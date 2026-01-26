// lib/data/repositories/image_repository.dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/supabase_config.dart';
import '../../core/config/r2_config.dart';

class ImageRepository {
  final _supabase = SupabaseConfig.client;

  /// Faz upload de uma imagem para o R2
  Future<String> uploadImage({
    required List<int> imageBytes,
    required String fileName,
    required String folder, // ex: 'covers', 'avatars'
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    // Gerar caminho único
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last.toLowerCase();
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final r2FileName = '$folder/$timestamp-$sanitizedName';
    final fileUrl = r2FileName;

    // Upload para R2 via proxy
    final uploadUrl = R2Config.buildFileUrl(r2FileName);
    final headers = R2Config.getAuthHeaders();
    
    // Determinar content type
    String contentType = 'image/jpeg';
    if (extension == 'png') contentType = 'image/png';
    if (extension == 'gif') contentType = 'image/gif';
    if (extension == 'webp') contentType = 'image/webp';
    
    headers['Content-Type'] = contentType;

    final request = http.Request('PUT', Uri.parse(uploadUrl));
    request.headers.addAll(headers);
    request.bodyBytes = Uint8List.fromList(imageBytes);

    try {
      final streamedResponse = await http.Client().send(request);
      
      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('Erro no upload: ${streamedResponse.statusCode} - $errorBody');
      }
      
      return fileUrl;
    } catch (e) {
      if (e.toString().contains('Failed to fetch') || 
          e.toString().contains('ClientException')) {
        throw Exception(
          'Erro de conexão ao fazer upload. Verifique:\n'
          '1. Se a Edge Function r2-proxy está deployada\n'
          '2. Se as variáveis de ambiente do R2 estão configuradas\n'
          'URL tentada: $uploadUrl',
        );
      }
      rethrow;
    }
  }

  /// Obtém URL do proxy para uma imagem (evita CORS)
  /// Retorna a URL da Edge Function que serve como proxy
  String getProxyImageUrl(String filePath) {
    if (filePath.startsWith('http')) return filePath;
    
    // Retornar URL do proxy diretamente (a Edge Function vai servir a imagem)
    return '${R2Config.proxyBaseUrl}/$filePath';
  }

  /// Obtém URL assinada para uma imagem (método antigo - mantido para compatibilidade)
  /// NOTA: Para evitar CORS, use getProxyImageUrl() em vez deste método
  @Deprecated('Use getProxyImageUrl() para evitar problemas de CORS')
  Future<String> getSignedImageUrl(String filePath) async {
    if (filePath.startsWith('http')) return filePath;
    
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final functionUrl = '${R2Config.proxyBaseUrl}/$filePath';
    final headers = R2Config.getAuthHeaders();
    headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';

    final response = await http.get(Uri.parse(functionUrl), headers: headers);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['url'] as String;
    } else {
      throw Exception('Erro ao obter URL assinada: ${response.statusCode}');
    }
  }
}
