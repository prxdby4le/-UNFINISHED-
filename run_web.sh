#!/bin/bash
# Script para rodar Flutter Web em porta fixa

PORT=${1:-8080}

echo "🚀 Iniciando Flutter Web na porta $PORT..."
flutter run -d chrome --web-port=$PORT
