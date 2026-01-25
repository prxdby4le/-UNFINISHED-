#!/bin/bash

echo "🚀 Iniciando build para Vercel..."

# 1. Instalar Flutter
if [ -d "flutter" ]; then
  cd flutter && git pull && cd ..
else
  git clone https://github.com/flutter/flutter.git -b stable
fi

export PATH="$PATH:`pwd`/flutter/bin"

# 2. Configurar Flutter
flutter config --enable-web
flutter pub get

# 3. Gerar arquivo de configuração do Supabase
# (Isso é necessário porque o arquivo original está no .gitignore)
if [ ! -f "lib/core/config/supabase_config.dart" ]; then
  echo "⚠️ Criando lib/core/config/supabase_config.dart via Variáveis de Ambiente..."
  
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
fi

# 4. Compilar o projeto
echo "🔨 Compilando para Web..."
flutter build web --release --no-tree-shake-icons