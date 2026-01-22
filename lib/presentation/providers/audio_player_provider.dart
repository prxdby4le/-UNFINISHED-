// lib/presentation/providers/audio_player_provider.dart
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/cache/audio_cache_manager.dart';
import '../../core/config/r2_config.dart';
import '../../data/models/audio_version.dart';

class AudioPlayerProvider {
  late AudioPlayer _audioPlayer;
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioCacheManager _cacheManager = AudioCacheManager();
  
  List<AudioVersion>? _currentVersions;
  
  AudioPlayerProvider() {
    _audioPlayer = AudioPlayer();
  }
  
  /// Configura uma playlist com gapless playback
  /// 
  /// [audioUrls] - Lista de URLs dos arquivos de áudio
  /// [titles] - Lista opcional de títulos para cada track
  /// Retorna true se a configuração foi bem-sucedida
  Future<bool> loadPlaylistGapless({
    required List<String> audioUrls,
    List<String>? titles,
    int initialIndex = 0,
  }) async {
    try {
      // Converter URLs para AudioSource com suporte a gapless
      final List<AudioSource> audioSources = [];
      
      for (int i = 0; i < audioUrls.length; i++) {
        final url = audioUrls[i];
        final title = titles != null && i < titles.length 
            ? titles[i] 
            : _extractTitleFromUrl(url);
        
        audioSources.add(
          AudioSource.uri(
            Uri.parse(url),
            headers: _getAuthHeaders(),
            tag: MediaItem(
              id: url,
              title: title,
              artUri: Uri.parse('https://example.com/cover.jpg'),
            ),
          ),
        );
      }
      
      // Criar playlist concatenada (gapless)
      final playlist = ConcatenatingAudioSource(
        children: audioSources,
        useLazyPreparation: true, // Preparar próximo arquivo em background
      );
      
      // Carregar playlist
      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: initialIndex,
        preload: true, // Pré-carregar para gapless suave
      );
      
      return true;
    } catch (e) {
      print('Erro ao carregar playlist: $e');
      return false;
    }
  }
  
  /// Carrega versões de áudio de um projeto em sequência gapless
  /// Usa cache local quando disponível para melhor performance
  Future<bool> loadProjectVersions({
    required String projectId,
    List<String>? versionIds, // Se null, carrega todas
  }) async {
    try {
      // Buscar versões do projeto
      var query = _supabase
          .from('audio_versions')
          .select('*')
          .eq('project_id', projectId)
          .order('created_at', ascending: true);
      
      if (versionIds != null && versionIds.isNotEmpty) {
        query = query.in_('id', versionIds);
      }
      
      final response = await query;
      final versionsData = response as List<dynamic>;
      
      if (versionsData.isEmpty) {
        return false;
      }
      
      // Converter para modelos
      _currentVersions = versionsData
          .map((v) => AudioVersion.fromJson(v as Map<String, dynamic>))
          .toList();
      
      // Construir lista de AudioSource usando cache
      final List<AudioSource> audioSources = [];
      final List<String> titles = [];
      
      for (var version in _currentVersions!) {
        final fileUrl = _buildR2ProxyUrl(version.fileUrl);
        
        // Tentar obter do cache primeiro
        try {
          final cachedPath = await _cacheManager.getCachedFile(
            versionId: version.id,
            fileUrl: fileUrl,
          );
          
          // Usar arquivo local para melhor performance e gapless perfeito
          audioSources.add(
            AudioSource.file(
              cachedPath,
              tag: MediaItem(
                id: version.id,
                title: version.name,
                artist: 'Trashtalk Records',
              ),
            ),
          );
        } catch (e) {
          // Se falhar o cache, usar URL remota
          print('Cache falhou, usando URL remota: $e');
          audioSources.add(
            AudioSource.uri(
              Uri.parse(fileUrl),
              headers: _getAuthHeaders(),
              tag: MediaItem(
                id: version.id,
                title: version.name,
                artist: 'Trashtalk Records',
              ),
            ),
          );
        }
        
        titles.add(version.name);
      }
      
      // Criar playlist concatenada (gapless)
      final playlist = ConcatenatingAudioSource(
        children: audioSources,
        useLazyPreparation: true,
      );
      
      // Carregar playlist
      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: 0,
        preload: true,
      );
      
      return true;
    } catch (e) {
      print('Erro ao carregar versões do projeto: $e');
      return false;
    }
  }
  
  /// Pré-carrega próximo track em background
  Future<void> preloadNextTrack() async {
    final currentIndex = await _audioPlayer.currentIndex;
    if (currentIndex != null && _currentVersions != null) {
      final nextIndex = currentIndex + 1;
      if (nextIndex < _currentVersions!.length) {
        final nextVersion = _currentVersions![nextIndex];
        final fileUrl = _buildR2ProxyUrl(nextVersion.fileUrl);
        
        // Baixar em background sem bloquear
        _cacheManager.getCachedFile(
          versionId: nextVersion.id,
          fileUrl: fileUrl,
        ).catchError((e) {
          print('Erro ao pré-carregar próximo track: $e');
        });
      }
    }
  }
  
  /// Headers de autenticação para requisições
  Map<String, String> _getAuthHeaders() {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      return {
        'Authorization': 'Bearer ${session.accessToken}',
      };
    }
    return {};
  }
  
  /// Constrói URL do proxy R2
  String _buildR2ProxyUrl(String filePath) {
    // Se já for URL completa, usar diretamente
    if (filePath.startsWith('http')) {
      return filePath;
    }
    return R2Config.buildFileUrl(filePath);
  }
  
  /// Extrai título do URL (para exibição)
  String _extractTitleFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      return segments.last.split('.').first;
    }
    return 'Áudio';
  }
  
  // Getters para controle do player
  AudioPlayer get player => _audioPlayer;
  
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;
  Stream<SequenceState?> get sequenceStateStream => _audioPlayer.sequenceStateStream;
  
  // Métodos de controle
  Future<void> play() => _audioPlayer.play();
  Future<void> pause() => _audioPlayer.pause();
  Future<void> stop() => _audioPlayer.stop();
  Future<void> seek(Duration position) => _audioPlayer.seek(position);
  Future<void> seekToNext() => _audioPlayer.seekToNext();
  Future<void> seekToPrevious() => _audioPlayer.seekToPrevious();
  Future<void> setVolume(double volume) => _audioPlayer.setVolume(volume);
  Future<void> setSpeed(double speed) => _audioPlayer.setSpeed(speed);
  
  // Informações do track atual
  Future<AudioVersion?> getCurrentVersion() async {
    final index = await _audioPlayer.currentIndex;
    if (index != null && _currentVersions != null && index < _currentVersions!.length) {
      return _currentVersions![index];
    }
    return null;
  }
  
  // Limpar recursos
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
