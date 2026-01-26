// lib/data/repositories/feedback_repository.dart
import '../../core/config/supabase_config.dart';
import '../models/feedback.dart';

class FeedbackRepository {
  final _supabase = SupabaseConfig.client;

  /// Busca todos os comentários de uma versão de áudio
  /// Inclui informações do autor via join com profiles
  Future<List<Feedback>> getFeedbackByVersion(String versionId) async {
    try {
      final response = await _supabase
          .from('feedback')
          .select('''
            *,
            profiles:author_id(
              full_name,
              email,
              avatar_url
            )
          ''')
          .eq('audio_version_id', versionId)
          .order('created_at', ascending: false);

      final feedbackData = response as List<dynamic>;
      return feedbackData
          .map((f) => Feedback.fromJson(f as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar feedback: $e');
      return [];
    }
  }

  /// Cria novo comentário
  Future<Feedback> createFeedback({
    required String audioVersionId,
    required String content,
    int? timestampSeconds,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    // Validar conteúdo
    if (content.trim().isEmpty) {
      throw Exception('Comentário não pode estar vazio');
    }
    if (content.trim().length < 3) {
      throw Exception('Comentário deve ter pelo menos 3 caracteres');
    }

    try {
      final response = await _supabase
          .from('feedback')
          .insert({
            'audio_version_id': audioVersionId,
            'author_id': user.id,
            'content': content.trim(),
            'timestamp_seconds': timestampSeconds,
          })
          .select('''
            *,
            profiles:author_id(
              full_name,
              email,
              avatar_url
            )
          ''')
          .single();

      return Feedback.fromJson(response);
    } catch (e) {
      print('Erro ao criar feedback: $e');
      rethrow;
    }
  }

  /// Atualiza comentário próprio
  Future<Feedback> updateFeedback({
    required String id,
    required String content,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    // Validar conteúdo
    if (content.trim().isEmpty) {
      throw Exception('Comentário não pode estar vazio');
    }
    if (content.trim().length < 3) {
      throw Exception('Comentário deve ter pelo menos 3 caracteres');
    }

    try {
      final response = await _supabase
          .from('feedback')
          .update({'content': content.trim()})
          .eq('id', id)
          .eq('author_id', user.id) // Garantir que é o autor
          .select('''
            *,
            profiles:author_id(
              full_name,
              email,
              avatar_url
            )
          ''')
          .maybeSingle();

      if (response == null) {
        throw Exception('Comentário não encontrado ou você não tem permissão para editá-lo');
      }

      return Feedback.fromJson(response);
    } catch (e) {
      print('Erro ao atualizar feedback: $e');
      rethrow;
    }
  }

  /// Deleta comentário próprio
  Future<void> deleteFeedback(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final response = await _supabase
          .from('feedback')
          .delete()
          .eq('id', id)
          .eq('author_id', user.id); // Garantir que é o autor

      // Verificar se deletou algo
      if (response.isEmpty) {
        throw Exception('Comentário não encontrado ou você não tem permissão para deletá-lo');
      }
    } catch (e) {
      print('Erro ao deletar feedback: $e');
      rethrow;
    }
  }

  /// Conta comentários de uma versão
  Future<int> getFeedbackCount(String versionId) async {
    try {
      final response = await _supabase
          .from('feedback')
          .select('id')
          .eq('audio_version_id', versionId);

      return (response as List).length;
    } catch (e) {
      print('Erro ao contar feedback: $e');
      return 0;
    }
  }

  /// Busca comentários com paginação
  Future<List<Feedback>> getFeedbackByVersionPaginated({
    required String versionId,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await _supabase
          .from('feedback')
          .select('''
            *,
            profiles:author_id(
              full_name,
              email,
              avatar_url
            )
          ''')
          .eq('audio_version_id', versionId)
          .order('created_at', ascending: false)
          .range(from, to);

      final feedbackData = response as List<dynamic>;
      return feedbackData
          .map((f) => Feedback.fromJson(f as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar feedback paginado: $e');
      return [];
    }
  }
}
