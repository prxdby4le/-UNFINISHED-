# 🔧 Correção de Erros CORS e 502 Bad Gateway

## Problemas Corrigidos

### 1. Tratamento de Erros Melhorado
- ✅ Adicionado tratamento específico para erros de CORS
- ✅ Adicionado tratamento para erros 502/503 (Edge Function não disponível)
- ✅ Adicionado timeout de 30 segundos para requisições
- ✅ Verificação automática de sessão antes de fazer requisições
- ✅ Tentativa automática de atualizar sessão expirada

### 2. Mensagens de Erro Mais Claras
- ✅ Mensagens específicas para cada tipo de erro
- ✅ Instruções sobre o que fazer quando há erro
- ✅ Logs detalhados para debug

## Como Resolver os Erros

### Passo 1: Fazer Deploy da Edge Function

A Edge Function precisa estar deployada corretamente. Execute:

```bash
./deploy-r2-proxy.sh
```

Ou manualmente:

```bash
supabase functions deploy r2-proxy --no-verify-jwt
```

### Passo 2: Verificar Variáveis de Ambiente

**Importante**: O R2 está na Cloudflare, mas as credenciais precisam estar configuradas no Supabase!

No Supabase Dashboard:
1. Vá em **Edge Functions > r2-proxy > Settings** (ou **Secrets**)
2. Verifique se estas variáveis estão configuradas:
   - `R2_ACCOUNT_ID` → Account ID do Cloudflare (encontrado no dashboard)
   - `R2_ACCESS_KEY_ID` → Access Key ID do token R2 (criado no Cloudflare)
   - `R2_SECRET_ACCESS_KEY` → Secret Access Key do token R2 (criado no Cloudflare)

**Onde obter essas credenciais**:
- Acesse [Cloudflare Dashboard](https://dash.cloudflare.com/)
- Vá em **R2** > **Manage R2 API Tokens**
- Crie um token e anote as credenciais
- Cole essas credenciais no Supabase Dashboard

**Nota**: `SUPABASE_URL` e `SUPABASE_ANON_KEY` são automaticamente disponibilizadas pelo Supabase.

### Passo 3: Verificar CORS no R2 (Cloudflare)

**Importante**: O CORS precisa estar configurado no R2, que está na Cloudflare!

No Cloudflare Dashboard:
1. Acesse [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Vá em **R2** > Selecione o bucket `trashtalk-audio-files`
3. Vá em **Settings** > **CORS Policy**
4. Certifique-se de que a política CORS está configurada (veja `docs/R2_SETUP.md`)

**Resumo**: 
- R2 = Cloudflare (onde os arquivos ficam)
- Edge Function = Supabase (precisa das credenciais do R2)
- CORS = Configurado no R2 (Cloudflare)

### Passo 4: Verificar Logs

Após fazer o deploy, verifique os logs:
1. Vá em **Supabase Dashboard > Edge Functions > r2-proxy > Logs**
2. Procure por erros relacionados a:
   - Credenciais do R2 faltando
   - Erros de conexão com o R2
   - Erros de validação de JWT

### Passo 5: Testar a Função

Teste a função diretamente:

```bash
# Primeiro, obtenha um token JWT válido (faça login no app e copie do DevTools)
# Depois teste:
curl -H "Authorization: Bearer [SEU_TOKEN]" \
  -H "apikey: [SUA_ANON_KEY]" \
  https://lkdigbdgpaquhevpfrdf.supabase.co/functions/v1/r2-proxy/[caminho-do-arquivo]
```

**Resposta esperada (JSON)**:
```json
{
  "url": "https://[account-id].r2.cloudflarestorage.com/...",
  "version": "2.0-signed-url",
  "timestamp": "2024-..."
}
```

## Erros Comuns e Soluções

### Erro: "Access-Control-Allow-Origin header is missing"
**Causa**: Edge Function não está retornando headers CORS
**Solução**: 
1. Verifique se a função está deployada com a versão mais recente
2. Execute: `supabase functions deploy r2-proxy --no-verify-jwt`

### Erro: "502 Bad Gateway"
**Causa**: Edge Function não está disponível ou crashou
**Solução**:
1. Verifique os logs da função no Supabase Dashboard
2. Verifique se as variáveis de ambiente estão configuradas
3. Faça o deploy novamente

### Erro: "401 Unauthorized"
**Causa**: Token JWT inválido ou expirado
**Solução**:
1. Faça logout e login novamente no app
2. O código agora tenta atualizar a sessão automaticamente

### Erro: "Failed to fetch" ou "ClientException"
**Causa**: Problema de rede ou CORS
**Solução**:
1. Verifique sua conexão com a internet
2. Verifique se a Edge Function está deployada
3. Verifique se o CORS está configurado no R2

## Após Corrigir

1. **Recarregue o app completamente** (Ctrl+Shift+R ou Cmd+Shift+R)
2. **Faça login novamente** se necessário
3. **Teste reproduzir uma música**

O código agora tem tratamento de erros melhorado e deve mostrar mensagens mais claras sobre o que está errado.

## Debug

Se o problema persistir, verifique:

1. **Console do navegador**: Procure por mensagens `[AudioPlayer]`
2. **Logs da Edge Function**: Supabase Dashboard > Edge Functions > r2-proxy > Logs
3. **Network tab**: Verifique as requisições para `/functions/v1/r2-proxy/`

Os logs agora incluem:
- URL da requisição
- Status da resposta
- Preview do corpo da resposta
- Detalhes de erros
