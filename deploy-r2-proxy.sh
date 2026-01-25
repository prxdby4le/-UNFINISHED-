#!/bin/bash
# Script de deploy da Edge Function r2-proxy

echo "🚀 Fazendo deploy da Edge Function r2-proxy..."
echo ""

# Verificar se está logado
echo "📋 Verificando login no Supabase..."
if ! supabase projects list &>/dev/null; then
    echo "❌ Você não está logado no Supabase CLI"
    echo "   Execute: supabase login"
    exit 1
fi

# Verificar se o projeto está linkado
echo "📋 Verificando se o projeto está linkado..."
if ! supabase status &>/dev/null; then
    echo "⚠️  Projeto não está linkado. Fazendo link..."
    supabase link --project-ref lkdigbdgpaquhevpfrdf
fi

# Fazer deploy
echo ""
echo "📦 Fazendo deploy da função..."
echo "   ⚠️  IMPORTANTE: Usando --no-verify-jwt para permitir OPTIONS (preflight)"
echo ""

supabase functions deploy r2-proxy --no-verify-jwt

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deploy concluído com sucesso!"
    echo ""
    echo "📝 Próximos passos:"
    echo "   1. Recarregue o app completamente (Ctrl+Shift+R ou Cmd+Shift+R)"
    echo "   2. Teste novamente - agora deve retornar JSON com URL assinada"
    echo ""
    echo "🔍 Para verificar os logs:"
    echo "   - Supabase Dashboard > Edge Functions > r2-proxy > Logs"
    echo "   - Procure por: '[R2-Proxy] GET request - Generating signed URL'"
else
    echo ""
    echo "❌ Erro no deploy. Verifique:"
    echo "   - Se está logado: supabase login"
    echo "   - Se o projeto está linkado: supabase link --project-ref lkdigbdgpaquhevpfrdf"
    echo "   - Se as variáveis de ambiente estão configuradas no Dashboard"
    exit 1
fi
