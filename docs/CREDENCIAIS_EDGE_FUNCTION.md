# 🔐 Credenciais da Edge Function r2-proxy

## ✅ Credenciais Obrigatórias

### 1. **R2_ACCOUNT_ID** ✅
- **O que é**: ID da sua conta Cloudflare
- **Onde encontrar**: Cloudflare Dashboard > R2 > Overview > Account ID
- **Formato**: String alfanumérica (ex: `abc123def456...`)
- **Status**: ✅ Configurado (atualizado em 22 Jan 2026)

### 2. **R2_ACCESS_KEY_ID** ✅
- **O que é**: Chave de acesso para autenticar no R2
- **Onde criar**: Cloudflare Dashboard > R2 > Manage R2 API Tokens > Create API Token
- **Permissões necessárias**: Admin ou Read/Write no bucket `trashtalk-audio-files`
- **Formato**: String alfanumérica
- **Status**: ✅ Configurado (atualizado em 22 Jan 2026)

### 3. **R2_SECRET_ACCESS_KEY** ✅
- **O que é**: Chave secreta que acompanha o Access Key ID
- **Onde encontrar**: Aparece apenas uma vez ao criar o API Token (salve com segurança!)
- **Formato**: String longa alfanumérica
- **Status**: ✅ Configurado (atualizado em 22 Jan 2026)

## 🔧 Credenciais Opcionais (mas recomendadas)

### 4. **SUPABASE_URL** ✅
- **O que é**: URL base do seu projeto Supabase
- **Onde encontrar**: Supabase Dashboard > Project Settings > API > Project URL
- **Formato**: `https://[projeto-ref].supabase.co`
- **Uso**: Validação de JWT (opcional, mas melhora segurança)
- **Status**: ✅ Configurado (atualizado em 26 Jan 2026)

### 5. **SUPABASE_ANON_KEY** ✅
- **O que é**: Chave pública (anon) do Supabase
- **Onde encontrar**: Supabase Dashboard > Project Settings > API > anon public
- **Formato**: JWT token longo
- **Uso**: Validação de JWT (opcional, mas melhora segurança)
- **Status**: ✅ Configurado (atualizado em 26 Jan 2026)

## 📋 Credenciais Não Utilizadas (podem ser removidas)

### 6. **SUPABASE_SERVICE_ROLE_KEY** ⚠️
- **Status**: ⚠️ Configurada mas **NÃO USADA** no código atual
- **Recomendação**: Pode ser removida para reduzir superfície de ataque
- **Nota**: Se precisar de permissões administrativas no futuro, mantenha

### 7. **SUPABASE_DB_URL** ⚠️
- **Status**: ⚠️ Configurada mas **NÃO USADA** no código atual
- **Recomendação**: Pode ser removida
- **Nota**: Usada apenas se precisar acessar o banco diretamente da Edge Function

## ✅ Verificação

Todas as credenciais **obrigatórias** estão configuradas:
- ✅ R2_ACCOUNT_ID
- ✅ R2_ACCESS_KEY_ID
- ✅ R2_SECRET_ACCESS_KEY
- ✅ SUPABASE_URL (opcional, mas configurada)
- ✅ SUPABASE_ANON_KEY (opcional, mas configurada)

## 🔍 Como Verificar se Estão Funcionando

### 1. Verificar nos Logs da Edge Function

No Supabase Dashboard > Edge Functions > r2-proxy > Logs, procure por:

**✅ Se estiver OK:**
```
[R2-Proxy] S3Client configured: true
```

**❌ Se estiver com problema:**
```
R2 credentials not configured
R2 not configured
```

### 2. Testar a Função

```bash
curl -X GET \
  https://lkdigbdgpaquhevpfrdf.supabase.co/functions/v1/r2-proxy/test \
  -H "Authorization: Bearer [seu-token-jwt]"
```

**Resposta esperada (sucesso):**
```json
{
  "url": "https://[account-id].r2.cloudflarestorage.com/...",
  "version": "2.0-signed-url",
  "timestamp": "2026-01-26T..."
}
```

**Resposta de erro (credenciais faltando):**
```json
{
  "error": "R2 not configured",
  "details": "R2 credentials are missing..."
}
```

## 🛠️ Como Atualizar Credenciais

1. Acesse: Supabase Dashboard > Edge Functions > r2-proxy > Settings > Secrets
2. Clique no menu (três pontos) ao lado da credencial
3. Selecione "Edit" ou "Delete"
4. Para adicionar nova: Clique em "Add new secret"
5. **IMPORTANTE**: Após atualizar, faça redeploy da função:
   ```bash
   supabase functions deploy r2-proxy --no-verify-jwt
   ```

## 🔒 Segurança

- ✅ **Nunca** commite credenciais no Git
- ✅ Use apenas secrets do Supabase para armazenar
- ✅ Rotacione as chaves periodicamente (especialmente R2_SECRET_ACCESS_KEY)
- ✅ Use permissões mínimas necessárias (não Admin se possível)
- ✅ Remova credenciais não utilizadas

## 📝 Notas Importantes

1. **R2_SECRET_ACCESS_KEY**: Se você perder essa chave, precisará criar um novo API Token no Cloudflare
2. **SUPABASE_SERVICE_ROLE_KEY**: Tem acesso total ao banco - mantenha segura!
3. As credenciais são criptografadas no Supabase (por isso aparecem como hash SHA256)

## ✅ Status Atual

Todas as credenciais necessárias estão configuradas e atualizadas recentemente. A Edge Function deve funcionar corretamente!
