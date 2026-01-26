# 📦 Instalar Supabase CLI

## Linux/WSL

```bash
# Instalar via npm (se tiver Node.js)
npm install -g supabase

# Ou via Homebrew (se tiver)
brew install supabase/tap/supabase

# Ou baixar binário direto
curl -fsSL https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar -xz
sudo mv supabase /usr/local/bin/
```

## Verificar Instalação

```bash
supabase --version
```

## Login

```bash
supabase login
```

## Linkar Projeto

```bash
supabase link --project-ref lkdigbdgpaquhevpfrdf
```

## Fazer Deploy

```bash
supabase functions deploy r2-proxy --no-verify-jwt
```
