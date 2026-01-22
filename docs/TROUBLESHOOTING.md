# 🔧 Troubleshooting - Resolução de Problemas

## Erro 404 ou "Failed to fetch" na Autenticação

### Sintomas
```
AuthUnknownException: Received an empty response with status code 404
AuthRetryableFetchException: Client failed to fetch, uri=https://supabase.com/dashboard/...
```

### ⚠️ Erro Comum: URL Incorreta

**O erro mostra `supabase.com/dashboard`** - isso está ERRADO!

A URL correta deve ser: `https://[PROJECT_REF].supabase.co`

### Causas Possíveis

1. **URL do Supabase Incorreta** ⚠️ MAIS COMUM
   - ❌ ERRADO: `https://supabase.com/dashboard/project/...`
   - ✅ CORRETO: `https://lkdigbdgpaquhevpfrdf.supabase.co`
   - A URL deve ser da **API do projeto**, não do dashboard
   - Encontre a URL correta em: Supabase Dashboard > Project Settings > API > **Project URL**

2. **Chave Anon Incorreta**
   - Verifique se está usando a chave **anon/public**, não a service_role
   - Encontre em: Supabase Dashboard > Project Settings > API > **anon public**
   - Formato: geralmente começa com `eyJ...` (JWT)

3. **Projeto Supabase Não Existe ou Foi Deletado**
   - Verifique se o projeto ainda existe no Supabase Dashboard
   - Se necessário, crie um novo projeto

4. **Projeto Pausado**
   - Projetos gratuitos podem ser pausados após inatividade
   - Verifique no Dashboard se o projeto está ativo
   - Se pausado, clique em "Restore"

### Solução

1. **Verificar Credenciais**:
   ```dart
   // lib/core/config/supabase_config.dart
   static const String supabaseUrl = 'https://SEU-PROJETO-ID.supabase.co';
   static const String supabaseAnonKey = 'sua-chave-anon-aqui';
   ```

2. **Testar Conexão**:
   - Acesse a URL do seu projeto no navegador
   - Deve retornar uma página JSON ou erro de autenticação (não 404)

3. **Verificar Tabelas**:
   - Certifique-se de que executou os scripts SQL em `docs/DATABASE_SCHEMA.md`
   - Verifique se a tabela `profiles` existe

## Outros Erros Comuns

### Erro: "Table not found"
- **Causa**: Tabelas não foram criadas no Supabase
- **Solução**: Execute os scripts SQL em `docs/DATABASE_SCHEMA.md`

### Erro: "Row Level Security policy violation"
- **Causa**: RLS está bloqueando acesso
- **Solução**: Verifique se as políticas RLS estão configuradas corretamente

### Erro: "MissingPluginException" na Web
- **Causa**: Plugin não suporta web
- **Solução**: Já corrigido - o código detecta web e usa alternativas

### Erro: Upload falha
- **Causa**: Edge Function não configurada ou R2 não configurado
- **Solução**: Siga `docs/R2_SETUP.md` e `docs/CLOUDFLARE_R2_SETUP.md`

## Verificação Rápida

Execute este checklist:

- [ ] URL do Supabase está correta
- [ ] Chave anon está correta
- [ ] Projeto está ativo no Supabase
- [ ] Tabelas foram criadas (profiles, projects, audio_versions, feedback)
- [ ] RLS está configurado
- [ ] Edge Function r2-proxy está deployada
- [ ] Cloudflare R2 está configurado

## Suporte

Se o problema persistir:
1. Verifique os logs do console do navegador
2. Verifique os logs do Supabase Dashboard
3. Verifique os logs da Edge Function
