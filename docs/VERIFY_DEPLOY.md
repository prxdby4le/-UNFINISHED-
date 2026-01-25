# 🔍 Verificação de Deploy - R2 Proxy

## Como Verificar se a Nova Versão Está Ativa

Após fazer o deploy, verifique os logs no Supabase Dashboard:

1. Vá em **Supabase Dashboard** > **Edge Functions** > **r2-proxy** > **Logs**
2. Procure por requisições recentes
3. **Você DEVE ver estas mensagens**:
   ```
   [R2-Proxy] ===== VERSION 2.0 - SIGNED URL MODE =====
   [R2-Proxy] Request method: GET
   [R2-Proxy] GET request - Generating signed URL for key: ...
   [R2-Proxy] Signed URL generated successfully
   [R2-Proxy] Returning JSON response with signed URL
   ```

## Se Você NÃO Ver Essas Mensagens

Isso significa que a versão antiga ainda está ativa. Tente:

1. **Forçar novo deploy**:
   ```bash
   supabase functions deploy r2-proxy --no-verify-jwt --debug
   ```

2. **Verificar se há múltiplas versões**:
   - No Dashboard, vá em Edge Functions > r2-proxy
   - Verifique se há múltiplas versões deployadas
   - Delete versões antigas se necessário

3. **Verificar variáveis de ambiente**:
   - Certifique-se de que `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` estão configuradas
   - Se faltarem, a função pode estar caindo em erro silencioso

## Teste Manual

Teste a função diretamente via curl:

```bash
# Substitua [TOKEN] e [ANON_KEY] pelos valores reais
curl -X GET \
  -H "Authorization: Bearer [TOKEN]" \
  -H "apikey: [ANON_KEY]" \
  -v \
  https://lkdigbdgpaquhevpfrdf.supabase.co/functions/v1/r2-proxy/projects/[project-id]/[file.wav]
```

**Resposta esperada (NOVA versão)**:
```json
{
  "url": "https://[account-id].r2.cloudflarestorage.com/...",
  "version": "2.0-signed-url",
  "timestamp": "2026-01-24T..."
}
```

**Resposta antiga (se ainda estiver ativa)**:
```
RIFF... (dados binários do arquivo WAV)
Content-Type: audio/wav
```

## Se Ainda Retornar Audio/WAV

1. **Verifique os logs** - veja se há erros ao gerar a URL assinada
2. **Verifique as credenciais do R2** - se estiverem incorretas, pode estar caindo em erro
3. **Aguarde alguns minutos** - às vezes o deploy leva tempo para propagar
4. **Tente fazer deploy novamente** com `--debug` para ver mais detalhes
