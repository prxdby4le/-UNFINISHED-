import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/cache/audio_cache_manager.dart';
import '../../data/models/audio_version.dart';

class AudioPlayerProvider extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  final SupabaseClient _supabase = SupabaseConfig.client;
  final AudioCacheManager _cacheManager = AudioCacheManager();
  
  List<AudioVersion>? _currentVersions;
  String? _currentProjectId;
  bool _isLoading = false;
  String? _loadingMessage;
  int? _nextTrackIndex; // Para pré-cache
  
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  
  AudioPlayerProvider() {
    _audioPlayer = AudioPlayer();
    _setupListeners();
    _initializeCache();
  }
  
  Future<void> _initializeCache() async {
    await _cacheManager.initialize();
  }
  
  void _setupListeners() {
    _audioPlayer.playerStateStream.listen((_) => notifyListeners());
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && _currentVersions != null) {
        _preCacheNextTrack(index);
      }
      notifyListeners();
    });
    
    _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (e, st) => debugPrint('[AudioPlayer] Error: $e'),
    );
  }
  
  /// Pré-cache do próximo track em background
  void _preCacheNextTrack(int currentIndex) {
    if (_currentVersions == null || _currentVersions!.isEmpty) return;
    
    final nextIndex = currentIndex + 1;
    if (nextIndex >= _currentVersions!.length) return;
    
    // Evitar pré-cache duplicado
    if (_nextTrackIndex == nextIndex) return;
    _nextTrackIndex = nextIndex;
    
    final nextVersion = _currentVersions![nextIndex];
    if (nextVersion.fileUrl.isEmpty) return;
    
    // Pré-cache em background (não bloqueia)
    _cacheManager.preCacheFile(
      versionId: nextVersion.id,
      fileUrl: nextVersion.fileUrl,
    ).catchError((e) {
      debugPrint('[AudioPlayer] Erro no pré-cache: $e');
    });
  }
  
  /// Carrega versões usando URLs assinadas para streaming direto (MUITO mais rápido)
  Future<bool> loadProjectVersions({
    required String projectId,
    List<String>? versionIds,
    int startIndex = 0,
    bool forceReload = false,
  }) async {
    try {
      // Buscar versões no banco primeiro para verificar se há mudanças
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
      
      final newVersions = versionsData
          .map((v) => AudioVersion.fromJson(v as Map<String, dynamic>))
          .toList();
      
      // Verificar se precisa recarregar: projeto diferente, número de versões mudou, ou forceReload
      final needsReload = forceReload ||
          _currentProjectId != projectId ||
          _currentVersions == null ||
          _currentVersions!.length != newVersions.length ||
          // Verificar se os IDs das versões mudaram (nova música adicionada)
          !_currentVersions!.every((v) => newVersions.any((nv) => nv.id == v.id)) ||
          !newVersions.every((nv) => _currentVersions!.any((v) => v.id == nv.id));
      
      // Se já está no mesmo projeto e não precisa recarregar, apenas muda o índice
      if (!needsReload && 
          _currentProjectId == projectId && 
          _currentVersions != null && 
          _currentVersions!.isNotEmpty) {
        try {
          await _audioPlayer.seek(Duration.zero, index: startIndex);
          if (!_audioPlayer.playing) await _audioPlayer.play();
          return true;
        } catch (e) {
          debugPrint('[AudioPlayer] Erro ao fazer seek, recarregando playlist: $e');
          // Se o seek falhar, forçar recarregamento
        }
      }
      
      _isLoading = true;
      _loadingMessage = 'Buscando faixas...';
      _currentProjectId = projectId;
      _currentVersions = newVersions;
      notifyListeners();
      
      // ============ STREAMING DIRETO COM SIGNED URLS ============
      _loadingMessage = 'Preparando streaming...';
      notifyListeners();
      
      // Validar que todas as versões têm fileUrl válido
      for (final version in _currentVersions!) {
        if (version.fileUrl.isEmpty) {
          throw Exception('Versão "${version.name}" não possui URL de arquivo válida');
        }
      }
      
      // Verificar cache e obter URLs (cache ou signed URLs)
      _loadingMessage = 'Verificando cache...';
      notifyListeners();
      
      final List<String> audioSources = [];
      final List<bool> isCached = [];
      
      // Verificar cache para cada versão
      for (final version in _currentVersions!) {
        final cached = await _cacheManager.isCached(version.id, version.fileUrl);
        isCached.add(cached);
        
        if (cached) {
          // Usar arquivo do cache
          try {
            final cachePath = await _cacheManager.getCachedFile(
              versionId: version.id,
              fileUrl: version.fileUrl,
            );
            audioSources.add(cachePath);
            debugPrint('[AudioPlayer] Usando cache para: ${version.name}');
          } catch (e) {
            debugPrint('[AudioPlayer] Erro ao obter do cache, usando streaming: $e');
            // Fallback para streaming
            final signedUrl = await _getSignedUrl(version.fileUrl);
            audioSources.add(signedUrl);
            isCached[isCached.length - 1] = false;
          }
        } else {
          // Obter URL assinada para streaming
          try {
            final signedUrl = await _getSignedUrl(version.fileUrl);
            audioSources.add(signedUrl);
          } catch (e) {
            debugPrint('[AudioPlayer] Erro ao obter URL assinada: $e');
            throw Exception('Falha ao obter URL para "${version.name}": $e');
          }
        }
      }
      
      // Validar que todas as URLs foram obtidas com sucesso
      for (int i = 0; i < audioSources.length; i++) {
        if (audioSources[i].isEmpty) {
          throw Exception('Falha ao obter fonte de áudio para "${_currentVersions![i].name}"');
        }
      }
      
      // Cria a playlist (cache local ou streaming)
      _loadingMessage = 'Preparando playlist...';
      notifyListeners();
      
      final List<AudioSource> sources = [];
      
      for (int i = 0; i < _currentVersions!.length; i++) {
        final version = _currentVersions![i];
        final source = audioSources[i];
        
        sources.add(AudioSource.uri(
          Uri.parse(source),
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
      
      // Parar o player antes de definir nova fonte para evitar conflitos
      try {
        await _audioPlayer.stop();
      } catch (e) {
        debugPrint('[AudioPlayer] Erro ao parar player (pode estar já parado): $e');
      }
      
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
    } catch (e, stackTrace) {
      debugPrint('[AudioPlayer] Error: $e');
      debugPrint('[AudioPlayer] StackTrace: $stackTrace');
      _isLoading = false;
      _loadingMessage = null;
      notifyListeners();
      return false;
    }
  }
  
  /// Obtém URL assinada da Edge Function para acesso direto ao R2
  Future<String> _getSignedUrl(String filePath) async {
    if (filePath.startsWith('http')) return filePath;
    
    // Verificar se há sessão autenticada antes de fazer a requisição
    var session = _supabase.auth.currentSession;
    if (session == null) {
      debugPrint('[AudioPlayer] Nenhuma sessão encontrada, tentando atualizar...');
      try {
        await _supabase.auth.refreshSession();
        session = _supabase.auth.currentSession;
      } catch (e) {
        debugPrint('[AudioPlayer] Erro ao atualizar sessão: $e');
      }
      
      if (session == null) {
        throw Exception(
          'Não autenticado. Por favor, faça login novamente. '
          'A Edge Function requer autenticação para acessar os arquivos.'
        );
      }
    }
    
    // A rota da function deve incluir o caminho do arquivo
    // Ex: https://xxx.supabase.co/functions/v1/r2-proxy/user/project/file.wav
    final functionUrl = '${SupabaseConfig.supabaseUrl}/functions/v1/r2-proxy/$filePath';
    
    try {
      debugPrint('[AudioPlayer] Requesting signed URL from: $functionUrl');
      debugPrint('[AudioPlayer] File path: $filePath');
      debugPrint('[AudioPlayer] Has auth token: true');
      
      final headers = {
        'apikey': SupabaseConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      final response = await http.get(
        Uri.parse(functionUrl),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'Timeout ao conectar com a Edge Function. '
            'Verifique sua conexão com a internet e se a função está deployada.'
          );
        },
      );
      
      debugPrint('[AudioPlayer] Response status: ${response.statusCode}');
      debugPrint('[AudioPlayer] Response content-type: ${response.headers['content-type']}');
      if (response.body.isNotEmpty) {
        final preview = response.body.length > 200 
            ? '${response.body.substring(0, 200)}...' 
            : response.body;
        debugPrint('[AudioPlayer] Response body preview: $preview');
      }
      
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
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['url'] != null && data['url'] is String) {
            final signedUrl = data['url'] as String;
            debugPrint('[AudioPlayer] Signed URL obtained successfully (length: ${signedUrl.length})');
            return signedUrl;
          } else if (data['error'] != null) {
            throw Exception('Edge Function retornou erro: ${data['error']}');
          } else {
            throw Exception('Resposta não contém campo "url": ${response.body}');
          }
        } catch (jsonError) {
          debugPrint('[AudioPlayer] JSON decode error: $jsonError');
          throw Exception(
            'Erro ao decodificar JSON. A Edge Function pode estar retornando dados binários. '
            'Resposta: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}...'
          );
        }
      } else if (response.statusCode == 401) {
        // Token pode ter expirado, tentar atualizar
        debugPrint('[AudioPlayer] 401 Unauthorized, tentando atualizar sessão...');
        try {
          await _supabase.auth.refreshSession();
          session = _supabase.auth.currentSession;
          if (session != null) {
            // Tentar novamente com o novo token
            debugPrint('[AudioPlayer] Sessão atualizada, tentando novamente...');
            return await _getSignedUrl(filePath);
          }
        } catch (e) {
          debugPrint('[AudioPlayer] Erro ao atualizar sessão: $e');
        }
        throw Exception(
          'Não autenticado. Por favor, faça login novamente. '
          'Status: ${response.statusCode}'
        );
      } else if (response.statusCode == 502 || response.statusCode == 503) {
        throw Exception(
          'Edge Function não está disponível (${response.statusCode}). '
          'Verifique se a função r2-proxy está deployada corretamente no Supabase. '
          'Execute: supabase functions deploy r2-proxy --no-verify-jwt'
        );
      } else {
        final errorBody = response.body.length > 300 
            ? '${response.body.substring(0, 300)}...' 
            : response.body;
        throw Exception('Falha ao assinar URL: ${response.statusCode} - $errorBody');
      }
    } on http.ClientException catch (e) {
      // Erro de rede (CORS, conexão, etc)
      debugPrint('[AudioPlayer] ClientException: $e');
      if (e.message.contains('CORS') || e.message.contains('Failed to fetch')) {
        throw Exception(
          'Erro de CORS ou conexão. Verifique:\n'
          '1. Se a Edge Function r2-proxy está deployada\n'
          '2. Se os headers CORS estão configurados na função\n'
          '3. Se o bucket R2 tem CORS configurado\n'
          'Erro: ${e.message}'
        );
      }
      throw Exception(
        'Erro de conexão: ${e.message}. '
        'Verifique sua conexão com a internet.'
      );
    } catch (e) {
      debugPrint('[AudioPlayer] Erro ao obter URL assinada: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erro desconhecido: $e');
    }
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
  
  Future<void> play() async {
    try {
      final sequenceState = _audioPlayer.sequenceState;
      if (sequenceState == null || sequenceState.currentSource == null) {
        debugPrint('[AudioPlayer] Não é possível reproduzir: player não está pronto');
        // Tentar recarregar se tiver projeto atual
        if (_currentProjectId != null) {
          await loadProjectVersions(
            projectId: _currentProjectId!,
            forceReload: true,
          );
        }
        return;
      }
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('[AudioPlayer] Erro ao reproduzir: $e');
      // Tentar recarregar se necessário
      if (e.toString().contains('null') || e.toString().contains('Unexpected')) {
        if (_currentProjectId != null) {
          await loadProjectVersions(
            projectId: _currentProjectId!,
            forceReload: true,
          );
        }
      }
    }
  }
  
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('[AudioPlayer] Erro ao pausar: $e');
    }
  }
  
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('[AudioPlayer] Erro ao parar: $e');
    }
  }
  Future<void> seek(Duration position) async {
    try {
      // Verificar se o player está em um estado válido antes de fazer seek
      final sequenceState = _audioPlayer.sequenceState;
      if (sequenceState == null || sequenceState.currentSource == null) {
        debugPrint('[AudioPlayer] Não é possível fazer seek: player não está pronto');
        return;
      }
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('[AudioPlayer] Erro ao fazer seek: $e');
      // Tentar recarregar a playlist se o erro for relacionado a estado inválido
      if (e.toString().contains('null') || e.toString().contains('Unexpected')) {
        debugPrint('[AudioPlayer] Tentando recarregar playlist devido a erro de estado');
        if (_currentProjectId != null) {
          await loadProjectVersions(
            projectId: _currentProjectId!,
            forceReload: true,
          );
        }
      }
    }
  }
  
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      debugPrint('[AudioPlayer] Erro ao definir volume: $e');
    }
  }
  
  Future<void> setSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
    } catch (e) {
      debugPrint('[AudioPlayer] Erro ao definir velocidade: $e');
    }
  }
  
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
    try {
      final sequenceState = _audioPlayer.sequenceState;
      if (sequenceState == null || sequenceState.currentSource == null) {
        debugPrint('[AudioPlayer] Não é possível avançar: player não está pronto');
        return;
      }
      await _audioPlayer.seekToNext();
    } catch (e) {
      debugPrint('[AudioPlayer] Erro ao avançar: $e');
      // Tentar recarregar se necessário
      if (e.toString().contains('null') || e.toString().contains('Unexpected')) {
        if (_currentProjectId != null) {
          await loadProjectVersions(
            projectId: _currentProjectId!,
            forceReload: true,
          );
        }
      }
    }
  }
  
  Future<void> seekToPrevious() async {
    try {
      final sequenceState = _audioPlayer.sequenceState;
      if (sequenceState == null || sequenceState.currentSource == null) {
        debugPrint('[AudioPlayer] Não é possível retroceder: player não está pronto');
        return;
      }
      await _audioPlayer.seekToPrevious();
    } catch (e) {
      debugPrint('[AudioPlayer] Erro ao retroceder: $e');
      // Tentar recarregar se necessário
      if (e.toString().contains('null') || e.toString().contains('Unexpected')) {
        if (_currentProjectId != null) {
          await loadProjectVersions(
            projectId: _currentProjectId!,
            forceReload: true,
          );
        }
      }
    }
  }
  
  Future<void> skipToTrack(int index) async {
    if (_currentVersions == null || index < 0 || index >= _currentVersions!.length) {
      debugPrint('[AudioPlayer] Índice inválido: $index (total: ${_currentVersions?.length ?? 0})');
      return;
    }
    try {
      final sequenceState = _audioPlayer.sequenceState;
      if (sequenceState == null) {
        debugPrint('[AudioPlayer] Player não está pronto, recarregando...');
        await loadProjectVersions(
          projectId: _currentProjectId!,
          startIndex: index,
          forceReload: true,
        );
        return;
      }
      await _audioPlayer.seek(Duration.zero, index: index);
      await play();
    } catch (e) {
      debugPrint('[AudioPlayer] Erro ao pular para faixa: $e');
      // Tentar recarregar a playlist
      if (_currentProjectId != null) {
        await loadProjectVersions(
          projectId: _currentProjectId!,
          startIndex: index,
          forceReload: true,
        );
      }
    }
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
