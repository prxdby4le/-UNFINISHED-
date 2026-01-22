# ☁️ Configuração Cloudflare R2 + Supabase

## Visão Geral

O Cloudflare R2 será usado como storage primário para arquivos de áudio, enquanto o Supabase Storage será usado apenas como proxy/cache. Isso reduz custos de egress do Supabase.

## Opção 1: Integração Direta (Recomendada)

### 1.1 Configuração no Cloudflare

1. **Criar bucket no R2**:
   - Acesse [Cloudflare Dashboard](https://dash.cloudflare.com/)
   - Vá em R2 > Create bucket
   - Nome: `trashtalk-audio-files`
   - Escolha localização (ex: `auto`)

2. **Criar API Token**:
   - R2 > Manage R2 API Tokens
   - Create API Token
   - Permissões: Object Read & Write
   - Salve: `Account ID`, `Access Key ID`, `Secret Access Key`

3. **Configurar CORS** (para acesso via Flutter):
   ```json
   [
     {
       "AllowedOrigins": ["*"],
       "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
       "AllowedHeaders": ["*"],
       "ExposeHeaders": ["ETag"],
       "MaxAgeSeconds": 3600
     }
   ]
   ```

### 1.2 Configuração no Supabase

#### Criar Função Edge para Proxy R2

Crie uma Edge Function no Supabase que atua como proxy para o R2:

```typescript
// supabase/functions/r2-proxy/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { S3Client, GetObjectCommand, PutObjectCommand } from "https://deno.land/x/aws_sdk@v3.32.0/client-s3/mod.ts"

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

  try {
    if (method === 'GET') {
      // Download
      const command = new GetObjectCommand({
        Bucket: R2_BUCKET_NAME,
        Key: path,
      })
      const response = await s3Client.send(command)
      const body = await response.Body.transformToByteArray()
      
      return new Response(body, {
        headers: {
          'Content-Type': response.ContentType || 'audio/wav',
          'Content-Length': response.ContentLength?.toString() || '',
        },
      })
    } else if (method === 'PUT') {
      // Upload
      const body = await req.arrayBuffer()
      const command = new PutObjectCommand({
        Bucket: R2_BUCKET_NAME,
        Key: path,
        Body: new Uint8Array(body),
        ContentType: req.headers.get('Content-Type') || 'audio/wav',
      })
      await s3Client.send(command)
      
      return new Response(JSON.stringify({ success: true, key: path }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    }
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
```

#### Variáveis de Ambiente no Supabase

No Supabase Dashboard > Project Settings > Edge Functions:
- `R2_ACCOUNT_ID`: Seu Account ID do Cloudflare
- `R2_ACCESS_KEY_ID`: Access Key ID
- `R2_SECRET_ACCESS_KEY`: Secret Access Key

## Opção 2: Acesso Direto do Flutter (Alternativa)

Se preferir acesso direto sem proxy, você pode usar a biblioteca `aws_s3_api` no Flutter:

```dart
// lib/core/config/r2_config.dart
class R2Config {
  static const String accountId = 'YOUR_ACCOUNT_ID';
  static const String accessKeyId = 'YOUR_ACCESS_KEY_ID';
  static const String secretAccessKey = 'YOUR_SECRET_ACCESS_KEY';
  static const String bucketName = 'trashtalk-audio-files';
  
  static String get endpoint => 'https://$accountId.r2.cloudflarestorage.com';
}
```

**⚠️ Atenção**: Esta abordagem expõe credenciais no app. Use apenas se implementar autenticação própria ou se o bucket for público (não recomendado).

## Opção 3: Supabase Storage + R2 Sync (Híbrida)

Usar Supabase Storage como cache e sincronizar com R2 periodicamente:

1. Uploads vão para Supabase Storage
2. Background job sincroniza com R2
3. Downloads podem vir de qualquer um (prioridade: Supabase cache > R2)

## Recomendação

**Use a Opção 1 (Proxy via Supabase Edge Function)** porque:
- ✅ Credenciais seguras (não expostas no app)
- ✅ Autenticação integrada com Supabase Auth
- ✅ Logs e monitoramento centralizados
- ✅ Fácil de adicionar rate limiting e validações

## URLs de Acesso

Após configurar, os arquivos serão acessíveis via:
```
https://[seu-projeto].supabase.co/functions/v1/r2-proxy/[caminho-do-arquivo]
```

Exemplo:
```
https://abc123.supabase.co/functions/v1/r2-proxy/projects/project-1/mix-final.wav
```

## Teste de Configuração

```bash
# Testar upload
curl -X PUT \
  -H "Authorization: Bearer [seu-token]" \
  -H "Content-Type: audio/wav" \
  --data-binary @test.wav \
  https://[projeto].supabase.co/functions/v1/r2-proxy/test/test.wav

# Testar download
curl -H "Authorization: Bearer [seu-token]" \
  https://[projeto].supabase.co/functions/v1/r2-proxy/test/test.wav \
  -o downloaded.wav
```
