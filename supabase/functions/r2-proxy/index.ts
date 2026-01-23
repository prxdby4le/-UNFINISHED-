// supabase/functions/r2-proxy/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { S3Client, GetObjectCommand, PutObjectCommand } from "https://esm.sh/@aws-sdk/client-s3@3.490.0"

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

// Headers CORS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, PUT, POST, DELETE, OPTIONS',
}

serve(async (req) => {
  // Try-catch global para garantir que TODOS os erros retornem headers CORS
  try {
    // Tratar requisições OPTIONS (preflight)
    if (req.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: corsHeaders,
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
      // Criar cliente Supabase
      const supabase = createClient(supabaseUrl, supabaseAnonKey, {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      })
      
      // Verificar se o token é válido passando explicitamente
      const { data: { user }, error: authError } = await supabase.auth.getUser(token)
      
      if (authError) {
        console.error('Auth error:', authError.message)
        console.error('Token (first 20 chars):', token.substring(0, 20) + '...')
        return new Response(JSON.stringify({ 
          code: 401,
          message: 'Invalid JWT',
          details: authError.message 
        }), {
          status: 401,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        })
      }
      
      if (!user) {
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
        // Download
        const command = new GetObjectCommand({
          Bucket: R2_BUCKET_NAME,
          Key: key,
        })
        const response = await s3Client.send(command)
        
        // Converter stream para ArrayBuffer
        const chunks: Uint8Array[] = []
        if (response.Body) {
          // @ts-ignore - Body pode ser um ReadableStream
          for await (const chunk of response.Body) {
            chunks.push(chunk)
          }
        }
        
        // Concatenar chunks
        const totalLength = chunks.reduce((acc, chunk) => acc + chunk.length, 0)
        const body = new Uint8Array(totalLength)
        let offset = 0
        for (const chunk of chunks) {
          body.set(chunk, offset)
          offset += chunk.length
        }
        
        return new Response(body, {
          headers: {
            'Content-Type': response.ContentType || 'audio/wav',
            'Content-Length': (response.ContentLength || body.length).toString(),
            'Cache-Control': 'public, max-age=3600',
            ...corsHeaders,
          },
        })
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
