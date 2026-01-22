# 🔐 Correção de Erro JWT (Invalid JWT)

## Problema

Erro ao fazer upload:
```
Erro no upload: 401 - {"code":401,"message":"Invalid JWT"}
```

## Causa

A Edge Function não está validando o JWT corretamente ou o token não está sendo enviado com os headers necessários.

## Soluções Aplicadas

### 1. Validação de JWT na Edge Function

A Edge Function agora:
- Usa `@supabase/supabase-js` para validar o token
- Verifica se o usuário existe e está autenticado
- Retorna erros mais descritivos

### 2. Headers Corretos no Flutter

O código Flutter agora envia:
- `Authorization: Bearer <token>` - Token JWT do usuário
- `apikey: <anon-key>` - Chave anon do Supabase (necessária para Edge Functions)

## Variáveis de Ambiente Necessárias

A Edge Function precisa das variáveis de ambiente do Supabase (disponíveis automaticamente):

- `SUPABASE_URL` - URL do projeto
- `SUPABASE_ANON_KEY` - Chave anon

**Nota**: Essas variáveis são automaticamente disponibilizadas pelo Supabase nas Edge Functions. Você não precisa configurá-las manualmente.

### Como a Validação Funciona

1. O Flutter envia o token JWT no header `Authorization: Bearer <token>`
2. O Flutter também envia o `apikey` no header (chave anon do Supabase)
3. A Edge Function cria um cliente Supabase com o token no header
4. A Edge Function chama `getUser()` que valida o token automaticamente
5. Se o token for válido, o upload/download prossegue

## Verificação

Após fazer o deploy da Edge Function atualizada:

```bash
npx supabase functions deploy r2-proxy
```

O upload deve funcionar corretamente.

## Se o Erro Persistir

1. **Verifique se está logado**: O token pode ter expirado
   - Faça logout e login novamente

2. **Verifique o token**: Adicione logs temporários para ver o token sendo enviado
   ```dart
   print('Token: ${session?.accessToken}');
   ```

3. **Verifique variáveis de ambiente**: Confirme que as variáveis do R2 estão configuradas:
   - `R2_ACCOUNT_ID`
   - `R2_ACCESS_KEY_ID`
   - `R2_SECRET_ACCESS_KEY`

## Debug

Para debugar, adicione logs na Edge Function:

```typescript
console.log('Auth header:', authHeader?.substring(0, 20))
console.log('User:', user?.id)
```

Veja os logs em: Supabase Dashboard > Edge Functions > r2-proxy > Logs
