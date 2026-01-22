// lib/core/config/supabase_config.example.dart
// Copie este arquivo para supabase_config.dart e preencha com suas credenciais

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Substitua pelos valores do seu projeto Supabase
  // Encontre esses valores em: Supabase Dashboard > Project Settings > API
  static const String supabaseUrl = 'https://seu-projeto.supabase.co';
  static const String supabaseAnonKey = 'sua-chave-anon-aqui';
  
  /// Inicializa o Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
  
  /// Retorna instância do cliente Supabase
  static SupabaseClient get client => Supabase.instance.client;
}
