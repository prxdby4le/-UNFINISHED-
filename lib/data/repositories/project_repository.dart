// lib/data/repositories/project_repository.dart
import '../../core/config/supabase_config.dart';
import '../models/project.dart';

class ProjectRepository {
  final _supabase = SupabaseConfig.client;

  /// Busca todos os projetos do usuário atual (não arquivados)
  Future<List<Project>> getProjects({bool includeArchived = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('Erro: Usuário não autenticado');
        return [];
      }

      var query = _supabase
          .from('projects')
          .select()
          .eq('created_by', user.id); // IMPORTANTE: Filtrar por usuário!
      
      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }

      final response = await query.order('created_at', ascending: false);
      final projectsData = response as List<dynamic>;

      return projectsData
          .map((p) => Project.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar projetos: $e');
      return [];
    }
  }

  /// Busca um projeto por ID
  Future<Project?> getProjectById(String id) async {
    try {
      final response = await _supabase
          .from('projects')
          .select()
          .eq('id', id)
          .single();

      return Project.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      print('Erro ao buscar projeto: $e');
      return null;
    }
  }

  /// Cria um novo projeto
  Future<Project> createProject({
    required String name,
    String? description,
    String? coverImageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    // Garantir que o perfil do usuário existe antes de criar o projeto
    await _ensureUserProfileExists(user.id, user.email ?? '');

    final response = await _supabase
        .from('projects')
        .insert({
          'name': name,
          'description': description,
          'cover_image_url': coverImageUrl,
          'created_by': user.id,
        })
        .select()
        .single();

    return Project.fromJson(Map<String, dynamic>.from(response));
  }

  /// Garante que o perfil do usuário existe na tabela profiles
  Future<void> _ensureUserProfileExists(String userId, String email) async {
    try {
      // Verificar se o perfil já existe
      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      // Se não existe, criar
      if (existing == null) {
        await _supabase.from('profiles').insert({
          'id': userId,
          'email': email,
          'role': 'member',
        });
      }
    } catch (e) {
      // Se já existe, ignorar o erro
      if (!e.toString().contains('duplicate') && 
          !e.toString().contains('unique')) {
        print('Aviso: Erro ao verificar/criar perfil: $e');
        // Continuar mesmo com erro - pode ser que o perfil já exista
      }
    }
  }

  /// Atualiza um projeto existente
  Future<Project> updateProject({
    required String id,
    String? name,
    String? description,
    String? coverImageUrl,
    bool? isArchived,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (coverImageUrl != null) updates['cover_image_url'] = coverImageUrl;
    if (isArchived != null) updates['is_archived'] = isArchived;

    final response = await _supabase
        .from('projects')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Project.fromJson(Map<String, dynamic>.from(response));
  }

  /// Deleta um projeto
  Future<void> deleteProject(String id) async {
    await _supabase.from('projects').delete().eq('id', id);
  }

  /// Busca projetos por nome (busca) - apenas do usuário atual
  Future<List<Project>> searchProjects(String searchQuery) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('Erro: Usuário não autenticado');
        return [];
      }

      final response = await _supabase
          .from('projects')
          .select()
          .eq('created_by', user.id) // Filtrar por usuário!
          .ilike('name', '%$searchQuery%')
          .eq('is_archived', false)
          .order('created_at', ascending: false);

      final projectsData = response as List<dynamic>;
      return projectsData
          .map((p) => Project.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar projetos: $e');
      return [];
    }
  }
}
