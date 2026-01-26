# 🐳 Desenvolvimento com Supabase Local

## Visão Geral

Este projeto suporta desenvolvimento local usando Supabase CLI e Docker. Isso permite testar Edge Functions e outras funcionalidades sem depender do ambiente de produção.

## Pré-requisitos

1. **Docker Desktop** instalado e rodando
2. **Supabase CLI** instalado:
   ```bash
   npm install -g supabase
   ```

## Configuração Inicial

### 1. Iniciar Supabase Local

```bash
# Na raiz do projeto
supabase start
```

Isso vai:
- ✅ Iniciar todos os containers Docker necessários
- ✅ Criar o banco de dados local
- ✅ Aplicar as migrations
- ✅ Iniciar o Supabase Studio (http://localhost:54323)

### 2. Verificar Status

```bash
supabase status
```

Você verá algo como:
```
API URL: http://127.0.0.1:54321
GraphQL URL: http://127.0.0.1:54321/graphql/v1
DB URL: postgresql://postgres:postgres@127.0.0.1:54322/postgres
Studio URL: http://127.0.0.1:54323
Inbucket URL: http://127.0.0.1:54324
JWT secret: super-secret-jwt-token-with-at-least-32-characters-long
anon key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
service_role key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. Configurar o Flutter para Usar Supabase Local

Edite `lib/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  // Para desenvolvimento local
  static const String supabaseUrl = 'http://127.0.0.1:54321';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // Use a anon key do `supabase status`
  
  // ... resto do código
}
```

**⚠️ Importante**: Use a `anon key` que aparece no output de `supabase status`.

## Deploy de Edge Functions Localmente

### Deploy da Função r2-proxy

```bash
# Deploy local
supabase functions deploy r2-proxy --no-verify-jwt

# Ou usando o script
./deploy-r2-proxy.sh
```

### Configurar Variáveis de Ambiente Locais

As variáveis de ambiente para Edge Functions locais são configuradas no arquivo `.env` na raiz do projeto:

```bash
# .env (criar se não existir)
R2_ACCOUNT_ID=seu-account-id
R2_ACCESS_KEY_ID=seu-access-key
R2_SECRET_ACCESS_KEY=seu-secret-key
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=sua-anon-key-local
```

## Comandos Úteis

### Parar Supabase Local

```bash
supabase stop
```

### Reiniciar (com reset do banco)

```bash
supabase stop
supabase start
```

### Ver Logs

```bash
# Logs do Supabase
supabase logs

# Logs de uma Edge Function específica
supabase functions logs r2-proxy
```

### Aplicar Migrations

```bash
supabase db reset
```

## Troubleshooting

### Docker não está rodando

**Erro**: `Error: Cannot connect to the Docker daemon`

**Solução**: 
1. Inicie o Docker Desktop
2. Aguarde até que o Docker esteja completamente iniciado
3. Execute `supabase start` novamente

### Porta já em uso

**Erro**: `Error: port 54321 is already in use`

**Solução**:
1. Verifique se há outro Supabase local rodando: `supabase status`
2. Pare o Supabase: `supabase stop`
3. Ou pare o processo que está usando a porta

### Edge Function não funciona localmente

**Problema**: CORS ou 502 errors

**Solução**:
1. Certifique-se de que o Docker está rodando
2. Verifique se a função foi deployada: `supabase functions list`
3. Verifique os logs: `supabase functions logs r2-proxy`
4. Certifique-se de que as variáveis de ambiente estão configuradas

## Quando Usar Local vs Produção

### Use Supabase Local quando:
- ✅ Desenvolvendo novas funcionalidades
- ✅ Testando Edge Functions
- ✅ Testando migrations
- ✅ Desenvolvendo sem custos de API

### Use Supabase Produção quando:
- ✅ Testando integração completa
- ✅ Testando com dados reais
- ✅ Deploy para produção
- ✅ Testando performance

## Migração entre Local e Produção

Para alternar entre local e produção, apenas altere as credenciais em `supabase_config.dart`:

```dart
// Local
static const String supabaseUrl = 'http://127.0.0.1:54321';

// Produção
static const String supabaseUrl = 'https://lkdigbdgpaquhevpfrdf.supabase.co';
```

## Notas Importantes

1. **CORS no Local**: O Supabase local geralmente tem CORS mais permissivo, mas ainda precisa estar configurado corretamente nas Edge Functions.

2. **R2 no Local**: Para desenvolvimento local, você ainda precisa das credenciais do R2 (Cloudflare) reais, pois o storage local não suporta R2.

3. **Autenticação**: O Supabase local usa JWT tokens diferentes. Certifique-se de usar a `anon key` correta do ambiente local.

4. **Dados**: Os dados no Supabase local são isolados. Não há sincronização automática com produção.

---

**Última atualização**: 2025-01-26
**Status**: ✅ Funcionando com Docker
