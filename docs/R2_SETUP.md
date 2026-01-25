# ☁️ Configuração Cloudflare R2 + Supabase

## Visão Geral

O Cloudflare R2 é usado como storage para arquivos de áudio. Para garantir segurança e performance, usamos um modelo de **Presigned URLs**.

1. O App solicita acesso ao arquivo para a Edge Function.
2. A Edge Function valida a autenticação do usuário.
3. A Edge Function gera uma URL temporária (assinada) que dá acesso direto ao arquivo no R2 por 1 hora.
4. O App usa essa URL para fazer streaming direto do R2 (CDN Cloudflare), garantindo velocidade máxima e suporte a seek/range requests.

## Configuração Obrigatória

### 1. Cloudflare R2 (CORS)

Para que o streaming funcione em navegadores (Flutter Web), você **DEVE** configurar o CORS no seu bucket R2.

1. Acesse [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Vá em **R2** > Selecione o bucket `trashtalk-audio-files`
3. Vá em **Settings** > **CORS Policy**
4. Adicione a seguinte configuração:

```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["Content-Length", "Content-Type", "Content-Range", "ETag"],
    "MaxAgeSeconds": 3600
  },
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["PUT", "POST", "DELETE"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": [],
    "MaxAgeSeconds": 3600
  }
]
```
> Nota: Em produção, substitua `"*"` pelo domínio do seu app (ex: `https://meuapp.com`).

### 2. Variáveis de Ambiente (Supabase)

No Supabase Dashboard > Project Settings > Edge Functions, configure:

- `R2_ACCOUNT_ID`: Seu Account ID do Cloudflare
- `R2_ACCESS_KEY_ID`: Access Key ID (com permissão de Admin ou Read/Write no bucket)
- `R2_SECRET_ACCESS_KEY`: Secret Access Key

### 3. Deploy da Edge Function

Atualize a função `r2-proxy` com o novo código que suporta URLs assinadas:

```bash
supabase functions deploy r2-proxy --no-verify-jwt
```

## Como Funciona o Código

### Edge Function (`supabase/functions/r2-proxy/index.ts`)

A função agora retorna um JSON com a URL assinada para requisições GET:

```typescript
// ... validação de auth ...

if (method === 'GET') {
  // Gera URL assinada válida por 1 hora
  const signedUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 })
  
  return new Response(JSON.stringify({ url: signedUrl }), {
    headers: { 'Content-Type': 'application/json', ...corsHeaders }
  })
}
```

### App Flutter (`AudioPlayerProvider`)

O app solicita a URL e faz streaming:

```dart
// 1. Pede a URL assinada
final response = await http.get(Uri.parse('.../r2-proxy/file.wav'), headers: authHeaders);
final signedUrl = jsonDecode(response.body)['url'];

// 2. Faz streaming direto (suporta seek, cache, etc)
await player.setAudioSource(AudioSource.uri(Uri.parse(signedUrl)));
```

## Teste

```bash
# Testar geração de URL (deve retornar JSON com "url": "https://...")
curl -H "Authorization: Bearer [seu-token]" \
  https://[projeto].supabase.co/functions/v1/r2-proxy/test/test.wav
```
