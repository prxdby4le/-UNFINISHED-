#!/bin/bash

# Script para testar se o CORS está funcionando corretamente

SUPABASE_URL="https://lkdigbdgpaquhevpfrdf.supabase.co"
FUNCTION_URL="${SUPABASE_URL}/functions/v1/r2-proxy/test"
ORIGIN="http://localhost:6769"

echo "🧪 Testando CORS da Edge Function r2-proxy"
echo ""

# Teste 1: OPTIONS (preflight)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Testando OPTIONS (preflight request)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESPONSE=$(curl -s -X OPTIONS \
  "${FUNCTION_URL}" \
  -H "Origin: ${ORIGIN}" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: authorization" \
  -i)

echo "$RESPONSE" | head -20

# Verificar headers CORS
if echo "$RESPONSE" | grep -q "Access-Control-Allow-Origin"; then
    echo ""
    echo "✅ CORS headers encontrados!"
else
    echo ""
    echo "❌ CORS headers NÃO encontrados!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Verificando status code"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

STATUS=$(echo "$RESPONSE" | head -1 | grep -oE "HTTP/[0-9.]+ [0-9]+" | grep -oE "[0-9]+$")
echo "Status code: $STATUS"

if [ "$STATUS" = "200" ] || [ "$STATUS" = "204" ]; then
    echo "✅ Status code correto!"
else
    echo "❌ Status code incorreto! Esperado: 200 ou 204, Recebido: $STATUS"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Headers CORS presentes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CORS_HEADERS=(
    "Access-Control-Allow-Origin"
    "Access-Control-Allow-Methods"
    "Access-Control-Allow-Headers"
)

for header in "${CORS_HEADERS[@]}"; do
    if echo "$RESPONSE" | grep -qi "$header"; then
        VALUE=$(echo "$RESPONSE" | grep -i "$header" | head -1)
        echo "✅ $VALUE"
    else
        echo "❌ $header NÃO encontrado!"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Resumo"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if echo "$RESPONSE" | grep -q "Access-Control-Allow-Origin" && ([ "$STATUS" = "200" ] || [ "$STATUS" = "204" ]); then
    echo "✅ CORS está configurado corretamente!"
    echo ""
    echo "💡 Se ainda houver problemas no navegador:"
    echo "   1. Limpe o cache (Ctrl+Shift+R)"
    echo "   2. Teste em modo anônimo"
    echo "   3. Verifique os logs da Edge Function no Supabase Dashboard"
else
    echo "❌ CORS NÃO está configurado corretamente!"
    echo ""
    echo "💡 Próximos passos:"
    echo "   1. Execute: ./deploy-r2-proxy.sh"
    echo "   2. Verifique se a função está deployada no Supabase Dashboard"
    echo "   3. Verifique as variáveis de ambiente da função"
fi
