import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/audio_version.dart';

class AudioPlayerProvider extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  List<AudioVersion>? _currentVersions;
  String? _currentProjectId;
  bool _isLoading = false;
  String? _loadingMessage;
  
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
    });
    
    _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (e, st) => debugPrint('[AudioPlayer] Error: $e'),
    );
  }
  
  /// Carrega versões usando URLs assinadas para streaming direto (MUITO mais rápido)
  Future<bool> loadProjectVersions({
    required String projectId,
    List<String>? versionIds,
    int startIndex = 0,
  }) async {
    try {
      // Se já está no mesmo projeto, apenas muda o índice
      if (_currentProjectId == projectId && 
          _currentVersions != null && 
          _currentVersions!.isNotEmpty) {
        await _audioPlayer.seek(Duration.zero, index: startIndex);
        if (!_audioPlayer.playing) await _audioPlayer.play();
        return true;
      }
      
      _isLoading = true;
      _loadingMessage = 'Buscando faixas...';
      _currentProjectId = projectId;
      notifyListeners();
      
      // Buscar versões no banco
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
      
      // ============ STREAMING DIRETO COM SIGNED URLS ============
      _loadingMessage = 'Preparando streaming...';
      notifyListeners();
      
      // Busca todas as URLs assinadas em paralelo (muito rápido)
      List<String> signedUrls;
      try {
        signedUrls = await Future.wait(
          _currentVersions!.map((v) => _getSignedUrl(v.fileUrl))
        );
      } catch (e) {
        debugPrint('[AudioPlayer] Erro ao obter URLs assinadas: $e');
        _isLoading = false;
        _loadingMessage = 'Erro: ${e.toString()}';
        notifyListeners();
        return false;
      }
      
      // Cria a playlist com streaming direto
      final List<AudioSource> sources = [];
      
      for (int i = 0; i < _currentVersions!.length; i++) {
        final version = _currentVersions![i];
        final url = signedUrls[i];
        
        sources.add(AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: version.id,
            title: version.name,
            artist: '[UNFINISHED]',
          ),
        ));
      }
      
      final playlist = ConcatenatingAudioSource(
        children: sources,
        useLazyPreparation: true,
      );
      
      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: startIndex,
        preload: true,
      );
      
      await _audioPlayer.setLoopMode(LoopMode.all);
      
      _isLoading = false;
      _loadingMessage = null;
      notifyListeners();
      
      // Auto play se necessário (geralmente setAudioSource já prepara, mas podemos garantir)
      // O play é chamado pela UI ou aqui se quisermos auto-play
      return true;
    } catch (e) {
      debugPrint('[AudioPlayer] Error: $e');
      _isLoading = false;
      _loadingMessage = null;
      notifyListeners();
      return false;
    }
  }
  
  /// Obtém URL assinada da Edge Function para acesso direto ao R2
  Future<String> _getSignedUrl(String filePath) async {
    if (filePath.startsWith('http')) return filePath;
    
    // A rota da function deve incluir o caminho do arquivo
    // Ex: https://xxx.supabase.co/functions/v1/r2-proxy/user/project/file.wav
    final functionUrl = '${SupabaseConfig.supabaseUrl}/functions/v1/r2-proxy/$filePath';
    
    try {
      debugPrint('[AudioPlayer] Requesting signed URL from: $functionUrl');
      final response = await http.get(
        Uri.parse(functionUrl),
        headers: _getAuthHeaders(),
      );
      
      debugPrint('[AudioPlayer] Response status: ${response.statusCode}');
      debugPrint('[AudioPlayer] Response content-type: ${response.headers['content-type']}');
      debugPrint('[AudioPlayer] Response body preview: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
      
      if (response.statusCode == 200) {
        // Verificar se a resposta é JSON
        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.contains('application/json')) {
          throw Exception(
            'Edge Function retornou dados binários em vez de JSON. '
            'A função precisa ser deployada com a nova versão que retorna URLs assinadas. '
            'Execute: supabase functions deploy r2-proxy --no-verify-jwt'
          );
        }
        
        try {
          final data = jsonDecode(response.body);
          if (data['url'] != null) {
            debugPrint('[AudioPlayer] Signed URL obtained successfully');
            return data['url'] as String;
          } else {
            throw Exception('Resposta não contém campo "url": ${response.body}');
          }
        } catch (jsonError) {
          throw Exception(
            'Erro ao decodificar JSON. A Edge Function pode estar retornando dados binários. '
            'Resposta: ${response.body.substring(0, 200)}...'
          );
        }
      } else {
        final errorBody = response.body.length > 200 
            ? '${response.body.substring(0, 200)}...' 
            : response.body;
        throw Exception('Falha ao assinar URL: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      debugPrint('[AudioPlayer] Erro ao obter URL assinada: $e');
      rethrow; // Re-throw para que o erro seja propagado e tratado acima
    }
  }
  
  Map<String, String> _getAuthHeaders() {
    final session = _supabase.auth.currentSession;
    return {
      'apikey': SupabaseConfig.supabaseAnonKey,
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
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
  
  Future<void> seekToNext() async {
    await _audioPlayer.seekToNext(); 
    // JustAudio já lida com playlist, mas se quiser lógica circular manual:
    // O setLoopMode(LoopMode.all) já deve cuidar do circular quando termina
    // Mas seekToNext() pode travar no fim se não tiver habilitado
    // Vamos manter o padrão da lib
  }
  
  Future<void> seekToPrevious() async {
    await _audioPlayer.seekToPrevious();
  }
  
  Future<void> skipToTrack(int index) async {
    if (_currentVersions == null || index < 0 || index >= _currentVersions!.length) return;
    await _audioPlayer.seek(Duration.zero, index: index);
    await play();
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
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
