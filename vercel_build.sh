#!/bin/bash
set -e  # Parar em caso de erro

echo "🚀 Iniciando build para Vercel..."

# 1. Instalar Flutter
if [ -d "flutter" ]; then
  echo "📦 Flutter já existe, atualizando..."
  cd flutter && git pull && cd ..
else
  echo "📦 Clonando Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:`pwd`/flutter/bin"

# 2. Verificar e configurar Flutter
echo "🔧 Configurando Flutter..."
flutter --version
flutter config --enable-web
flutter doctor

# 3. Instalar dependências
echo "📚 Instalando dependências..."
flutter pub get

# 4. Gerar arquivo de configuração do Supabase
# (Isso é necessário porque o arquivo original está no .gitignore)
if [ ! -f "lib/core/config/supabase_config.dart" ]; then
  echo "⚠️ Criando lib/core/config/supabase_config.dart via Variáveis de Ambiente..."
  
  # Verificar se as variáveis estão definidas
  if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ ERRO: Variáveis SUPABASE_URL ou SUPABASE_ANON_KEY não estão definidas!"
    exit 1
  fi
  
  mkdir -p lib/core/config
  
  cat > lib/core/config/supabase_config.dart <<EOF
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = '$SUPABASE_URL';
  static const String supabaseAnonKey = '$SUPABASE_ANON_KEY';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
EOF
  
  echo "✅ Arquivo supabase_config.dart criado com sucesso"
else
  echo "ℹ️ Arquivo supabase_config.dart já existe, usando o existente"
fi

# 5. Compilar o projeto
echo "🔨 Compilando para Web..."
flutter build web --release --no-tree-shake-icons

# 6. Verificar se o build foi criado
if [ ! -d "build/web" ]; then
  echo "❌ ERRO: Diretório build/web não foi criado!"
  exit 1
fi

echo "✅ Build concluído com sucesso!"
echo "📦 Arquivos prontos em: build/web"
ls -lh build/web | head -10