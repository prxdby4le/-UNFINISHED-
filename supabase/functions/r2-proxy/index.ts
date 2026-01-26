// supabase/functions/r2-proxy/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const R2_ACCOUNT_ID = Deno.env.get('R2_ACCOUNT_ID')
const R2_ACCESS_KEY_ID = Deno.env.get('R2_ACCESS_KEY_ID')
const R2_SECRET_ACCESS_KEY = Deno.env.get('R2_SECRET_ACCESS_KEY')
const R2_BUCKET_NAME = 'trashtalk-audio-files'

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

// Função helper para criar headers CORS válidos
// IMPORTANTE: Sempre retorna headers válidos, nunca undefined ou null
function getCorsHeaders(origin?: string | null): Record<string, string> {
  // Se tiver origin específico, usa ele. Senão, permite tudo (*)
  const allowOrigin = origin || '*'
  
  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, accept, origin',
    'Access-Control-Allow-Methods': 'GET, PUT, POST, DELETE, OPTIONS, HEAD',
    'Access-Control-Max-Age': '86400',
    'Access-Control-Allow-Credentials': 'false',
  }
}

// Função helper para criar resposta com CORS garantido
function corsResponse(body: string | null, status: number, contentType: string = 'application/json', origin?: string | null): Response {
  const headers: Record<string, string> = {
    ...getCorsHeaders(origin),
  }
  
  if (contentType) {
    headers['Content-Type'] = contentType
  }
  
  return new Response(body, {
    status,
    headers,
  })
}

// Função para criar S3Client usando importação dinâmica
async function createS3Client(): Promise<any> {
  if (!R2_ACCOUNT_ID || !R2_ACCESS_KEY_ID || !R2_SECRET_ACCESS_KEY) {
    return null
  }
  
  try {
    const { S3Client } = await import("https://esm.sh/@aws-sdk/client-s3@3.490.0")
    
    return new S3Client({
      region: 'auto',
      endpoint: `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: R2_ACCESS_KEY_ID,
        secretAccessKey: R2_SECRET_ACCESS_KEY,
      },
      forcePathStyle: true,
    })
  } catch (error) {
    console.error('[R2-Proxy] Error creating S3Client:', error)
    return null
  }
}

serve(async (req) => {
  // Extrair origin da requisição para CORS dinâmico
  const origin = req.headers.get('Origin')
  
  console.log('[R2-Proxy] ===== VERSION 3.0 - CORS FIX =====')
  console.log('[R2-Proxy] Method:', req.method)
  console.log('[R2-Proxy] URL:', req.url)
  console.log('[R2-Proxy] Origin:', origin)
  
  // TRATAR OPTIONS PRIMEIRO - ANTES DE QUALQUER COISA
  // O navegador SEMPRE faz OPTIONS antes de requisições CORS
  if (req.method === 'OPTIONS') {
    console.log('[R2-Proxy] OPTIONS preflight - returning CORS headers')
    return corsResponse(null, 200, '', origin)
  }
  
  // Try-catch global para garantir CORS em TODOS os erros
  try {
    // Verificar autenticação
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      console.log('[R2-Proxy] No authorization header')
      return corsResponse(
        JSON.stringify({ error: 'Unauthorized: No authorization header' }),
        401,
        'application/json',
        origin
      )
    }

    // Extrair token
    const token = authHeader.replace('Bearer ', '')
    
    if (!token || token === authHeader) {
      console.log('[R2-Proxy] Invalid authorization format')
      return corsResponse(
        JSON.stringify({ 
          error: 'Invalid Authorization header format',
          details: 'Expected: Bearer <token>'
        }),
        401,
        'application/json',
        origin
      )
    }

    // Validar JWT usando Supabase
    if (!supabaseUrl || !supabaseAnonKey) {
      console.error('[R2-Proxy] Supabase credentials not configured')
      return corsResponse(
        JSON.stringify({ 
          error: 'Server configuration error',
          details: 'Supabase credentials not available'
        }),
        500,
        'application/json',
        origin
      )
    }

    try {
      const validateResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'apikey': supabaseAnonKey,
        },
      })
      
      if (!validateResponse.ok) {
        const errorData = await validateResponse.json().catch(() => ({}))
        console.error('[R2-Proxy] Auth validation failed:', validateResponse.status)
        return corsResponse(
          JSON.stringify({ 
            code: 401,
            message: 'Invalid JWT',
            details: errorData.message || 'Token validation failed'
          }),
          401,
          'application/json',
          origin
        )
      }
      
      const user = await validateResponse.json()
      
      if (!user || !user.id) {
        console.error('[R2-Proxy] User not found in token')
        return corsResponse(
          JSON.stringify({ 
            code: 401,
            message: 'User not found'
          }),
          401,
          'application/json',
          origin
        )
      }
      
      console.log('[R2-Proxy] Authenticated user:', user.id)
    } catch (error) {
      console.error('[R2-Proxy] JWT validation error:', error)
      return corsResponse(
        JSON.stringify({ 
          code: 401,
          message: 'JWT validation failed',
          details: error instanceof Error ? error.message : 'Unknown error'
        }),
        401,
        'application/json',
        origin
      )
    }

    // Extrair path e key
    const url = new URL(req.url)
    const path = url.pathname.replace('/r2-proxy', '')
    const method = req.method
    const key = path.startsWith('/') ? path.substring(1) : path

    if (!key) {
      console.log('[R2-Proxy] Health check - no key provided')
      return corsResponse(
        JSON.stringify({ message: 'R2 Proxy Ready', version: '3.0-cors-fix' }),
        200,
        'application/json',
        origin
      )
    }

    console.log('[R2-Proxy] Processing request for key:', key)

    // Criar S3Client
    const s3Client = await createS3Client()
    
    if (!s3Client) {
      console.error('[R2-Proxy] S3Client creation failed')
      return corsResponse(
        JSON.stringify({ 
          error: 'R2 not configured',
          details: 'R2 credentials are missing'
        }),
        500,
        'application/json',
        origin
      )
    }

    // Processar requisição baseada no método
    if (method === 'GET') {
      try {
        // Verificar se é uma imagem ou áudio (serve diretamente para evitar CORS)
        // Verificar extensão ou se está no diretório covers/avatars
        const hasImageExtension = /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(key)
        const hasAudioExtension = /\.(mp3|wav|flac|aiff|m4a|aac|ogg)$/i.test(key)
        const isInCoversFolder = /^covers\//i.test(key) || /\/covers\//i.test(key)
        const isInAvatarsFolder = /^avatars\//i.test(key) || /\/avatars\//i.test(key)
        const isInProjectsFolder = /^projects\//i.test(key) || /\/projects\//i.test(key)
        const isImage = hasImageExtension || isInCoversFolder || isInAvatarsFolder
        const isAudio = hasAudioExtension || isInProjectsFolder
        
        console.log('[R2-Proxy] Key:', key, 'hasImageExtension:', hasImageExtension, 'hasAudioExtension:', hasAudioExtension, 'isImage:', isImage, 'isAudio:', isAudio)
        
        if (isImage || isAudio) {
          // Para imagens e áudio, servir diretamente através do proxy (evita CORS)
          console.log('[R2-Proxy] Serving file directly:', key, 'type:', isImage ? 'image' : 'audio')
          
          try {
            const { GetObjectCommand } = await import("https://esm.sh/@aws-sdk/client-s3@3.490.0")
            
            const command = new GetObjectCommand({
              Bucket: R2_BUCKET_NAME,
              Key: key,
            })
            
            const response = await s3Client.send(command)
            
            if (!response.Body) {
              console.error('[R2-Proxy] No body in response for:', key)
              return corsResponse(
                JSON.stringify({ error: 'File not found or empty', key: key }),
                404,
                'application/json',
                origin
              )
            }
            
            // Converter body para Uint8Array
            // O Body pode ser um ReadableStream ou um Blob
            let result: Uint8Array
            
            try {
              if (response.Body instanceof ReadableStream) {
                const reader = response.Body.getReader()
                const chunks: Uint8Array[] = []
                
                while (true) {
                  const { done, value } = await reader.read()
                  if (done) break
                  if (value) chunks.push(value)
                }
                
                // Concatenar chunks
                const totalLength = chunks.reduce((acc, chunk) => acc + chunk.length, 0)
                result = new Uint8Array(totalLength)
                let offset = 0
                for (const chunk of chunks) {
                  result.set(chunk, offset)
                  offset += chunk.length
                }
              } else if (response.Body && typeof (response.Body as any).arrayBuffer === 'function') {
                // Se for Blob ou outro tipo com arrayBuffer, converter
                const arrayBuffer = await (response.Body as any).arrayBuffer()
                result = new Uint8Array(arrayBuffer)
              } else if (response.Body && typeof (response.Body as any).transformToByteArray === 'function') {
                // Para Blob no Deno
                const byteArray = await (response.Body as any).transformToByteArray()
                result = new Uint8Array(byteArray)
              } else {
                // Tentar converter como Uint8Array diretamente
                result = new Uint8Array(response.Body as any)
              }
            } catch (bodyError) {
              console.error('[R2-Proxy] Error reading body:', bodyError)
              throw new Error(`Failed to read file body: ${bodyError instanceof Error ? bodyError.message : String(bodyError)}`)
            }
            
            // Determinar content type baseado na extensão ou no ContentType do response
            let contentType = response.ContentType
            if (!contentType || contentType === 'application/octet-stream') {
              // Fallback para extensão
              const lowerKey = key.toLowerCase()
              if (lowerKey.endsWith('.png')) contentType = 'image/png'
              else if (lowerKey.endsWith('.gif')) contentType = 'image/gif'
              else if (lowerKey.endsWith('.webp')) contentType = 'image/webp'
              else if (lowerKey.endsWith('.svg')) contentType = 'image/svg+xml'
              else if (lowerKey.endsWith('.jpg') || lowerKey.endsWith('.jpeg')) contentType = 'image/jpeg'
              else if (lowerKey.endsWith('.mp3')) contentType = 'audio/mpeg'
              else if (lowerKey.endsWith('.wav')) contentType = 'audio/wav'
              else if (lowerKey.endsWith('.flac')) contentType = 'audio/flac'
              else if (lowerKey.endsWith('.aiff')) contentType = 'audio/aiff'
              else if (lowerKey.endsWith('.m4a')) contentType = 'audio/mp4'
              else if (lowerKey.endsWith('.aac')) contentType = 'audio/aac'
              else if (lowerKey.endsWith('.ogg')) contentType = 'audio/ogg'
              else contentType = isImage ? 'image/jpeg' : 'audio/mpeg'
            }
            
            console.log('[R2-Proxy] File served successfully, size:', result.length, 'bytes, type:', contentType)
            
            // Retornar resposta com CORS e o body do arquivo
            return new Response(result, {
              status: 200,
              headers: {
                ...getCorsHeaders(origin),
                'Content-Type': contentType,
                'Cache-Control': 'public, max-age=3600',
                'Content-Disposition': `attachment; filename="${key.split('/').pop()}"`,
              }
            })
          } catch (fileError) {
            console.error('[R2-Proxy] Error serving file:', fileError)
            // Se falhar ao servir arquivo, retornar erro com CORS
            return corsResponse(
              JSON.stringify({ 
                error: 'Failed to serve file',
                key: key,
                details: fileError instanceof Error ? fileError.message : String(fileError)
              }),
              500,
              'application/json',
              origin
            )
          }
        } else {
          // Para outros arquivos (áudio), retornar URL assinada (comportamento original)
          console.log('[R2-Proxy] Generating signed URL for:', key)
          
          const { GetObjectCommand } = await import("https://esm.sh/@aws-sdk/client-s3@3.490.0")
          const { getSignedUrl } = await import("https://esm.sh/@aws-sdk/s3-request-presigner@3.490.0")
          
          const command = new GetObjectCommand({
            Bucket: R2_BUCKET_NAME,
            Key: key,
          })
      
          const signedUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 })
          
          console.log('[R2-Proxy] Signed URL generated successfully')
      
          return corsResponse(
            JSON.stringify({ 
              url: signedUrl,
              version: '3.0-cors-fix',
              timestamp: new Date().toISOString()
            }),
            200,
            'application/json',
            origin
          )
        }
      } catch (error) {
        console.error('[R2-Proxy] Error processing GET request:', error)
        return corsResponse(
          JSON.stringify({ 
            error: 'Failed to process request',
            details: error instanceof Error ? error.message : String(error)
          }),
          500,
          'application/json',
          origin
        )
      }
    } else if (method === 'PUT') {
      try {
        const body = await req.arrayBuffer()
        const contentType = req.headers.get('Content-Type') || 'audio/wav'
        
        const { PutObjectCommand } = await import("https://esm.sh/@aws-sdk/client-s3@3.490.0")
        
        const command = new PutObjectCommand({
          Bucket: R2_BUCKET_NAME,
          Key: key,
          Body: new Uint8Array(body),
          ContentType: contentType,
        })
        
        await s3Client.send(command)
        
        console.log('[R2-Proxy] Upload successful for:', key)
        
        return corsResponse(
          JSON.stringify({ success: true, key: key }),
          200,
          'application/json',
          origin
        )
      } catch (error) {
        console.error('[R2-Proxy] Upload error:', error)
        return corsResponse(
          JSON.stringify({ 
            error: 'Upload failed',
            details: error instanceof Error ? error.message : String(error)
          }),
          500,
          'application/json',
          origin
        )
      }
    } else {
      console.log('[R2-Proxy] Method not allowed:', method)
      return corsResponse(
        JSON.stringify({ error: 'Method not allowed' }),
        405,
        'application/json',
        origin
      )
    }
  } catch (error) {
    // Catch global - GARANTE que sempre retorna CORS
    console.error('[R2-Proxy] Critical error:', error)
    return corsResponse(
      JSON.stringify({ 
        error: 'Critical server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      500,
      'application/json',
      origin
    )
  }
})
