#!/bin/bash

# Script para fazer deploy da Edge Function r2-proxy
# Garante que o CORS está configurado corretamente

set -e

echo "🚀 Deploying r2-proxy Edge Function..."
echo ""

# Verificar se supabase CLI está instalado
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI não encontrado!"
    echo "   Instale com: npm install -g supabase"
    exit 1
fi

# Verificar se está logado
echo "📋 Verificando autenticação..."
if ! supabase projects list &> /dev/null; then
    echo "❌ Não autenticado no Supabase!"
    echo "   Execute: supabase login"
    exit 1
fi

# Fazer deploy
echo "📦 Fazendo deploy da função..."
supabase functions deploy r2-proxy --no-verify-jwt

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deploy concluído com sucesso!"
    echo ""
    echo "🧪 Testando CORS..."
    echo ""
    
    # Testar OPTIONS (preflight)
    echo "Testando OPTIONS (preflight):"
    curl -X OPTIONS \
      "https://lkdigbdgpaquhevpfrdf.supabase.co/functions/v1/r2-proxy/test" \
      -H "Origin: http://localhost:6769" \
      -H "Access-Control-Request-Method: GET" \
      -H "Access-Control-Request-Headers: authorization" \
      -v 2>&1 | grep -E "(HTTP|Access-Control|200|204)" || true
    
    echo ""
    echo "✅ Se você viu 'Access-Control-Allow-Origin' acima, o CORS está funcionando!"
    echo ""
    echo "📝 Próximos passos:"
    echo "   1. Limpe o cache do navegador (Ctrl+Shift+R)"
    echo "   2. Recarregue a aplicação"
    echo "   3. Verifique os logs no Supabase Dashboard se ainda houver problemas"
else
    echo ""
    echo "❌ Erro no deploy!"
    echo "   Verifique os logs acima para mais detalhes"
    exit 1
fi
