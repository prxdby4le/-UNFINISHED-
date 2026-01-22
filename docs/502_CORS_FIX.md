# 🔧 Correção de Erro 502 e CORS

## Problemas Identificados

1. **502 Bad Gateway**: A Edge Function pode estar crashando antes de retornar uma resposta
2. **CORS Error**: Headers CORS não estão sendo retornados em todas as respostas
3. **401 Unauthorized**: Pode ser causado pelo 502 ou por token inválido

## Correções Aplicadas

### 1. Try-Catch Global
- Adicionado try-catch global para garantir que **TODOS** os erros retornem headers CORS
- Isso previne o erro 502 causado por exceções não tratadas

### 2. Validação de Configuração
- Verificação se as credenciais do R2 estão configuradas antes de criar o cliente S3
- Mensagens de erro mais claras quando as variáveis de ambiente estão faltando

### 3. Headers CORS em Todas as Respostas
- Garantido que **TODAS** as respostas (sucesso, erro, 401, 500) incluem headers CORS
- Isso resolve o erro "No 'Access-Control-Allow-Origin' header is present"

## Próximos Passos

### 1. Verificar se a Edge Function está Deployada

```bash
npx supabase functions deploy r2-proxy
```

Ou via Dashboard:
1. Vá em **Supabase Dashboard > Edge Functions > r2-proxy**
2. Verifique se o código está atualizado
3. Clique em **Deploy** se necessário

### 2. Verificar Variáveis de Ambiente

No Supabase Dashboard:
1. Vá em **Edge Functions > r2-proxy > Settings**
2. Verifique se as seguintes variáveis estão configuradas:
   - `R2_ACCOUNT_ID`
   - `R2_ACCESS_KEY_ID`
   - `R2_SECRET_ACCESS_KEY`

**Nota**: `SUPABASE_URL` e `SUPABASE_ANON_KEY` são automaticamente disponibilizadas pelo Supabase.

### 3. Verificar Logs

Após fazer o deploy, verifique os logs:
1. Vá em **Supabase Dashboard > Edge Functions > r2-proxy > Logs**
2. Procure por erros relacionados a:
   - Credenciais do R2 faltando
   - Erros de conexão com o R2
   - Erros de validação de JWT

### 4. Testar a Função

Você pode testar a função diretamente:

```bash
curl -X OPTIONS https://lkdigbdgpaquhevpfrdf.supabase.co/functions/v1/r2-proxy \
  -H "Origin: http://localhost:6769" \
  -v
```

Deve retornar `204 No Content` com headers CORS.

## Se o Problema Persistir

### Verificar se o Token JWT é Válido

1. Faça logout e login novamente no app
2. O token pode ter expirado

### Verificar Credenciais do R2

1. Confirme que o bucket `trashtalk-audio-files` existe no Cloudflare R2
2. Verifique se as credenciais estão corretas
3. Teste as credenciais usando a AWS CLI ou um cliente S3

### Verificar Logs da Edge Function

Os logs mostrarão exatamente onde o erro está ocorrendo:
- Se for erro de autenticação, verá "Auth error: ..."
- Se for erro de R2, verá "R2 Error: ..."
- Se for erro crítico, verá "Critical error in r2-proxy: ..."

## Estrutura de Erros

Agora todos os erros retornam com headers CORS:

- **401 Unauthorized**: Token inválido ou ausente → Headers CORS incluídos
- **500 Internal Server Error**: Erro no servidor → Headers CORS incluídos
- **502 Bad Gateway**: Não deve mais ocorrer (try-catch global)

## Debug

Para debugar, adicione logs temporários na Edge Function:

```typescript
console.log('Request method:', req.method)
console.log('Request URL:', req.url)
console.log('Auth header present:', !!authHeader)
```

Veja os logs em: **Supabase Dashboard > Edge Functions > r2-proxy > Logs**
