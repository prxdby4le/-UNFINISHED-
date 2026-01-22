// lib/data/repositories/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../../core/config/supabase_config.dart';

class AuthRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Retorna o usuário atual autenticado
  User? get currentUser => _supabase.auth.currentUser;

  /// Retorna o perfil do usuário atual
  Future<UserProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      print('Erro ao buscar perfil: $e');
      return null;
    }
  }

  /// Faz login com email e senha
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Melhor tratamento de erros
      if (e.toString().contains('404')) {
        throw Exception(
          'Erro de conexão: Verifique se a URL do Supabase está correta.\n'
          'Verifique o arquivo lib/core/config/supabase_config.dart',
        );
      }
      rethrow;
    }
  }

  /// Cria nova conta com email e senha
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          if (fullName != null) 'full_name': fullName,
        },
        emailRedirectTo: null, // Não redirecionar email
      );

      // Criar perfil na tabela profiles usando o ID do usuário
      // IMPORTANTE: Usar o ID do usuário retornado, não fazer query separada
      if (response.user != null) {
        final userId = response.user!.id;
        
        try {
          // Usar RPC ou inserção direta com o ID do usuário autenticado
          // A política RLS deve permitir que o próprio usuário crie seu perfil
          await _supabase.from('profiles').insert({
            'id': userId,
            'email': email,
            'full_name': fullName,
            'role': 'member',
          });
        } catch (e) {
          print('Erro ao criar perfil: $e');
          // Se falhar, tentar novamente após um pequeno delay
          // (às vezes o usuário ainda não está totalmente criado)
          await Future.delayed(const Duration(milliseconds: 500));
          try {
            await _supabase.from('profiles').insert({
              'id': userId,
              'email': email,
              'full_name': fullName,
              'role': 'member',
            });
          } catch (e2) {
            print('Erro ao criar perfil (tentativa 2): $e2');
            // Não falha o signup se o perfil já existir ou der erro
          }
        }
      }

      return response;
    } catch (e) {
      // Melhor tratamento de erros
      if (e.toString().contains('404')) {
        throw Exception(
          'Erro de conexão: Verifique se a URL do Supabase está correta.\n'
          'Verifique o arquivo lib/core/config/supabase_config.dart',
        );
      }
      if (e.toString().contains('email_not_confirmed')) {
        throw Exception(
          'Email não confirmado. Verifique sua caixa de entrada e confirme o email antes de fazer login.',
        );
      }
      rethrow;
    }
  }

  /// Faz logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => currentUser != null;

  /// Stream de mudanças no estado de autenticação
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Envia email de recuperação de senha
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: null, // Você pode configurar uma URL de redirect
    );
  }

  /// Atualiza o perfil do usuário
  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _supabase.from('profiles').update({
      if (fullName != null) 'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', user.id);
  }
}
