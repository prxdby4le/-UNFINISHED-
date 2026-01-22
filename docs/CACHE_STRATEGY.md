# 💾 Estratégia de Cache para Arquivos de Áudio

## Visão Geral

Arquivos WAV/FLAC podem ser muito grandes (50-200MB cada). Uma estratégia de cache inteligente é essencial para:
- ✅ Reduzir consumo de dados móveis
- ✅ Melhorar experiência (gapless playback mais suave)
- ✅ Permitir reprodução offline
- ✅ Reduzir custos de egress do R2

## Arquitetura de Cache

### 1. Estrutura de Diretórios

```
/cache/
  /audio/
    /projects/
      /{project_id}/
        /{version_id}.wav
        /{version_id}.flac
    /temp/
      /{temp_file}.wav
  /metadata/
    /versions_cache.json
```

### 2. Implementação do Cache Manager

```dart
// lib/core/cache/audio_cache_manager.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class AudioCacheManager {
  static final AudioCacheManager _instance = AudioCacheManager._internal();
  factory AudioCacheManager() => _instance;
  AudioCacheManager._internal();
  
  Directory? _cacheDir;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, DateTime> _cacheMetadata = {};
  
  // Tamanho máximo do cache (500MB)
  static const int maxCacheSizeBytes = 500 * 1024 * 1024;
  
  // Tamanho mínimo de espaço livre necessário (100MB)
  static const int minFreeSpaceBytes = 100 * 1024 * 1024;
  
  /// Inicializa o cache
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/audio_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    await _loadCacheMetadata();
  }
  
  /// Obtém arquivo do cache ou baixa se não existir
  /// 
  /// [versionId] - ID da versão de áudio
  /// [fileUrl] - URL do arquivo remoto
  /// [forceDownload] - Força download mesmo se já existe em cache
  /// 
  /// Retorna o caminho local do arquivo
  Future<String> getCachedFile({
    required String versionId,
    required String fileUrl,
    bool forceDownload = false,
  }) async {
    final cacheFile = _getCacheFilePath(versionId, fileUrl);
    
    // Verificar se já existe em cache
    if (!forceDownload && await File(cacheFile).exists()) {
      _updateCacheMetadata(versionId);
      return cacheFile;
    }
    
    // Verificar espaço disponível
    await _ensureCacheSpace();
    
    // Baixar arquivo
    await _downloadFile(fileUrl, cacheFile);
    
    _updateCacheMetadata(versionId);
    return cacheFile;
  }
  
  /// Baixa arquivo com progresso
  Future<void> _downloadFile(String url, String destination) async {
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
    
    await for (var chunk in response.stream) {
      sink.add(chunk);
      downloadedBytes += chunk.length;
      
      // Emitir progresso (opcional, via stream)
      // _progressController.add(downloadedBytes / totalBytes);
    }
    
    await sink.close();
  }
  
  /// Verifica e libera espaço se necessário
  Future<void> _ensureCacheSpace() async {
    final currentSize = await _getCacheSize();
    final freeSpace = await _getFreeSpace();
    
    // Se cache muito grande ou pouco espaço livre, limpar
    if (currentSize > maxCacheSizeBytes || freeSpace < minFreeSpaceBytes) {
      await _cleanOldCache();
    }
  }
  
  /// Limpa arquivos antigos do cache (LRU - Least Recently Used)
  Future<void> _cleanOldCache() async {
    // Ordenar por último acesso
    final sortedEntries = _cacheMetadata.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    int freedSpace = 0;
    final targetFreeSpace = maxCacheSizeBytes ~/ 2; // Liberar 50% do cache
    
    for (var entry in sortedEntries) {
      if (freedSpace >= targetFreeSpace) break;
      
      final file = File(_getCacheFilePath(entry.key, ''));
      if (await file.exists()) {
        final size = await file.length();
        await file.delete();
        _cacheMetadata.remove(entry.key);
        freedSpace += size;
      }
    }
  }
  
  /// Obtém tamanho total do cache
  Future<int> _getCacheSize() async {
    if (_cacheDir == null) return 0;
    
    int totalSize = 0;
    await for (var entity in _cacheDir!.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }
  
  /// Obtém espaço livre disponível
  Future<int> _getFreeSpace() async {
    final appDir = await getApplicationDocumentsDirectory();
    final stat = await FileStat.stat(appDir.path);
    // Nota: FileStat não tem freeSpace diretamente
    // Em produção, use package:disk_space ou similar
    return 0; // Placeholder
  }
  
  /// Caminho do arquivo em cache
  String _getCacheFilePath(String versionId, String fileUrl) {
    // Usar hash do URL para evitar caracteres inválidos
    final urlHash = md5.convert(utf8.encode(fileUrl)).toString();
    final extension = fileUrl.split('.').last;
    return '${_cacheDir!.path}/$versionId-$urlHash.$extension';
  }
  
  /// Atualiza metadata de acesso
  void _updateCacheMetadata(String versionId) {
    _cacheMetadata[versionId] = DateTime.now();
    _saveCacheMetadata();
  }
  
  /// Carrega metadata do cache
  Future<void> _loadCacheMetadata() async {
    final metadataFile = File('${_cacheDir!.path}/metadata.json');
    if (await metadataFile.exists()) {
      final content = await metadataFile.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      _cacheMetadata.clear();
      data.forEach((key, value) {
        _cacheMetadata[key] = DateTime.parse(value as String);
      });
    }
  }
  
  /// Salva metadata do cache
  Future<void> _saveCacheMetadata() async {
    final metadataFile = File('${_cacheDir!.path}/metadata.json');
    final data = _cacheMetadata.map((key, value) => 
      MapEntry(key, value.toIso8601String())
    );
    await metadataFile.writeAsString(json.encode(data));
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
    if (_cacheDir != null && await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create(recursive: true);
      _cacheMetadata.clear();
    }
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
```

### 3. Integração com AudioPlayer

```dart
// Modificar AudioPlayerProvider para usar cache
class AudioPlayerProvider {
  final AudioCacheManager _cacheManager = AudioCacheManager();
  
  Future<bool> loadProjectVersions({
    required String projectId,
    List<String>? versionIds,
  }) async {
    // ... buscar versões ...
    
    // Para cada versão, obter arquivo do cache
    final List<AudioSource> audioSources = [];
    for (var version in versions) {
      final versionId = version['id'] as String;
      final fileUrl = _buildR2ProxyUrl(version['file_url']);
      
      // Obter arquivo do cache (ou baixar)
      final cachedPath = await _cacheManager.getCachedFile(
        versionId: versionId,
        fileUrl: fileUrl,
      );
      
      // Usar arquivo local para melhor performance
      audioSources.add(AudioSource.file(cachedPath));
    }
    
    final playlist = ConcatenatingAudioSource(children: audioSources);
    await _audioPlayer.setAudioSource(playlist);
    
    return true;
  }
}
```

## Estratégias de Cache

### 1. Cache por Demanda (Lazy Loading)

- **Quando**: Arquivo é solicitado pela primeira vez
- **Vantagem**: Não consome dados desnecessários
- **Desvantagem**: Primeira reprodução pode ter delay

### 2. Pré-cache Inteligente

```dart
// Pré-cache próximo arquivo enquanto o atual toca
Future<void> preloadNextTrack() async {
  final currentIndex = await _audioPlayer.currentIndex;
  if (currentIndex != null) {
    final nextVersion = versions[currentIndex + 1];
    if (nextVersion != null) {
      // Baixar em background
      _cacheManager.getCachedFile(
        versionId: nextVersion['id'],
        fileUrl: _buildR2ProxyUrl(nextVersion['file_url']),
      );
    }
  }
}
```

### 3. Cache Seletivo

Permitir usuário escolher quais projetos/versões manter em cache:

```dart
// Marcar versão para manter em cache permanentemente
Future<void> pinVersion(String versionId) async {
  // Adicionar à lista de "pinned"
  // Nunca deletar versões pinned no cleanup
}
```

### 4. Cache por Wi-Fi

```dart
// Só fazer cache quando conectado via Wi-Fi
Future<bool> shouldCache() async {
  // Usar package:connectivity_plus
  final connectivity = Connectivity();
  final result = await connectivity.checkConnectivity();
  return result == ConnectivityResult.wifi;
}
```

## Configurações Recomendadas

### Android

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
    android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
    android:maxSdkVersion="32" />
```

### iOS

```xml
<!-- ios/Runner/Info.plist -->
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

## Monitoramento

Adicione métricas para monitorar eficiência do cache:

```dart
class CacheMetrics {
  int cacheHits = 0;
  int cacheMisses = 0;
  int totalDownloads = 0;
  int totalBytesDownloaded = 0;
  
  double get hitRate => cacheHits / (cacheHits + cacheMisses);
}
```

## Considerações de Segurança

1. **Validação de Arquivos**: Verificar hash/integridade dos arquivos baixados
2. **Criptografia**: Considerar criptografar arquivos em cache (opcional)
3. **Limpeza Automática**: Limpar cache ao fazer logout
