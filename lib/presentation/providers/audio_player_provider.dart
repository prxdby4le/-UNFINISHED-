// lib/presentation/providers/audio_player_provider.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/r2_config.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/audio_version.dart';

class AudioPlayerProvider extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  List<AudioVersion>? _currentVersions;
  String? _currentProjectId;
  bool _isLoading = false;
  String? _loadingMessage;
  
  // Cache de áudio
  final Map<String, Uint8List> _audioCache = {};
  
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  
  AudioPlayerProvider() {
    _audioPlayer = AudioPlayer();
    _setupListeners();
  }
  
  void _setupListeners() {
    _audioPlayer.playerStateStream.listen((_) => notifyListeners());
    _audioPlayer.currentIndexStream.listen((index) {
      notifyListeners();
      // Preload próximas faixas quando muda
      if (index != null) _preloadNextTracks(index);
    });
    
    _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (e, st) => debugPrint('[AudioPlayer] Error: $e'),
    );
  }
  
  /// Carrega versões - RÁPIDO: só carrega a faixa selecionada primeiro
  Future<bool> loadProjectVersions({
    required String projectId,
    List<String>? versionIds,
    int startIndex = 0,
  }) async {
    try {
      // Se já está no mesmo projeto com cache, só muda o índice
      if (_currentProjectId == projectId && 
          _currentVersions != null && 
          _currentVersions!.isNotEmpty) {
        // Verificar se a faixa está em cache
        if (startIndex < _currentVersions!.length) {
          final targetVersion = _currentVersions![startIndex];
          if (_audioCache.containsKey(targetVersion.id)) {
            await _audioPlayer.seek(Duration.zero, index: startIndex);
            return true;
          }
        }
      }
      
      _isLoading = true;
      _loadingMessage = 'Buscando faixas...';
      _currentProjectId = projectId;
      notifyListeners();
      
      // Buscar versões
      final response = await _supabase
          .from('audio_versions')
          .select('*')
          .eq('project_id', projectId)
          .order('created_at', ascending: true);
      
      List<dynamic> versionsData = response as List<dynamic>;
      
      if (versionIds != null && versionIds.isNotEmpty) {
        versionsData = versionsData.where((v) => versionIds.contains(v['id'])).toList();
      }
      
      if (versionsData.isEmpty) {
        _isLoading = false;
        _loadingMessage = null;
        notifyListeners();
        return false;
      }
      
      _currentVersions = versionsData
          .map((v) => AudioVersion.fromJson(v as Map<String, dynamic>))
          .toList();
      
      notifyListeners();
      
      // ============ CARREGAMENTO RÁPIDO ============
      // Só carrega a faixa selecionada para começar rápido
      final headers = _getAuthHeaders();
      
      if (kIsWeb) {
        // Carregar apenas a faixa inicial
        _loadingMessage = 'Carregando faixa...';
        notifyListeners();
        
        final targetVersion = _currentVersions![startIndex];
        if (!_audioCache.containsKey(targetVersion.id)) {
          await _downloadTrack(targetVersion, headers);
        }
      }
      
      // Criar playlist
      await _createPlaylist(startIndex);
      
      _isLoading = false;
      _loadingMessage = null;
      notifyListeners();
      
      // Preload das outras faixas em BACKGROUND (não bloqueia)
      if (kIsWeb) {
        _preloadRemainingTracks(startIndex, headers);
      }
      
      return true;
    } catch (e) {
      debugPrint('[AudioPlayer] Error: $e');
      _isLoading = false;
      _loadingMessage = null;
      notifyListeners();
      return false;
    }
  }
  
  /// Cria playlist (usa cache se disponível, senão streaming)
  Future<void> _createPlaylist(int startIndex) async {
    if (_currentVersions == null || _currentVersions!.isEmpty) return;
    
    final headers = _getAuthHeaders();
    final List<AudioSource> sources = [];
    
    for (int i = 0; i < _currentVersions!.length; i++) {
      final version = _currentVersions![i];
      
      if (kIsWeb) {
        if (_audioCache.containsKey(version.id)) {
          // Usar cache
          sources.add(_CachedAudioSource(
            bytes: _audioCache[version.id]!,
            version: version,
          ));
        } else {
          // Lazy loading - carrega quando precisar
          sources.add(_LazyAudioSource(
            version: version,
            fileUrl: _buildR2ProxyUrl(version.fileUrl),
            headers: headers,
            cache: _audioCache,
            onLoaded: () => notifyListeners(),
          ));
        }
      } else {
        // Mobile/Desktop - streaming direto
        sources.add(AudioSource.uri(
          Uri.parse(_buildR2ProxyUrl(version.fileUrl)),
          headers: headers,
          tag: MediaItem(
            id: version.id,
            title: version.name,
            artist: '[UNFINISHED]',
          ),
        ));
      }
    }
    
    final playlist = ConcatenatingAudioSource(
      children: sources,
      useLazyPreparation: true, // Prepara sob demanda
    );
    
    await _audioPlayer.setAudioSource(
      playlist,
      initialIndex: startIndex,
      preload: true,
    );
    
    // Loop da playlist
    await _audioPlayer.setLoopMode(LoopMode.all);
  }
  
  /// Preload das faixas restantes em background
  void _preloadRemainingTracks(int currentIndex, Map<String, String> headers) {
    if (_currentVersions == null) return;
    
    // Preload em ordem de prioridade: próximas primeiro
    final indices = <int>[];
    
    // Próximas faixas
    for (int i = currentIndex + 1; i < _currentVersions!.length; i++) {
      indices.add(i);
    }
    // Faixas anteriores
    for (int i = 0; i < currentIndex; i++) {
      indices.add(i);
    }
    
    // Download em background sem bloquear
    for (final i in indices) {
      final version = _currentVersions![i];
      if (!_audioCache.containsKey(version.id)) {
        _downloadTrack(version, headers).then((_) {
          debugPrint('[AudioPlayer] Background loaded: ${version.name}');
        });
      }
    }
  }
  
  /// Preload das próximas faixas quando muda de track
  void _preloadNextTracks(int currentIndex) {
    if (_currentVersions == null || !kIsWeb) return;
    
    final headers = _getAuthHeaders();
    
    // Preload próximas 2 faixas
    for (int i = 1; i <= 2; i++) {
      final nextIndex = (currentIndex + i) % _currentVersions!.length;
      final version = _currentVersions![nextIndex];
      
      if (!_audioCache.containsKey(version.id)) {
        _downloadTrack(version, headers);
      }
    }
  }
  
  /// Download de uma faixa
  Future<void> _downloadTrack(AudioVersion version, Map<String, String> headers) async {
    if (_audioCache.containsKey(version.id)) return;
    
    try {
      final url = _buildR2ProxyUrl(version.fileUrl);
      debugPrint('[AudioPlayer] Downloading: ${version.name}');
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      if (response.statusCode == 200) {
        _audioCache[version.id] = response.bodyBytes;
        debugPrint('[AudioPlayer] Loaded: ${version.name} (${(response.bodyBytes.length / 1024 / 1024).toStringAsFixed(1)} MB)');
      }
    } catch (e) {
      debugPrint('[AudioPlayer] Download failed: $e');
    }
  }
  
  Map<String, String> _getAuthHeaders() {
    final session = _supabase.auth.currentSession;
    return {
      'apikey': SupabaseConfig.supabaseAnonKey,
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
  }
  
  String _buildR2ProxyUrl(String filePath) {
    if (filePath.startsWith('http')) return filePath;
    return R2Config.buildFileUrl(filePath);
  }
  
  // ============ GETTERS ============
  
  AudioPlayer get player => _audioPlayer;
  bool get isPlaying => _audioPlayer.playing;
  int? get currentIndex => _audioPlayer.currentIndex;
  double get currentSpeed => _audioPlayer.speed;
  double get currentPitch => kIsWeb ? 1.0 : _audioPlayer.pitch;
  
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;
  Stream<SequenceState?> get sequenceStateStream => _audioPlayer.sequenceStateStream;
  
  List<AudioVersion>? get currentVersions => _currentVersions;
  String? get currentProjectId => _currentProjectId;
  
  // ============ CONTROLES ============
  
  Future<void> play() => _audioPlayer.play();
  Future<void> pause() => _audioPlayer.pause();
  Future<void> stop() => _audioPlayer.stop();
  Future<void> seek(Duration position) => _audioPlayer.seek(position);
  Future<void> setVolume(double volume) => _audioPlayer.setVolume(volume);
  Future<void> setSpeed(double speed) => _audioPlayer.setSpeed(speed);
  
  Future<void> setPitch(double pitch) async {
    if (kIsWeb) return; // Não suportado no web
    try {
      await _audioPlayer.setPitch(pitch);
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioPlayer] Pitch error: $e');
    }
  }
  
  /// Próxima faixa (circular)
  Future<void> seekToNext() async {
    final current = _audioPlayer.currentIndex ?? 0;
    final total = _currentVersions?.length ?? 0;
    if (total == 0) return;
    
    final next = (current + 1) % total;
    await _audioPlayer.seek(Duration.zero, index: next);
    if (!_audioPlayer.playing) await play();
    notifyListeners();
  }
  
  /// Faixa anterior (circular)
  Future<void> seekToPrevious() async {
    final current = _audioPlayer.currentIndex ?? 0;
    final total = _currentVersions?.length ?? 0;
    if (total == 0) return;
    
    // Se passou mais de 3s, volta ao início
    if (_audioPlayer.position.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
    } else {
      final prev = current > 0 ? current - 1 : total - 1;
      await _audioPlayer.seek(Duration.zero, index: prev);
      if (!_audioPlayer.playing) await play();
    }
    notifyListeners();
  }
  
  /// Pula para faixa específica
  Future<void> skipToTrack(int index) async {
    if (_currentVersions == null || index < 0 || index >= _currentVersions!.length) return;
    await _audioPlayer.seek(Duration.zero, index: index);
    await play();
    notifyListeners();
  }
  
  Future<void> toggleShuffle() async {
    await _audioPlayer.setShuffleModeEnabled(!_audioPlayer.shuffleModeEnabled);
    notifyListeners();
  }
  
  Future<void> toggleLoopMode() async {
    final modes = [LoopMode.off, LoopMode.all, LoopMode.one];
    final current = modes.indexOf(_audioPlayer.loopMode);
    await _audioPlayer.setLoopMode(modes[(current + 1) % modes.length]);
    notifyListeners();
  }
  
  AudioVersion? getCurrentVersion() {
    final index = _audioPlayer.currentIndex;
    if (index != null && _currentVersions != null && index < _currentVersions!.length) {
      return _currentVersions![index];
    }
    return null;
  }
  
  void clearCache() => _audioCache.clear();
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioCache.clear();
    super.dispose();
  }
}

/// AudioSource de bytes em cache
class _CachedAudioSource extends StreamAudioSource {
  final Uint8List bytes;
  final AudioVersion version;
  
  _CachedAudioSource({required this.bytes, required this.version})
      : super(tag: MediaItem(id: version.id, title: version.name, artist: '[UNFINISHED]'));
  
  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: _contentType,
    );
  }
  
  String get _contentType {
    switch ((version.format ?? 'wav').toLowerCase()) {
      case 'mp3': return 'audio/mpeg';
      case 'flac': return 'audio/flac';
      case 'aiff': return 'audio/aiff';
      case 'm4a': return 'audio/mp4';
      default: return 'audio/wav';
    }
  }
}

/// AudioSource com lazy loading
class _LazyAudioSource extends StreamAudioSource {
  final AudioVersion version;
  final String fileUrl;
  final Map<String, String> headers;
  final Map<String, Uint8List> cache;
  final VoidCallback? onLoaded;
  
  Uint8List? _bytes;
  bool _isLoading = false;
  Completer<void>? _loadCompleter;
  
  _LazyAudioSource({
    required this.version,
    required this.fileUrl,
    required this.headers,
    required this.cache,
    this.onLoaded,
  }) : super(tag: MediaItem(id: version.id, title: version.name, artist: '[UNFINISHED]'));
  
  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // Verificar cache
    _bytes ??= cache[version.id];
    
    // Carregar se necessário
    if (_bytes == null) {
      if (!_isLoading) {
        _isLoading = true;
        _loadCompleter = Completer<void>();
        
        try {
          debugPrint('[LazyAudio] Loading: ${version.name}');
          final response = await http.get(Uri.parse(fileUrl), headers: headers);
          
          if (response.statusCode == 200) {
            _bytes = response.bodyBytes;
            cache[version.id] = _bytes!;
            debugPrint('[LazyAudio] Loaded: ${version.name}');
            onLoaded?.call();
          } else {
            throw Exception('HTTP ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('[LazyAudio] Error: $e');
          _loadCompleter?.completeError(e);
          rethrow;
        } finally {
          _isLoading = false;
          if (!_loadCompleter!.isCompleted) {
            _loadCompleter!.complete();
          }
        }
      } else {
        // Aguardar carregamento em andamento
        await _loadCompleter?.future;
        _bytes ??= cache[version.id];
      }
    }
    
    if (_bytes == null) throw Exception('Failed to load audio');
    
    start ??= 0;
    end ??= _bytes!.length;
    
    return StreamAudioResponse(
      sourceLength: _bytes!.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes!.sublist(start, end)),
      contentType: _contentType,
    );
  }
  
  String get _contentType {
    switch ((version.format ?? 'wav').toLowerCase()) {
      case 'mp3': return 'audio/mpeg';
      case 'flac': return 'audio/flac';
      case 'aiff': return 'audio/aiff';
      case 'm4a': return 'audio/mp4';
      default: return 'audio/wav';
    }
  }
}
