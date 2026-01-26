// lib/core/cache/audio_cache_manager.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class AudioCacheManager {
  static final AudioCacheManager _instance = AudioCacheManager._internal();
  factory AudioCacheManager() => _instance;
  AudioCacheManager._internal();
  
  Directory? _cacheDir;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, DateTime> _cacheMetadata = {};
  final Map<String, int> _fileSizes = {}; // Armazena tamanho dos arquivos
  final Connectivity _connectivity = Connectivity();
  
  // Tamanho máximo do cache (500MB)
  static const int maxCacheSizeBytes = 500 * 1024 * 1024;
  
  // Tamanho mínimo de espaço livre necessário (100MB)
  static const int minFreeSpaceBytes = 100 * 1024 * 1024;
  
  // Configuração: cache apenas em Wi-Fi
  bool _wifiOnlyCache = false;
  
  bool _initialized = false;
  bool _isWeb = false;
  
  // Getters e setters
  bool get wifiOnlyCache => _wifiOnlyCache;
  set wifiOnlyCache(bool value) => _wifiOnlyCache = value;
  
  /// Inicializa o cache
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Verificar se está rodando na web
    _isWeb = kIsWeb;
    
    if (_isWeb) {
      // Na web, não há cache de arquivos locais
      // Usar apenas URLs remotas
      _initialized = true;
      return;
    }
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/audio_cache');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      await _loadCacheMetadata();
      _initialized = true;
    } catch (e) {
      print('Erro ao inicializar cache: $e');
      _isWeb = true; // Fallback para modo web
      _initialized = true;
    }
  }
  
  /// Obtém arquivo do cache ou baixa se não existir
  /// 
  /// [versionId] - ID da versão de áudio
  /// [fileUrl] - URL do arquivo remoto
  /// [forceDownload] - Força download mesmo se já existe em cache
  /// 
  /// Retorna o caminho local do arquivo (ou URL na web)
  Future<String> getCachedFile({
    required String versionId,
    required String fileUrl,
    bool forceDownload = false,
    Function(double)? onProgress,
  }) async {
    if (!_initialized) await initialize();
    
    // Na web, retornar URL diretamente (sem cache local)
    if (_isWeb) {
      return fileUrl;
    }
    
    final cacheFile = _getCacheFilePath(versionId, fileUrl);
    
    // Verificar se já existe em cache
    if (!forceDownload && await File(cacheFile).exists()) {
      _updateCacheMetadata(versionId);
      return cacheFile;
    }
    
    // Verificar se deve fazer cache (Wi-Fi only)
    if (_wifiOnlyCache) {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.wifi) {
        // Não está em Wi-Fi, retornar URL direto
        debugPrint('[Cache] Wi-Fi only mode: retornando URL direto (não está em Wi-Fi)');
        return fileUrl;
      }
    }
    
    // Verificar espaço disponível
    await _ensureCacheSpace();
    
    // Baixar arquivo
    await _downloadFile(fileUrl, cacheFile, onProgress: onProgress);
    
    // Salvar tamanho do arquivo
    final file = File(cacheFile);
    if (await file.exists()) {
      _fileSizes[versionId] = await file.length();
    }
    
    _updateCacheMetadata(versionId);
    return cacheFile;
  }
  
  /// Baixa arquivo com progresso
  Future<void> _downloadFile(
    String url,
    String destination, {
    Function(double)? onProgress,
  }) async {
    final headers = _getAuthHeaders();
    final request = http.Request('GET', Uri.parse(url));
    request.headers.addAll(headers);
    
    final response = await http.Client().send(request);
    
    if (response.statusCode != 200) {
      throw Exception('Falha ao baixar arquivo: ${response.statusCode}');
    }
    
    final file = File(destination);
    final sink = file.openWrite();
    
    int totalBytes = response.contentLength ?? 0;
    int downloadedBytes = 0;
    
    try {
      await for (var chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        
        // Emitir progresso
        if (onProgress != null && totalBytes > 0) {
          onProgress(downloadedBytes / totalBytes);
        }
      }
    } finally {
      await sink.close();
    }
  }
  
  /// Verifica e libera espaço se necessário
  Future<void> _ensureCacheSpace({int? requiredSpace}) async {
    final currentSize = await _getCacheSize();
    final freeSpace = await _getFreeSpace();
    
    // Se cache muito grande ou pouco espaço livre, limpar
    final needsCleanup = currentSize > maxCacheSizeBytes || 
                        freeSpace < minFreeSpaceBytes ||
                        (requiredSpace != null && currentSize + requiredSpace > maxCacheSizeBytes);
    
    if (needsCleanup) {
      await _cleanOldCache();
      
      // Verificar novamente após limpeza
      final newSize = await _getCacheSize();
      final newFreeSpace = await _getFreeSpace();
      
      if (requiredSpace != null) {
        if (newSize + requiredSpace > maxCacheSizeBytes || 
            newFreeSpace < minFreeSpaceBytes + requiredSpace) {
          throw Exception('Espaço insuficiente no cache mesmo após limpeza');
        }
      }
    }
  }
  
  /// Limpa arquivos antigos do cache (LRU - Least Recently Used)
  Future<void> _cleanOldCache() async {
    if (_isWeb || _cacheDir == null) return;
    
    // Criar lista de arquivos com metadata
    final List<Map<String, dynamic>> fileList = [];
    
    try {
      await for (var entity in _cacheDir!.list()) {
        if (entity is File && !entity.path.endsWith('.json')) {
          // Extrair versionId do nome do arquivo
          final fileName = entity.path.split('/').last;
          final versionId = fileName.split('-').first;
          
          if (_cacheMetadata.containsKey(versionId)) {
            final size = await entity.length();
            fileList.add({
              'path': entity.path,
              'versionId': versionId,
              'lastAccess': _cacheMetadata[versionId]!,
              'size': size,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[Cache] Erro ao listar arquivos para limpeza: $e');
      return;
    }
    
    // Ordenar por último acesso (mais antigo primeiro)
    fileList.sort((a, b) => (a['lastAccess'] as DateTime).compareTo(b['lastAccess'] as DateTime));
    
    int freedSpace = 0;
    final targetFreeSpace = maxCacheSizeBytes ~/ 2; // Liberar 50% do cache
    
    for (var fileInfo in fileList) {
      if (freedSpace >= targetFreeSpace) break;
      
      try {
        final file = File(fileInfo['path'] as String);
        if (await file.exists()) {
          await file.delete();
          final versionId = fileInfo['versionId'] as String;
          _cacheMetadata.remove(versionId);
          _fileSizes.remove(versionId);
          freedSpace += fileInfo['size'] as int;
        }
      } catch (e) {
        debugPrint('[Cache] Erro ao deletar arquivo ${fileInfo['path']}: $e');
      }
    }
    
    await _saveCacheMetadata();
    debugPrint('[Cache] Limpeza concluída: ${(freedSpace / (1024 * 1024)).toStringAsFixed(2)} MB liberados');
  }
  
  /// Obtém tamanho total do cache
  Future<int> _getCacheSize() async {
    if (_isWeb || _cacheDir == null) return 0;
    
    // Se temos os tamanhos em cache, usar eles (mais rápido)
    if (_fileSizes.isNotEmpty) {
      int totalSize = 0;
      for (var size in _fileSizes.values) {
        totalSize += size;
      }
      return totalSize;
    }
    
    // Caso contrário, calcular do disco
    int totalSize = 0;
    try {
      await for (var entity in _cacheDir!.list(recursive: true)) {
        if (entity is File && !entity.path.endsWith('.json')) {
          final size = await entity.length();
          totalSize += size;
          
          // Atualizar cache de tamanhos
          final fileName = entity.path.split('/').last;
          final versionId = fileName.split('-').first;
          if (versionId.isNotEmpty) {
            _fileSizes[versionId] = size;
          }
        }
      }
    } catch (e) {
      debugPrint('[Cache] Erro ao calcular tamanho do cache: $e');
    }
    return totalSize;
  }
  
  /// Obtém tamanho do cache (método público)
  Future<int> getCacheSize() async {
    return await _getCacheSize();
  }
  
  /// Obtém espaço livre disponível
  Future<int> _getFreeSpace() async {
    if (_isWeb || _cacheDir == null) return 0;
    
    try {
      // Verificar se o diretório existe e podemos escrever
      // Em produção, considere usar package:disk_space para verificação real
      // Por enquanto, retornamos um valor conservador
      if (await _cacheDir!.exists()) {
        // Diretório existe, assumir espaço suficiente
        return minFreeSpaceBytes * 2; // Retorna 200MB como espaço mínimo assumido
      }
      return minFreeSpaceBytes;
    } catch (e) {
      debugPrint('[Cache] Erro ao verificar espaço livre: $e');
      // Em caso de erro, retornar valor conservador
      return minFreeSpaceBytes;
    }
  }
  
  /// Verifica se há espaço suficiente para um arquivo de tamanho específico
  Future<bool> hasEnoughSpace(int fileSizeBytes) async {
    final currentSize = await _getCacheSize();
    final freeSpace = await _getFreeSpace();
    
    // Verificar se o cache atual + novo arquivo não excede o limite
    if (currentSize + fileSizeBytes > maxCacheSizeBytes) {
      return false;
    }
    
    // Verificar se há espaço livre suficiente no dispositivo
    if (freeSpace < minFreeSpaceBytes + fileSizeBytes) {
      return false;
    }
    
    return true;
  }
  
  /// Caminho do arquivo em cache
  String _getCacheFilePath(String versionId, String fileUrl) {
    // Usar hash do URL para evitar caracteres inválidos
    final urlHash = md5.convert(utf8.encode(fileUrl)).toString();
    final extension = fileUrl.split('.').last.split('?').first; // Remove query params
    return '${_cacheDir!.path}/$versionId-$urlHash.$extension';
  }
  
  /// Atualiza metadata de acesso
  void _updateCacheMetadata(String versionId) {
    _cacheMetadata[versionId] = DateTime.now();
    _saveCacheMetadata();
  }
  
  /// Carrega metadata do cache
  Future<void> _loadCacheMetadata() async {
    if (_isWeb || _cacheDir == null) return;
    
    final metadataFile = File('${_cacheDir!.path}/metadata.json');
    if (await metadataFile.exists()) {
      try {
        final content = await metadataFile.readAsString();
        final data = json.decode(content) as Map<String, dynamic>;
        _cacheMetadata.clear();
        data.forEach((key, value) {
          _cacheMetadata[key] = DateTime.parse(value as String);
        });
      } catch (e) {
        debugPrint('[Cache] Erro ao carregar metadata do cache: $e');
      }
    }
    
    // Carregar tamanhos dos arquivos também
    await _loadFileSizes();
  }
  
  /// Carrega tamanhos dos arquivos do disco
  Future<void> _loadFileSizes() async {
    if (_isWeb || _cacheDir == null) return;
    
    try {
      await for (var entity in _cacheDir!.list()) {
        if (entity is File && !entity.path.endsWith('.json')) {
          final fileName = entity.path.split('/').last;
          final versionId = fileName.split('-').first;
          if (versionId.isNotEmpty) {
            _fileSizes[versionId] = await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint('[Cache] Erro ao carregar tamanhos dos arquivos: $e');
    }
  }
  
  /// Salva metadata do cache
  Future<void> _saveCacheMetadata() async {
    if (_isWeb || _cacheDir == null) return;
    
    final metadataFile = File('${_cacheDir!.path}/metadata.json');
    try {
      final data = _cacheMetadata.map((key, value) => 
        MapEntry(key, value.toIso8601String())
      );
      await metadataFile.writeAsString(json.encode(data));
    } catch (e) {
      print('Erro ao salvar metadata do cache: $e');
    }
  }
  
  /// Headers de autenticação
  Map<String, String> _getAuthHeaders() {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      return {
        'Authorization': 'Bearer ${session.accessToken}',
      };
    }
    return {};
  }
  
  /// Limpa todo o cache
  Future<void> clearCache() async {
    if (_isWeb) return;
    
    if (_cacheDir != null && await _cacheDir!.exists()) {
      try {
        await for (var entity in _cacheDir!.list(recursive: true)) {
          if (entity is File) {
            await entity.delete();
          }
        }
        _cacheMetadata.clear();
        _fileSizes.clear();
        await _saveCacheMetadata();
        debugPrint('[Cache] Cache completamente limpo');
      } catch (e) {
        debugPrint('[Cache] Erro ao limpar cache: $e');
        rethrow;
      }
    }
  }
  
  /// Remove arquivo específico do cache
  Future<void> removeCachedFile(String versionId) async {
    if (_isWeb || _cacheDir == null) return;
    
    try {
      await for (var entity in _cacheDir!.list()) {
        if (entity is File && entity.path.contains(versionId)) {
          await entity.delete();
          _cacheMetadata.remove(versionId);
          _fileSizes.remove(versionId);
          await _saveCacheMetadata();
          break;
        }
      }
    } catch (e) {
      debugPrint('[Cache] Erro ao remover arquivo do cache: $e');
    }
  }
  
  /// Pré-cache de um arquivo (download em background)
  Future<void> preCacheFile({
    required String versionId,
    required String fileUrl,
    Function(double)? onProgress,
  }) async {
    if (!_initialized) await initialize();
    
    if (_isWeb) return; // Não há cache na web
    
    // Verificar se já está em cache
    if (await isCached(versionId, fileUrl)) {
      return;
    }
    
    // Verificar Wi-Fi se necessário
    if (_wifiOnlyCache) {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.wifi) {
        debugPrint('[Cache] Pré-cache cancelado: não está em Wi-Fi');
        return;
      }
    }
    
    try {
      final cacheFile = _getCacheFilePath(versionId, fileUrl);
      
      // Verificar espaço antes de baixar
      // Estimar tamanho (vamos tentar obter do header primeiro)
      try {
        final headResponse = await http.head(Uri.parse(fileUrl), headers: _getAuthHeaders());
        final contentLength = headResponse.headers['content-length'];
        if (contentLength != null) {
          final fileSize = int.parse(contentLength);
          if (!await hasEnoughSpace(fileSize)) {
            await _ensureCacheSpace(requiredSpace: fileSize);
          }
        }
      } catch (e) {
        debugPrint('[Cache] Não foi possível verificar tamanho do arquivo: $e');
      }
      
      // Baixar em background
      await _downloadFile(fileUrl, cacheFile, onProgress: onProgress);
      
      final file = File(cacheFile);
      if (await file.exists()) {
        _fileSizes[versionId] = await file.length();
      }
      
      _updateCacheMetadata(versionId);
      debugPrint('[Cache] Pré-cache concluído para: $versionId');
    } catch (e) {
      debugPrint('[Cache] Erro no pré-cache: $e');
      // Não relançar erro - pré-cache é opcional
    }
  }
  
  /// Verifica se arquivo está em cache
  Future<bool> isCached(String versionId, String fileUrl) async {
    if (!_initialized) await initialize();
    
    // Na web, sempre retornar false (não há cache local)
    if (_isWeb) {
      return false;
    }
    
    final cacheFile = _getCacheFilePath(versionId, fileUrl);
    return await File(cacheFile).exists();
  }
  
  /// Obtém estatísticas do cache
  Future<CacheStats> getStats() async {
    final size = await _getCacheSize();
    final fileCount = _cacheMetadata.length;
    return CacheStats(
      totalSizeBytes: size,
      fileCount: fileCount,
    );
  }
}

class CacheStats {
  final int totalSizeBytes;
  final int fileCount;
  
  CacheStats({
    required this.totalSizeBytes,
    required this.fileCount,
  });
  
  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
