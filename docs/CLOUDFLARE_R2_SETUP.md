# ☁️ Guia Completo: Configuração Cloudflare R2

## Passo 1: Criar Bucket no Cloudflare R2

1. **Acesse o Dashboard do Cloudflare**:
   - Vá para [https://dash.cloudflare.com/](https://dash.cloudflare.com/)
   - Faça login na sua conta

2. **Navegue até R2**:
   - No menu lateral, clique em **"R2"** (ou procure por "Object Storage")
   - Se for a primeira vez, você pode precisar ativar o R2 (pode ter um período de trial gratuito)

3. **Criar o Bucket**:
   - Clique em **"Create bucket"**
   - **Nome do bucket**: `trashtalk-audio-files`
   - **Location**: Escolha `auto` (recomendado) ou a região mais próxima dos seus usuários
   - Clique em **"Create bucket"**

## Passo 2: Obter Account ID

1. **Encontrar o Account ID**:
   - No Dashboard do Cloudflare, olhe no canto superior direito
   - Você verá seu **Account ID** (um código alfanumérico)
   - **Copie e guarde este valor** - você precisará dele

   *Alternativa*: Vá em **R2 > Overview** e o Account ID estará visível lá também.

## Passo 3: Criar API Token (Credenciais de Acesso)

1. **Acessar Gerenciamento de Tokens**:
   - No menu R2, clique em **"Manage R2 API Tokens"**
   - Ou acesse diretamente: [https://dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens)

2. **Criar Novo Token**:
   - Clique em **"Create API Token"**
   - Escolha **"Custom token"** ou **"R2 Token"** (se disponível)

3. **Configurar Permissões**:
   - **Account Resources**: Selecione sua conta
   - **Permissions**: 
     - `Cloudflare R2:Edit` (para upload/download)
     - Ou `Cloudflare R2:Read` + `Cloudflare R2:Write` separadamente
   - **Account Resources**: Selecione o bucket `trashtalk-audio-files` ou "All buckets"

4. **Salvar Credenciais**:
   - Após criar, você verá:
     - **Access Key ID** (ex: `abc123def456...`)
     - **Secret Access Key** (ex: `xyz789...`) - **⚠️ Só aparece uma vez!**
   - **Copie e guarde ambos em local seguro**

## Passo 4: Configurar CORS (Opcional mas Recomendado)

Se você quiser acesso direto do Flutter (sem passar pelo proxy), configure CORS:

1. **No Dashboard R2**:
   - Vá em **R2 > Settings** (ou configurações do bucket)
   - Procure por **"CORS Policy"** ou **"CORS Configuration"**

2. **Adicionar Regra CORS**:
   ```json
   [
     {
       "AllowedOrigins": ["*"],
       "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
       "AllowedHeaders": ["*"],
       "ExposeHeaders": ["ETag", "Content-Length"],
       "MaxAgeSeconds": 3600
     }
   ]
   ```

   **⚠️ Nota**: `"*"` permite qualquer origem. Para produção, substitua por domínios específicos.

## Passo 5: Verificar Configuração

### Teste Rápido via Dashboard

1. **Upload de Teste**:
   - No bucket `trashtalk-audio-files`, clique em **"Upload"**
   - Faça upload de um arquivo pequeno de teste
   - Verifique se aparece na lista

2. **Verificar URL Pública** (se configurado):
   - Cloudflare R2 não expõe URLs públicas por padrão
   - Você precisará usar o proxy do Supabase ou configurar um Custom Domain

## Resumo das Credenciais Necessárias

Após completar os passos acima, você terá:

| Credencial | Onde Encontrar | Exemplo |
|------------|----------------|---------|
| **Account ID** | Dashboard superior direito ou R2 Overview | `abc123def456789` |
| **Access Key ID** | API Tokens (após criar token) | `abc123def456...` |
| **Secret Access Key** | API Tokens (só aparece uma vez!) | `xyz789secret...` |
| **Bucket Name** | Nome que você escolheu | `trashtalk-audio-files` |

## Próximos Passos

Agora que você tem as credenciais do Cloudflare R2:

1. **Configure as variáveis de ambiente no Supabase** (veja `QUICK_START.md`)
2. **Faça o deploy da Edge Function** (veja `QUICK_START.md`)
3. **Teste a conexão** usando os comandos curl em `R2_SETUP.md`

## Troubleshooting

### Problema: "Access Denied" ao fazer upload
- **Solução**: Verifique se o token tem permissões de `Write`
- Verifique se o bucket name está correto

### Problema: "Bucket not found"
- **Solução**: Confirme que o bucket foi criado e o nome está exatamente igual
- Verifique se está usando o Account ID correto

### Problema: CORS errors no Flutter
- **Solução**: Configure CORS no bucket (Passo 4) ou use o proxy do Supabase

## Recursos Úteis

- [Documentação Oficial R2](https://developers.cloudflare.com/r2/)
- [API Reference R2](https://developers.cloudflare.com/r2/api/s3/api/)
- [Pricing R2](https://developers.cloudflare.com/r2/pricing/) - Lembre-se: **egress é grátis!**
