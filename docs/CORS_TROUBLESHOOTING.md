# 🚨 Correção de Erro CORS - Guia Completo

## Erro Observado

```
Access to fetch at 'https://...supabase.co/functions/v1/r2-proxy/...' 
from origin 'http://localhost:6769' has been blocked by CORS policy: 
Response to preflight request doesn't pass access control check: 
It does not have HTTP ok status.
```

## Causa Raiz

O Supabase Edge Functions pode estar bloqueando requisições OPTIONS (preflight) **antes** de chegar no código da função, especialmente se a função foi deployada **COM verificação de JWT habilitada**.

## Solução Passo a Passo

### 1. Verificar se a Função Foi Deployada

Primeiro, confirme se a função está deployada com a versão mais recente:

```bash
# Verificar se está logado
supabase login

# Verificar se o projeto está linkado
supabase link --project-ref lkdigbdgpaquhevpfrdf

# Fazer deploy SEM verificação de JWT (CRÍTICO!)
supabase functions deploy r2-proxy --no-verify-jwt
```

**⚠️ IMPORTANTE**: O `--no-verify-jwt` é **ESSENCIAL** porque:
- A função já faz validação manual de JWT no código
- Se o Supabase verificar JWT antes, ele bloqueia o OPTIONS (preflight)
- O OPTIONS não tem token, então falha a verificação automática

### 2. Verificar Variáveis de Ambiente

No Supabase Dashboard:
1. Vá em **Edge Functions** > **r2-proxy** > **Settings**
2. Verifique se estão configuradas:
   - `R2_ACCOUNT_ID`
   - `R2_ACCESS_KEY_ID`
   - `R2_SECRET_ACCESS_KEY`

### 3. Testar a Função Manualmente

Teste o OPTIONS (preflight):

```bash
curl -X OPTIONS \
  -H "Origin: http://localhost:6769" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: authorization,apikey" \
  -v \
  https://lkdigbdgpaquhevpfrdf.supabase.co/functions/v1/r2-proxy/test
```

**Resposta esperada**:
```
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, PUT, POST, DELETE, OPTIONS, HEAD
Access-Control-Allow-Headers: authorization, x-client-info, apikey, content-type, accept, origin
```

Se retornar 401 ou 403, a função está com verificação de JWT habilitada.

### 4. Testar GET com Token

```bash
# Primeiro, obtenha um token (faça login no app e copie do console)
TOKEN="seu_token_aqui"

curl -X GET \
  -H "Authorization: Bearer $TOKEN" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  https://lkdigbdgpaquhevpfrdf.supabase.co/functions/v1/r2-proxy/[caminho-do-arquivo]
```

**Resposta esperada (JSON)**:
```json
{"url":"https://[account-id].r2.cloudflarestorage.com/..."}
```

### 5. Verificar Logs

No Supabase Dashboard:
1. Vá em **Edge Functions** > **r2-proxy** > **Logs**
2. Procure por:
   - `[R2-Proxy] Handling OPTIONS preflight request` (deve aparecer)
   - Erros relacionados a CORS
   - Erros de validação de JWT

## Se Ainda Não Funcionar

### Opção A: Deploy via Dashboard

1. Vá em **Supabase Dashboard** > **Edge Functions** > **r2-proxy**
2. Clique em **Edit**
3. Cole o código atualizado de `supabase/functions/r2-proxy/index.ts`
4. **IMPORTANTE**: Na seção de configurações, desabilite "Verify JWT" ou configure para "Skip JWT verification"
5. Clique em **Deploy**

### Opção B: Verificar Configuração do Projeto

Se você está usando o Supabase CLI localmente, verifique se há um arquivo `.env` ou configuração que possa estar sobrescrevendo:

```bash
# Verificar configuração atual
supabase status
```

## Verificação Final

Após o deploy correto:

1. **Recarregue o app completamente** (Ctrl+Shift+R ou Cmd+Shift+R)
2. **Abra o DevTools** > **Network**
3. **Filtre por "r2-proxy"**
4. **Verifique**:
   - A requisição OPTIONS retorna 200 (não 401/403)
   - A requisição GET retorna JSON com `{"url":"..."}`
   - Não há mais erros de CORS no console

## Debug Adicional

Se o problema persistir, adicione este código temporário no início da função para ver o que está chegando:

```typescript
console.log('[R2-Proxy] Request method:', req.method);
console.log('[R2-Proxy] Request headers:', Object.fromEntries(req.headers.entries()));
console.log('[R2-Proxy] Request URL:', req.url);
```

Isso vai aparecer nos logs do Supabase e ajudar a identificar o problema.
