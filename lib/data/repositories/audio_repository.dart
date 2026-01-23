// lib/data/repositories/audio_repository.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/config/supabase_config.dart';
import '../../core/config/r2_config.dart';
import '../models/audio_version.dart';

class AudioRepository {
  final _supabase = SupabaseConfig.client;

  /// Busca todas as versões de um projeto (ordenadas por data de criação)
  Future<List<AudioVersion>> getVersionsByProject(String projectId) async {
    try {
      final response = await _supabase
          .from('audio_versions')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: true); // Mais antigo primeiro = ordem da playlist

      final versionsData = response as List<dynamic>;
      return versionsData
          .map((v) => AudioVersion.fromJson(v as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar versões: $e');
      return [];
    }
  }

  /// Busca uma versão por ID
  Future<AudioVersion?> getVersionById(String id) async {
    try {
      final response = await _supabase
          .from('audio_versions')
          .select()
          .eq('id', id)
          .single();

      return AudioVersion.fromJson(response);
    } catch (e) {
      print('Erro ao buscar versão: $e');
      return null;
    }
  }

  /// Faz upload de um arquivo de áudio para o R2 (Mobile/Desktop)
  Future<AudioVersion> uploadAudio({
    required String projectId,
    required File audioFile,
    required String name,
    String? description,
    bool isMaster = false,
    Function(double)? onProgress,
  }) async {
    final fileBytes = await audioFile.readAsBytes();
    return await uploadAudioFromBytes(
      projectId: projectId,
      fileBytes: fileBytes,
      fileName: audioFile.path.split('/').last,
      name: name,
      description: description,
      isMaster: isMaster,
      onProgress: onProgress,
    );
  }

  /// Faz upload de um arquivo de áudio para o R2 usando bytes (Web/Mobile/Desktop)
  Future<AudioVersion> uploadAudioFromBytes({
    required String projectId,
    required List<int> fileBytes,
    required String fileName,
    required String name,
    String? description,
    bool isMaster = false,
    Function(double)? onProgress,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    // 1. Gerar caminho único para o arquivo no R2
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    // Sanitizar o nome para evitar caracteres inválidos
    final sanitizedName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final r2FileName = 'projects/$projectId/$timestamp-$sanitizedName.$extension';
    final fileUrl = r2FileName; // Caminho relativo no bucket

    // 2. Tamanho do arquivo
    final fileSize = fileBytes.length;

    // 3. Upload para R2 via proxy - usar o caminho gerado, não o nome original
    final uploadUrl = R2Config.buildFileUrl(r2FileName);
    final headers = R2Config.getAuthHeaders();
    headers['Content-Type'] = _getMimeType(extension);

    final request = http.Request('PUT', Uri.parse(uploadUrl));
    request.headers.addAll(headers);
    request.bodyBytes = Uint8List.fromList(fileBytes);

    try {
      final streamedResponse = await http.Client().send(request);
      
      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('Erro no upload: ${streamedResponse.statusCode} - $errorBody');
      }
    } catch (e) {
      // Melhor tratamento de erros
      if (e.toString().contains('Failed to fetch') || 
          e.toString().contains('ClientException')) {
        throw Exception(
          'Erro de conexão ao fazer upload. Verifique:\n'
          '1. Se a Edge Function r2-proxy está deployada\n'
          '2. Se as variáveis de ambiente do R2 estão configuradas\n'
          '3. Se o bucket do R2 existe\n'
          'URL tentada: $uploadUrl',
        );
      }
      rethrow;
    }

    // 4. Extrair duração (simplificado - em produção use package:audio_metadata)
    // Por enquanto, deixamos null e pode ser atualizado depois
    final durationSeconds = await _extractDurationFromBytes(fileBytes, extension);

    // 5. Criar registro no banco
    final response = await _supabase
        .from('audio_versions')
        .insert({
          'project_id': projectId,
          'name': name,
          'description': description,
          'file_url': fileUrl,
          'file_size': fileSize,
          'duration_seconds': durationSeconds,
          'format': extension.toUpperCase(),
          'uploaded_by': user.id,
          'is_master': isMaster,
        })
        .select()
        .single();

    return AudioVersion.fromJson(response);
  }

  /// Atualiza uma versão de áudio
  Future<AudioVersion> updateVersion({
    required String id,
    String? name,
    String? description,
    bool? isMaster,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (isMaster != null) updates['is_master'] = isMaster;

    final response = await _supabase
        .from('audio_versions')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return AudioVersion.fromJson(response);
  }

  /// Deleta uma versão de áudio
  Future<void> deleteVersion(String id) async {
    // TODO: Deletar arquivo do R2 também
    await _supabase.from('audio_versions').delete().eq('id', id);
  }

  /// Obtém MIME type baseado na extensão
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'wav':
        return 'audio/wav';
      case 'flac':
        return 'audio/flac';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'audio/wav';
    }
  }

  /// Extrai duração do arquivo (simplificado)
  /// Em produção, use package:audio_metadata ou similar
  Future<int?> _extractDurationFromBytes(List<int> bytes, String extension) async {
    // Por enquanto retorna null
    // TODO: Implementar extração de duração usando package apropriado
    // Para web, você pode usar package:audio_metadata ou similar que funcione com bytes
    return null;
  }
}
