# 🔧 Correção de Erro CORS

## Problema

Erro no console do navegador:
```
Access to fetch at 'https://...supabase.co/functions/v1/r2-proxy/...' 
from origin 'http://localhost:6769' has been blocked by CORS policy: 
Response to preflight request doesn't pass access control check: 
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## Causa

A Edge Function do Supabase não está retornando os headers CORS necessários para permitir requisições do navegador.

## Solução Aplicada

A Edge Function `r2-proxy` foi atualizada para:

1. **Adicionar headers CORS em todas as respostas**:
   ```typescript
   const corsHeaders = {
     'Access-Control-Allow-Origin': '*',
     'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
     'Access-Control-Allow-Methods': 'GET, PUT, POST, DELETE, OPTIONS',
   }
   ```

2. **Tratar requisições OPTIONS (preflight)**:
   - O navegador envia uma requisição OPTIONS antes do PUT/POST
   - A função agora responde corretamente a essas requisições

3. **Incluir headers em todas as respostas**:
   - GET (download)
   - PUT (upload)
   - Erros
   - Métodos não permitidos

## Próximos Passos

Após fazer o deploy da Edge Function atualizada:

```bash
npx supabase functions deploy r2-proxy
```

O upload deve funcionar sem erros de CORS.

## Segurança (Produção)

⚠️ **Para produção**, considere restringir `Access-Control-Allow-Origin`:

```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://seu-dominio.com',
  // ... outros headers
}
```

Ou use uma lista de origens permitidas.

## Verificação

Após o deploy, teste o upload novamente. O erro de CORS deve desaparecer.
