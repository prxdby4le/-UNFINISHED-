# 🚀 Deploy Rápido no Vercel

## Passo a Passo Simplificado

### 1️⃣ Preparar o Repositório

```bash
# Certifique-se de que está tudo commitado
git add .
git commit -m "Preparar para deploy no Vercel"
git push
```

### 2️⃣ Criar Conta no Vercel

1. Acesse [vercel.com](https://vercel.com)
2. Faça login com GitHub/GitLab/Bitbucket
3. Clique em **"Add New..."** → **"Project"**

### 3️⃣ Importar Projeto

1. Selecione seu repositório
2. Clique em **"Import"**

### 4️⃣ Configurar Variáveis de Ambiente

**No dashboard do projeto → Settings → Environment Variables:**

Adicione estas variáveis (marque para Production, Preview e Development):

```
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anon
R2_ACCOUNT_ID=seu-account-id
R2_ACCESS_KEY_ID=sua-access-key
R2_SECRET_ACCESS_KEY=sua-secret-key
R2_BUCKET_NAME=nome-do-bucket
R2_ENDPOINT=https://account-id.r2.cloudflarestorage.com
```

### 5️⃣ Configurar Build Settings

**No dashboard do projeto → Settings → General:**

- **Build Command**: `chmod +x vercel_build.sh && ./vercel_build.sh`
- **Output Directory**: `build/web`
- **Install Command**: (deixe vazio)
- **Framework Preset**: `Other`

### 6️⃣ Fazer Deploy

1. Clique em **"Deploy"**
2. Aguarde o build (5-10 minutos na primeira vez)
3. Acesse a URL fornecida

### 7️⃣ Verificar

✅ Login funciona  
✅ Projetos carregam  
✅ Upload funciona  
✅ Áudio toca  
✅ Imagens carregam  
✅ Waveform funciona  

---

**Pronto!** 🎉

Para mais detalhes, veja [docs/DEPLOY_VERCEL.md](docs/DEPLOY_VERCEL.md)
