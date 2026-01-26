
// lib/core/config/r2_config.dart
import 'supabase_config.dart';

class R2Config {
  // URL base do proxy R2 (Edge Function do Supabase)
  static String get proxyBaseUrl {
    const supabaseUrl = SupabaseConfig.supabaseUrl;
    return '$supabaseUrl/functions/v1/r2-proxy';
  }
  
  /// Constrói URL completa para arquivo no R2
  /// 
  /// [filePath] - Caminho do arquivo no bucket (ex: "projects/project-1/mix.wav")
  static String buildFileUrl(String filePath) {
    // Remove barras iniciais se houver
    final cleanPath = filePath.startsWith('/') 
        ? filePath.substring(1) 
        : filePath;
    return '$proxyBaseUrl/$cleanPath';
  }
  
  /// Headers de autenticação para requisições R2
  static Map<String, String> getAuthHeaders() {
    final session = SupabaseConfig.client.auth.currentSession;
    
    // Debug: verificar sessão
    print('[R2Config] Session exists: ${session != null}');
    if (session != null) {
      print('[R2Config] Token (first 20 chars): ${session.accessToken.substring(0, 20)}...');
      print('[R2Config] Token expires at: ${session.expiresAt}');
    }
    
    if (session != null) {
      return {
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': SupabaseConfig.supabaseAnonKey,
      };
    }
    
    print('[R2Config] WARNING: No session found, sending only apikey');
    return {
      'apikey': SupabaseConfig.supabaseAnonKey,
    };
  }
}
