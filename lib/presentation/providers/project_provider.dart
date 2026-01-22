// lib/presentation/providers/project_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/models/project.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectRepository _repository = ProjectRepository();
  List<Project> _projects = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carrega todos os projetos
  Future<void> loadProjects({bool includeArchived = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _projects = await _repository.getProjects(includeArchived: includeArchived);
    } catch (e) {
      _errorMessage = 'Erro ao carregar projetos: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Busca projetos por nome
  Future<void> searchProjects(String query) async {
    if (query.isEmpty) {
      await loadProjects();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _projects = await _repository.searchProjects(query);
    } catch (e) {
      _errorMessage = 'Erro ao buscar projetos: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cria um novo projeto
  Future<Project?> createProject({
    required String name,
    String? description,
    String? coverImageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final project = await _repository.createProject(
        name: name,
        description: description,
        coverImageUrl: coverImageUrl,
      );
      _projects.insert(0, project);
      notifyListeners();
      return project;
    } catch (e) {
      _errorMessage = 'Erro ao criar projeto: $e';
      print(_errorMessage);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualiza um projeto
  Future<bool> updateProject({
    required String id,
    String? name,
    String? description,
    String? coverImageUrl,
    bool? isArchived,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateProject(
        id: id,
        name: name,
        description: description,
        coverImageUrl: coverImageUrl,
        isArchived: isArchived,
      );

      final index = _projects.indexWhere((p) => p.id == id);
      if (index != -1) {
        _projects[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar projeto: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deleta um projeto
  Future<bool> deleteProject(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteProject(id);
      _projects.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao deletar projeto: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recarrega projetos
  Future<void> refresh() async {
    await loadProjects();
  }
}
