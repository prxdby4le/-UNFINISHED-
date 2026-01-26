# 🚀 Guia de Deploy no Vercel

Este guia explica como fazer deploy do projeto Flutter Web no Vercel.

## 📋 Pré-requisitos

1. Conta no [Vercel](https://vercel.com)
2. Conta no [GitHub](https://github.com) (recomendado) ou GitLab/Bitbucket
3. Projeto já configurado com Supabase e Cloudflare R2
4. Credenciais do Supabase e R2 disponíveis

## 🔧 Passo 1: Preparar o Repositório

### 1.1. Verificar arquivos de configuração

Certifique-se de que os seguintes arquivos existem:

- ✅ `vercel.json` - Configuração do Vercel
- ✅ `vercel_build.sh` - Script de build
- ✅ `pubspec.yaml` - Dependências do Flutter

### 1.2. Verificar .gitignore

Certifique-se de que o `.gitignore` inclui:
```
# Build
build/
.dart_tool/
*.dill

# Config (será criado via variáveis de ambiente)
lib/core/config/supabase_config.dart
```

## 🔑 Passo 2: Configurar Variáveis de Ambiente no Vercel

### 2.1. Acessar o Dashboard do Vercel

1. Acesse [vercel.com](https://vercel.com)
2. Faça login com sua conta
3. Clique em "Add New..." → "Project"

### 2.2. Importar o Repositório

1. Conecte seu repositório GitHub/GitLab/Bitbucket
2. Selecione o repositório do projeto
3. Clique em "Import"

### 2.3. Configurar Variáveis de Ambiente

Antes de fazer o deploy, configure as seguintes variáveis de ambiente no Vercel:

**No dashboard do projeto → Settings → Environment Variables:**

| Variável | Descrição | Onde encontrar |
|----------|-----------|----------------|
| `SUPABASE_URL` | URL do projeto Supabase | Supabase Dashboard → Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Chave anônima do Supabase | Supabase Dashboard → Settings → API → anon public key |
| `R2_ACCOUNT_ID` | Account ID do Cloudflare R2 | Cloudflare Dashboard → R2 → Overview |
| `R2_ACCESS_KEY_ID` | Access Key ID do R2 | Cloudflare Dashboard → R2 → Manage R2 API Tokens |
| `R2_SECRET_ACCESS_KEY` | Secret Access Key do R2 | Cloudflare Dashboard → R2 → Manage R2 API Tokens |
| `R2_BUCKET_NAME` | Nome do bucket R2 | Cloudflare Dashboard → R2 → Seu bucket |
| `R2_ENDPOINT` | Endpoint do R2 | Geralmente: `https://<account-id>.r2.cloudflarestorage.com` |

**⚠️ IMPORTANTE:**
- Marque todas as variáveis para **Production**, **Preview** e **Development**
- Não compartilhe essas chaves publicamente

## ⚙️ Passo 3: Configurar Build Settings

### 3.1. Framework Preset

No Vercel, configure:
- **Framework Preset**: `Other` ou deixe em branco
- **Build Command**: `chmod +x vercel_build.sh && ./vercel_build.sh`
- **Output Directory**: `build/web`
- **Install Command**: (deixe vazio, o script cuida disso)

### 3.2. Root Directory

Se o projeto estiver em uma subpasta, configure o **Root Directory**:
- Exemplo: Se o projeto está em `projetos/[UNFINISHED]`, configure como `projetos/[UNFINISHED]`

## 🚀 Passo 4: Fazer o Deploy

### 4.1. Deploy Automático (Recomendado)

1. Após configurar as variáveis de ambiente, clique em **"Deploy"**
2. O Vercel irá:
   - Clonar o repositório
   - Executar o script `vercel_build.sh`
   - Fazer build do Flutter Web
   - Fazer deploy dos arquivos estáticos

### 4.2. Deploy Manual (via CLI)

Se preferir usar a CLI do Vercel:

```bash
# 1. Instalar Vercel CLI
npm i -g vercel

# 2. Fazer login
vercel login

# 3. Configurar variáveis de ambiente (opcional, pode fazer no dashboard)
vercel env add SUPABASE_URL
vercel env add SUPABASE_ANON_KEY
# ... (repita para todas as variáveis)

# 4. Fazer deploy
vercel --prod
```

## 🔍 Passo 5: Verificar o Deploy

### 5.1. Verificar Build Logs

1. No dashboard do Vercel, vá para **Deployments**
2. Clique no deployment mais recente
3. Verifique os logs de build:
   - ✅ Deve mostrar "🚀 Iniciando build para Vercel..."
   - ✅ Deve mostrar "🔨 Compilando para Web..."
   - ✅ Deve terminar com sucesso

### 5.2. Testar a Aplicação

1. Acesse a URL fornecida pelo Vercel (ex: `seu-projeto.vercel.app`)
2. Teste:
   - ✅ Login funciona
   - ✅ Carregamento de projetos
   - ✅ Upload de áudio
   - ✅ Reprodução de áudio
   - ✅ Carregamento de imagens (sem CORS)
   - ✅ Waveform funciona

## 🐛 Troubleshooting

### Erro: "Flutter not found"

**Solução**: O script `vercel_build.sh` já instala o Flutter automaticamente. Verifique se o script tem permissão de execução.

### Erro: "SUPABASE_URL not found"

**Solução**: 
1. Verifique se configurou todas as variáveis de ambiente no Vercel
2. Certifique-se de que marcou para Production/Preview/Development
3. Faça um novo deploy após adicionar as variáveis

### Erro: "Build failed"

**Solução**:
1. Verifique os logs de build no Vercel
2. Certifique-se de que todas as dependências estão no `pubspec.yaml`
3. Verifique se o Flutter está configurado corretamente no script

### Erro de CORS no Waveform

**Solução**: 
- O waveform usa a Edge Function do Supabase que já tem CORS configurado
- Se ainda houver erro, verifique se a Edge Function está deployada:
  ```bash
  supabase functions deploy r2-proxy --no-verify-jwt
  ```

### Erro: "Cannot find module"

**Solução**:
- Verifique se o `pubspec.yaml` está correto
- O script já executa `flutter pub get`

## 📝 Notas Importantes

### Performance

- O build do Flutter Web pode demorar 5-10 minutos na primeira vez
- Builds subsequentes são mais rápidos devido ao cache do Vercel

### Limitações do Vercel

- **Tempo de build**: Máximo de 45 minutos (gratuito)
- **Tamanho do build**: Máximo de 100MB (gratuito)
- **Funções serverless**: Não usamos neste projeto (tudo é estático)

### Custom Domain

Para usar um domínio customizado:

1. No dashboard do Vercel, vá para **Settings → Domains**
2. Adicione seu domínio
3. Configure os DNS conforme instruções do Vercel

## 🔄 Atualizações Futuras

Após o deploy inicial, todas as atualizações são automáticas:

1. Faça push para a branch `main` (ou a branch configurada)
2. O Vercel detecta automaticamente
3. Faz build e deploy automaticamente
4. Você recebe uma notificação quando estiver pronto

## 📚 Recursos Adicionais

- [Documentação do Vercel](https://vercel.com/docs)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

## ✅ Checklist Final

Antes de considerar o deploy completo, verifique:

- [ ] Todas as variáveis de ambiente configuradas
- [ ] Build executado com sucesso
- [ ] Aplicação acessível na URL do Vercel
- [ ] Login funciona
- [ ] Upload de arquivos funciona
- [ ] Reprodução de áudio funciona
- [ ] Imagens carregam sem erro de CORS
- [ ] Waveform funciona corretamente
- [ ] Edge Function `r2-proxy` está deployada no Supabase

---

**Pronto!** Seu projeto está no ar! 🎉
