# 🎵 Implementação Gapless Playback

## Visão Geral

O `just_audio` suporta gapless playback nativamente quando configurado corretamente. Este documento mostra como implementar para arquivos remotos (R2/Supabase).

## Configuração Básica

### 1. Dependências

```yaml
# pubspec.yaml
dependencies:
  just_audio: ^0.9.36
  just_audio_background: ^0.0.1-beta.35
  audio_service: ^0.18.10
```

### 2. Exemplo Completo: AudioPlayer com Gapless

```dart
// lib/presentation/providers/audio_player_provider.dart
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AudioPlayerProvider {
  late AudioPlayer _audioPlayer;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  AudioPlayerProvider() {
    _audioPlayer = AudioPlayer();
  }
  
  /// Configura uma playlist com gapless playback
  /// 
  /// [audioUrls] - Lista de URLs dos arquivos de áudio
  /// Retorna true se a configuração foi bem-sucedida
  Future<bool> loadPlaylistGapless({
    required List<String> audioUrls,
    int initialIndex = 0,
  }) async {
    try {
      // Converter URLs para AudioSource com suporte a gapless
      final List<AudioSource> audioSources = audioUrls.map((url) {
        // Para arquivos remotos, usar ConcatenatingAudioSource
        // que suporta gapless nativamente
        return AudioSource.uri(
          Uri.parse(url),
          headers: _getAuthHeaders(),
          tag: MediaItem(
            id: url,
            title: _extractTitleFromUrl(url),
            artUri: Uri.parse('https://example.com/cover.jpg'),
          ),
        );
      }).toList();
      
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
  Future<bool> loadProjectVersions({
    required String projectId,
    List<String>? versionIds, // Se null, carrega todas
  }) async {
    try {
      // Buscar versões do projeto
      var query = _supabase
          .from('audio_versions')
          .select('id, file_url, name')
          .eq('project_id', projectId)
          .order('created_at', ascending: true);
      
      if (versionIds != null && versionIds.isNotEmpty) {
        query = query.in_('id', versionIds);
      }
      
      final response = await query.execute();
      final versions = response.data as List<dynamic>;
      
      if (versions.isEmpty) {
        return false;
      }
      
      // Construir URLs completas (via proxy R2)
      final audioUrls = versions.map((v) {
        final fileUrl = v['file_url'] as String;
        // Se já for URL completa, usar diretamente
        // Se for caminho relativo, construir URL do proxy
        if (fileUrl.startsWith('http')) {
          return fileUrl;
        }
        return _buildR2ProxyUrl(fileUrl);
      }).toList();
      
      return await loadPlaylistGapless(audioUrls: audioUrls);
    } catch (e) {
      print('Erro ao carregar versões do projeto: $e');
      return false;
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
    final supabaseUrl = _supabase.supabaseUrl;
    // Remove barras iniciais do caminho
    final cleanPath = filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$supabaseUrl/functions/v1/r2-proxy/$cleanPath';
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
  
  // Métodos de controle
  Future<void> play() => _audioPlayer.play();
  Future<void> pause() => _audioPlayer.pause();
  Future<void> stop() => _audioPlayer.stop();
  Future<void> seek(Duration position) => _audioPlayer.seek(position);
  Future<void> seekToNext() => _audioPlayer.seekToNext();
  Future<void> seekToPrevious() => _audioPlayer.seekToPrevious();
  
  // Limpar recursos
  Future<void> dispose() => _audioPlayer.dispose();
}
```

### 3. Configuração para Background Playback

```dart
// lib/main.dart
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar background audio
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.trashtalk.audio',
    androidNotificationChannelName: 'Trashtalk Audio',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
  );
  
  runApp(MyApp());
}
```

### 4. Widget de Player com Gapless

```dart
// lib/presentation/widgets/audio_player_widget.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/audio_player_provider.dart';

class AudioPlayerWidget extends StatefulWidget {
  final AudioPlayerProvider playerProvider;
  
  const AudioPlayerWidget({
    Key? key,
    required this.playerProvider,
  }) : super(key: key);
  
  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: widget.playerProvider.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data ?? PlayerState(false, ProcessingState.idle);
        final processingState = playerState.processingState;
        
        return Column(
          children: [
            // Indicador de progresso
            StreamBuilder<Duration>(
              stream: widget.playerProvider.positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: widget.playerProvider.durationStream,
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? Duration.zero;
                    return Slider(
                      value: position.inMilliseconds.toDouble(),
                      min: 0,
                      max: duration.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        widget.playerProvider.seek(Duration(milliseconds: value.toInt()));
                      },
                    );
                  },
                );
              },
            ),
            
            // Controles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous),
                  onPressed: playerState.processingState != ProcessingState.loading
                      ? widget.playerProvider.seekToPrevious
                      : null,
                ),
                IconButton(
                  icon: Icon(playerState.playing ? Icons.pause : Icons.play_arrow),
                  onPressed: playerState.processingState != ProcessingState.loading
                      ? () {
                          if (playerState.playing) {
                            widget.playerProvider.pause();
                          } else {
                            widget.playerProvider.play();
                          }
                        }
                      : null,
                ),
                IconButton(
                  icon: Icon(Icons.skip_next),
                  onPressed: playerState.processingState != ProcessingState.loading
                      ? widget.playerProvider.seekToNext
                      : null,
                ),
              ],
            ),
            
            // Indicador de track atual
            StreamBuilder<int?>(
              stream: widget.playerProvider.currentIndexStream,
              builder: (context, snapshot) {
                final index = snapshot.data;
                if (index != null) {
                  return Text('Track ${index + 1}');
                }
                return SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }
}
```

## Otimizações para Gapless

### 1. Pré-carregamento Inteligente

```dart
// Pré-carregar próximo arquivo enquanto o atual está tocando
Future<void> _preloadNext() async {
  final currentIndex = await _audioPlayer.currentIndex;
  if (currentIndex != null && currentIndex < _audioPlayer.audioSourceSequence.length - 1) {
    // just_audio faz isso automaticamente com useLazyPreparation: true
    // Mas você pode forçar pré-carregamento manual se necessário
  }
}
```

### 2. Cache Local para Gapless Mais Suave

Combine com estratégia de cache (ver `CACHE_STRATEGY.md`) para arquivos já baixados serem reproduzidos localmente, garantindo gapless perfeito.

### 3. Formato de Arquivo

- **WAV**: Melhor para gapless (sem compressão)
- **FLAC**: Excelente qualidade, boa para gapless
- **MP3**: Pode ter pequenas pausas entre tracks (depende do encoder)

## Troubleshooting

### Problema: Pequenas pausas entre tracks

**Solução**: 
- Verifique se `useLazyPreparation: true` está configurado
- Certifique-se de que os arquivos não têm silêncio no início/fim
- Use WAV ou FLAC em vez de MP3

### Problema: Player trava ao trocar de track

**Solução**:
- Implemente tratamento de erro robusto
- Adicione retry logic para downloads
- Use cache local quando possível

### Problema: Background playback não funciona

**Solução**:
- Verifique se `just_audio_background` está inicializado
- Configure permissões de background no Android/iOS
- Teste com app minimizado
