// lib/data/repositories/library_repository.dart
import '../../core/config/supabase_config.dart';

class LibraryRepository {
  final _supabase = SupabaseConfig.client;

  /// Verifica se um projeto está na biblioteca do usuário
  Future<bool> isInLibrary(String projectId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('user_library')
          .select('id')
          .eq('user_id', user.id)
          .eq('project_id', projectId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Erro ao verificar biblioteca: $e');
      return false;
    }
  }

  /// Adiciona um projeto à biblioteca
  Future<bool> addToLibrary(String projectId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('user_library').insert({
        'user_id': user.id,
        'project_id': projectId,
      });

      return true;
    } catch (e) {
      print('Erro ao adicionar à biblioteca: $e');
      return false;
    }
  }

  /// Remove um projeto da biblioteca
  Future<bool> removeFromLibrary(String projectId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('user_library')
          .delete()
          .eq('user_id', user.id)
          .eq('project_id', projectId);

      return true;
    } catch (e) {
      print('Erro ao remover da biblioteca: $e');
      return false;
    }
  }

  /// Busca todos os projetos na biblioteca do usuário
  Future<List<String>> getLibraryProjectIds() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('user_library')
          .select('project_id')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((item) => item['project_id'] as String)
          .toList();
    } catch (e) {
      print('Erro ao buscar biblioteca: $e');
      return [];
    }
  }

  /// Toggle - adiciona ou remove da biblioteca
  Future<bool> toggleLibrary(String projectId) async {
    final isInLib = await isInLibrary(projectId);
    if (isInLib) {
      return await removeFromLibrary(projectId);
    } else {
      return await addToLibrary(projectId);
    }
  }
}
