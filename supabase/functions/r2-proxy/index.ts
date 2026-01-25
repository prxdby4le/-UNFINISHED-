// supabase/functions/r2-proxy/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { S3Client, GetObjectCommand, PutObjectCommand } from "https://esm.sh/@aws-sdk/client-s3@3.490.0"
import { getSignedUrl } from "https://esm.sh/@aws-sdk/s3-request-presigner@3.490.0"

const R2_ACCOUNT_ID = Deno.env.get('R2_ACCOUNT_ID')
const R2_ACCESS_KEY_ID = Deno.env.get('R2_ACCESS_KEY_ID')
const R2_SECRET_ACCESS_KEY = Deno.env.get('R2_SECRET_ACCESS_KEY')
const R2_BUCKET_NAME = 'trashtalk-audio-files'

// Supabase client para validar JWT
const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

// Validar variáveis de ambiente do R2
if (!R2_ACCOUNT_ID || !R2_ACCESS_KEY_ID || !R2_SECRET_ACCESS_KEY) {
  console.error('R2 credentials not configured')
}

const s3Client = R2_ACCOUNT_ID && R2_ACCESS_KEY_ID && R2_SECRET_ACCESS_KEY
  ? new S3Client({
      region: 'auto',
      endpoint: `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: R2_ACCESS_KEY_ID,
        secretAccessKey: R2_SECRET_ACCESS_KEY,
      },
      forcePathStyle: true,
    })
  : null

// Headers CORS - mais permissivos para garantir funcionamento
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, accept, origin',
  'Access-Control-Allow-Methods': 'GET, PUT, POST, DELETE, OPTIONS, HEAD',
  'Access-Control-Max-Age': '86400', // 24 horas
}

serve(async (req) => {
  // Log de versão para confirmar que a nova versão está rodando
  console.log('[R2-Proxy] ===== VERSION 2.0 - SIGNED URL MODE =====')
  console.log('[R2-Proxy] Request method:', req.method)
  console.log('[R2-Proxy] Request URL:', req.url)
  
  // Try-catch global para garantir que TODOS os erros retornem headers CORS
  try {
    // Tratar requisições OPTIONS (preflight) - DEVE SER A PRIMEIRA COISA
    // O navegador faz isso antes de qualquer requisição real
    if (req.method === 'OPTIONS') {
      console.log('[R2-Proxy] Handling OPTIONS preflight request');
      return new Response(null, {
        status: 200, // Mudando para 200 em vez de 204 para garantir compatibilidade
        headers: {
          ...corsHeaders,
          'Content-Length': '0',
        },
      })
    }

    // Verificar autenticação
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized: No authorization header' }), {
        status: 401,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      })
    }

    // Extrair token do header
    const token = authHeader.replace('Bearer ', '')
    
    if (!token || token === authHeader) {
      return new Response(JSON.stringify({ 
        error: 'Invalid Authorization header format',
        details: 'Expected: Bearer <token>'
      }), {
        status: 401,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      })
    }

    // Validar JWT usando Supabase
    if (!supabaseUrl || !supabaseAnonKey) {
      console.error('Supabase URL or Anon Key not configured')
      console.error('SUPABASE_URL:', supabaseUrl ? 'SET' : 'NOT SET')
      console.error('SUPABASE_ANON_KEY:', supabaseAnonKey ? 'SET' : 'NOT SET')
      return new Response(JSON.stringify({ 
        error: 'Server configuration error',
        details: 'Supabase credentials not available'
      }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      })
    }

    try {
      // Validar JWT usando a API do Supabase diretamente (sem dependência externa)
      const validateResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'apikey': supabaseAnonKey,
        },
      })
      
      if (!validateResponse.ok) {
        const errorData = await validateResponse.json().catch(() => ({}))
        console.error('Auth validation failed:', validateResponse.status, errorData)
        return new Response(JSON.stringify({ 
          code: 401,
          message: 'Invalid JWT',
          details: errorData.message || 'Token validation failed'
        }), {
          status: 401,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        })
      }
      
      const user = await validateResponse.json()
      
      if (!user || !user.id) {
        return new Response(JSON.stringify({ 
          code: 401,
          message: 'User not found'
        }), {
          status: 401,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        })
      }
      
      // Log para debug
      console.log('Authenticated user:', user.id, user.email)
    } catch (error) {
      console.error('JWT validation error:', error)
      return new Response(JSON.stringify({ 
        code: 401,
        message: 'JWT validation failed',
        details: error instanceof Error ? error.message : 'Unknown error'
      }), {
        status: 401,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      })
    }

    const url = new URL(req.url)
    const path = url.pathname.replace('/r2-proxy', '')
    const method = req.method
    const key = path.startsWith('/') ? path.substring(1) : path

    if (!key) {
      return new Response(JSON.stringify({ message: 'R2 Proxy Ready' }), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      })
    }

    // Verificar se o cliente S3 está configurado
    if (!s3Client) {
      return new Response(JSON.stringify({ 
        error: 'R2 not configured',
        details: 'R2 credentials are missing. Please configure R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, and R2_SECRET_ACCESS_KEY'
      }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      })
    }

    try {
      if (method === 'GET') {
        try {
          console.log('[R2-Proxy] GET request - Generating signed URL for key:', key)
          console.log('[R2-Proxy] S3Client configured:', s3Client !== null)
          
          if (!s3Client) {
            throw new Error('S3Client not configured - check R2 credentials')
          }
          
          const command = new GetObjectCommand({
            Bucket: R2_BUCKET_NAME,
            Key: key,
          })
      
          console.log('[R2-Proxy] Calling getSignedUrl...')
          // Gera uma URL segura válida por 1 hora (3600 segundos)
          // O App vai usar essa URL para conectar DIRETO no R2
          const signedUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 })
          
          console.log('[R2-Proxy] Signed URL generated successfully (length:', signedUrl.length, ')')
          console.log('[R2-Proxy] Returning JSON response with signed URL')
      
          // Adicionar versão na resposta para debug
          const responseBody = JSON.stringify({ 
            url: signedUrl,
            version: '2.0-signed-url',
            timestamp: new Date().toISOString()
          })
          
          console.log('[R2-Proxy] Response body:', responseBody.substring(0, 100) + '...')
      
          return new Response(responseBody, {
            status: 200,
            headers: {
              'Content-Type': 'application/json',
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              ...corsHeaders,
            },
          })
        } catch (error) {
          console.error('[R2-Proxy] Error signing URL:', error)
          console.error('[R2-Proxy] Error details:', error instanceof Error ? error.message : String(error))
          return new Response(JSON.stringify({ 
            error: 'Failed to sign URL',
            details: error instanceof Error ? error.message : String(error)
          }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          })
        }
      } else if (method === 'PUT') {
        // Upload
        const body = await req.arrayBuffer()
        const contentType = req.headers.get('Content-Type') || 'audio/wav'
        
        const command = new PutObjectCommand({
          Bucket: R2_BUCKET_NAME,
          Key: key,
          Body: new Uint8Array(body),
          ContentType: contentType,
        })
        await s3Client.send(command)
        
        return new Response(JSON.stringify({ success: true, key: key }), {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        })
      } else {
        return new Response(JSON.stringify({ error: 'Method not allowed' }), {
          status: 405,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        })
      }
    } catch (error) {
      console.error('R2 Error:', error)
      return new Response(JSON.stringify({ 
        error: error instanceof Error ? error.message : 'Unknown error' 
      }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      })
    }
  } catch (outerError) {
    // Catch para erros de parsing ou outros erros críticos
    console.error('Critical error in r2-proxy:', outerError)
    return new Response(JSON.stringify({ 
      error: 'Critical server error',
      details: outerError instanceof Error ? outerError.message : 'Unknown error'
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    })
  }
})
