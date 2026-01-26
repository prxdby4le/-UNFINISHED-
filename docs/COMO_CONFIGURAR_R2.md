# 🔧 Como Configurar R2 (Cloudflare) + Supabase

## Entendendo a Arquitetura

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   Flutter   │ ──────> │   Supabase   │ ──────> │ Cloudflare  │
│     App     │         │ Edge Function│         │     R2      │
│             │         │  (r2-proxy)  │         │  (Storage)  │
└─────────────┘         └──────────────┘         └─────────────┘
```

### Onde cada coisa fica:

1. **R2 (Cloudflare)**: Onde os arquivos de áudio são armazenados
2. **Edge Function (Supabase)**: Ponte entre o app e o R2
3. **Flutter App**: Faz requisições para a Edge Function

## Passo a Passo

### 1️⃣ Configurar R2 no Cloudflare

1. Acesse [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Vá em **R2** > Crie ou selecione o bucket `trashtalk-audio-files`
3. Configure CORS:
   - Vá em **Settings** > **CORS Policy**
   - Adicione a configuração (veja `docs/R2_SETUP.md`)
4. Obtenha as credenciais:
   - Vá em **Manage R2 API Tokens**
   - Crie um token com permissões de **Read/Write**
   - Anote:
     - **Account ID** (encontrado no dashboard do Cloudflare)
     - **Access Key ID**
     - **Secret Access Key**

### 2️⃣ Configurar Edge Function no Supabase

A Edge Function precisa das credenciais do R2 para acessá-lo.

1. Acesse [Supabase Dashboard](https://supabase.com/dashboard)
2. Vá em **Edge Functions** > **r2-proxy**
3. Vá em **Settings** (ou **Secrets**)
4. Adicione as variáveis de ambiente:
   - `R2_ACCOUNT_ID` = Seu Account ID do Cloudflare
   - `R2_ACCESS_KEY_ID` = Access Key ID do token R2
   - `R2_SECRET_ACCESS_KEY` = Secret Access Key do token R2

**Importante**: Essas credenciais vêm do Cloudflare, mas precisam estar configuradas no Supabase!

### 3️⃣ Fazer Deploy da Edge Function

A Edge Function precisa estar deployada no Supabase:

```bash
# Na raiz do projeto
./deploy-r2-proxy.sh
```

Ou manualmente:

```bash
supabase functions deploy r2-proxy --no-verify-jwt
```

### 4️⃣ Verificar se Está Funcionando

Após o deploy, teste:

```bash
# Obtenha um token JWT (faça login no app e copie do DevTools)
curl -H "Authorization: Bearer [SEU_TOKEN]" \
  -H "apikey: [SUA_ANON_KEY]" \
  https://lkdigbdgpaquhevpfrdf.supabase.co/functions/v1/r2-proxy/[caminho-do-arquivo]
```

**Resposta esperada**:
```json
{
  "url": "https://[account-id].r2.cloudflarestorage.com/...",
  "version": "2.0-signed-url"
}
```

## Resumo: Onde Configurar Cada Coisa

| O que | Onde | Como |
|-------|------|------|
| **Bucket R2** | Cloudflare Dashboard | Criar bucket `trashtalk-audio-files` |
| **CORS do R2** | Cloudflare Dashboard > R2 > Settings > CORS | Adicionar política CORS |
| **Credenciais R2** | Cloudflare Dashboard > R2 > API Tokens | Criar token e anotar credenciais |
| **Variáveis de Ambiente** | Supabase Dashboard > Edge Functions > r2-proxy > Settings | Adicionar `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` |
| **Deploy da Função** | Terminal (na raiz do projeto) | `./deploy-r2-proxy.sh` |

## Erros Comuns

### "R2 credentials not configured"
**Causa**: Variáveis de ambiente não estão configuradas no Supabase
**Solução**: Vá em Supabase Dashboard > Edge Functions > r2-proxy > Settings e adicione as 3 variáveis

### "502 Bad Gateway"
**Causa**: Edge Function não está deployada ou crashou
**Solução**: 
1. Faça o deploy: `./deploy-r2-proxy.sh`
2. Verifique os logs no Supabase Dashboard

### "CORS error"
**Causa**: CORS não está configurado no R2 OU Edge Function não está retornando headers CORS
**Solução**:
1. Configure CORS no R2 (Cloudflare Dashboard)
2. Faça o deploy da Edge Function novamente

## Checklist

- [ ] Bucket R2 criado no Cloudflare
- [ ] CORS configurado no R2
- [ ] Token R2 criado e credenciais anotadas
- [ ] Variáveis de ambiente configuradas no Supabase
- [ ] Edge Function deployada
- [ ] Teste manual funcionando

## Dúvidas?

- **R2 está na Cloudflare?** ✅ Sim, correto!
- **Edge Function está no Supabase?** ✅ Sim, precisa estar deployada lá
- **Credenciais do R2 vão no Supabase?** ✅ Sim, como variáveis de ambiente da Edge Function
