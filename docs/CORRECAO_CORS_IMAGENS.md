# 🔧 Correção de CORS para Imagens

## Problema

Ao tentar carregar imagens do R2 diretamente, o navegador bloqueava as requisições com erro de CORS:
```
Access to XMLHttpRequest at 'https://...r2.cloudflarestorage.com/...' 
from origin 'http://localhost:6769' has been blocked by CORS policy: 
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## Solução Implementada

### 1. Edge Function como Proxy para Imagens

A Edge Function `r2-proxy` foi modificada para servir imagens diretamente através do proxy, evitando problemas de CORS:

- **Para imagens** (jpg, png, gif, webp, svg): A Edge Function baixa a imagem do R2 e a serve diretamente com headers CORS corretos
- **Para outros arquivos** (áudio): Mantém o comportamento original de retornar URL assinada

### 2. Código Flutter Atualizado

O `ImageRepository` agora tem um método `getProxyImageUrl()` que retorna a URL da Edge Function diretamente, em vez de obter uma URL assinada do R2.

## Como Funciona

1. **Upload**: A imagem é enviada para o R2 via Edge Function (PUT)
2. **Armazenamento**: O caminho relativo é salvo no banco (ex: `covers/123456-image.jpg`)
3. **Exibição**: O Flutter usa `getProxyImageUrl()` para obter a URL do proxy
4. **Proxy**: A Edge Function valida autenticação, baixa a imagem do R2 e a serve com CORS headers

## Deploy Necessário

⚠️ **IMPORTANTE**: Você precisa fazer deploy da Edge Function atualizada:

```bash
supabase functions deploy r2-proxy --no-verify-jwt
```

## Benefícios

- ✅ Sem problemas de CORS
- ✅ Autenticação validada antes de servir
- ✅ Cache headers para melhor performance
- ✅ Funciona em desenvolvimento e produção

## Estrutura de URLs

- **Antes**: `https://...r2.cloudflarestorage.com/covers/image.jpg` (bloqueado por CORS)
- **Agora**: `https://xxx.supabase.co/functions/v1/r2-proxy/covers/image.jpg` (funciona!)
