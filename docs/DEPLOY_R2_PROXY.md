# 🚀 Deploy da Edge Function R2-Proxy

## Problema Atual

O erro que você está vendo:
```
FormatException: SyntaxError: Unexpected token 'R', "RIFF°ñk WA"... is not valid JSON
```

Isso significa que a **Edge Function no servidor ainda está na versão antiga** que retorna o arquivo binário diretamente, em vez de retornar o JSON com a URL assinada.

## Solução: Deploy da Nova Versão

Execute este comando no terminal (na raiz do projeto):

```bash
supabase functions deploy r2-proxy --no-verify-jwt
```

> **Nota**: O `--no-verify-jwt` é necessário porque a função já faz validação manual do JWT internamente.

## Verificar se Deploy Funcionou

Após o deploy, teste fazendo uma requisição manual:

```bash
curl -H "Authorization: Bearer [SEU_TOKEN]" \
  https://lkdigbdgpaquhevpfrdf.supabase.co/functions/v1/r2-proxy/[caminho-do-arquivo]
```

**Resposta esperada (JSON)**:
```json
{"url":"https://[account-id].r2.cloudflarestorage.com/..."}
```

**Resposta antiga (binário)**:
```
RIFF... (dados do arquivo WAV)
```

## Se o Deploy Falhar

1. **Verificar variáveis de ambiente no Supabase Dashboard**:
   - `R2_ACCOUNT_ID`
   - `R2_ACCESS_KEY_ID`
   - `R2_SECRET_ACCESS_KEY`

2. **Verificar se está logado no Supabase CLI**:
   ```bash
   supabase login
   ```

3. **Verificar se o projeto está linkado**:
   ```bash
   supabase link --project-ref lkdigbdgpaquhevpfrdf
   ```

## Após o Deploy

1. **Recarregue o app** (hot restart não é suficiente, faça um refresh completo)
2. **Teste novamente** - agora deve funcionar muito mais rápido! ⚡
