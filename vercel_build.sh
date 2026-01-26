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

# 4. Verificar arquivos necessários
echo "🔍 Verificando arquivos necessários..."

# 4.1. Gerar arquivo de configuração do Supabase
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

# 4.2. Verificar se r2_config.dart existe (deve estar no repositório agora)
if [ ! -f "lib/core/config/r2_config.dart" ]; then
  echo "⚠️ Criando lib/core/config/r2_config.dart (fallback)..."
  mkdir -p lib/core/config
  
  cat > lib/core/config/r2_config.dart <<'R2CONFIGEOF'
// lib/core/config/r2_config.dart
import 'supabase_config.dart';

class R2Config {
  // URL base do proxy R2 (Edge Function do Supabase)
  static String get proxyBaseUrl {
    const supabaseUrl = SupabaseConfig.supabaseUrl;
    return '$supabaseUrl/functions/v1/r2-proxy';
  }
  
  /// Constrói URL completa para arquivo no R2
  static String buildFileUrl(String filePath) {
    final cleanPath = filePath.startsWith('/') 
        ? filePath.substring(1) 
        : filePath;
    return '$proxyBaseUrl/$cleanPath';
  }
  
  /// Headers de autenticação para requisições R2
  static Map<String, String> getAuthHeaders() {
    final session = SupabaseConfig.client.auth.currentSession;
    
    if (session != null) {
      return {
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': SupabaseConfig.supabaseAnonKey,
      };
    }
    
    return {
      'apikey': SupabaseConfig.supabaseAnonKey,
    };
  }
}
R2CONFIGEOF
  
  echo "✅ Arquivo r2_config.dart criado com sucesso (fallback)"
else
  echo "ℹ️ Arquivo r2_config.dart já existe"
fi

# 4.3. Verificar se audio_cache_manager.dart existe
if [ ! -f "lib/core/cache/audio_cache_manager.dart" ]; then
  echo "❌ ERRO: lib/core/cache/audio_cache_manager.dart não encontrado!"
  echo "   Este arquivo deve estar no repositório."
  exit 1
else
  echo "ℹ️ Arquivo audio_cache_manager.dart encontrado"
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