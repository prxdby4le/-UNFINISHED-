// supabase/functions/r2-proxy/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { S3Client, GetObjectCommand, PutObjectCommand } from "https://esm.sh/@aws-sdk/client-s3@3.490.0"

const R2_ACCOUNT_ID = Deno.env.get('R2_ACCOUNT_ID')
const R2_ACCESS_KEY_ID = Deno.env.get('R2_ACCESS_KEY_ID')
const R2_SECRET_ACCESS_KEY = Deno.env.get('R2_SECRET_ACCESS_KEY')
const R2_BUCKET_NAME = 'trashtalk-audio-files'

const s3Client = new S3Client({
  region: 'auto',
  endpoint: `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: R2_ACCESS_KEY_ID!,
    secretAccessKey: R2_SECRET_ACCESS_KEY!,
  },
  forcePathStyle: true,
})

serve(async (req) => {
  // Verificar autenticação
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const url = new URL(req.url)
  const path = url.pathname.replace('/r2-proxy', '')
  const method = req.method
  const key = path.startsWith('/') ? path.substring(1) : path

  if (!key) {
    return new Response(JSON.stringify({ message: 'R2 Proxy Ready' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
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
        headers: { 'Content-Type': 'application/json' },
      })
    } else {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      })
    }
  } catch (error) {
    console.error('R2 Error:', error)
    return new Response(JSON.stringify({ 
      error: error instanceof Error ? error.message : 'Unknown error' 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
