// lib/presentation/widgets/audio_player_widget.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/audio_player_provider.dart';
import '../../data/models/audio_version.dart';

class AudioPlayerWidget extends StatefulWidget {
  final AudioPlayerProvider playerProvider;
  final AudioVersion? currentVersion;

  const AudioPlayerWidget({
    super.key,
    required this.playerProvider,
    this.currentVersion,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de progresso
            StreamBuilder<Duration>(
              stream: widget.playerProvider.positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: widget.playerProvider.durationStream,
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? Duration.zero;
                    final progress = duration.inMilliseconds > 0
                        ? position.inMilliseconds / duration.inMilliseconds
                        : 0.0;

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: (value) {
                              final newPosition = Duration(
                                milliseconds: (value * duration.inMilliseconds).toInt(),
                              );
                              widget.playerProvider.seek(newPosition);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _formatDuration(duration),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            // Informações e controles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Informações do track
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<int?>(
                          stream: widget.playerProvider.currentIndexStream,
                          builder: (context, snapshot) {
                            final index = snapshot.data;
                            if (widget.currentVersion != null) {
                              return Text(
                                widget.currentVersion!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            return Text(
                              index != null ? 'Track ${index + 1}' : 'Nenhum áudio',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                        if (widget.currentVersion?.description != null)
                          Text(
                            widget.currentVersion!.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Controles
                  StreamBuilder<PlayerState>(
                    stream: widget.playerProvider.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data ??
                          PlayerState(false, ProcessingState.idle);
                      final isPlaying = playerState.playing;
                      final isLoading = playerState.processingState ==
                          ProcessingState.loading;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Anterior
                          IconButton(
                            icon: Icon(Icons.skip_previous),
                            onPressed: isLoading
                                ? null
                                : widget.playerProvider.seekToPrevious,
                            tooltip: 'Anterior',
                          ),

                          // Play/Pause
                          IconButton(
                            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                            iconSize: 32,
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (isPlaying) {
                                      widget.playerProvider.pause();
                                    } else {
                                      widget.playerProvider.play();
                                    }
                                  },
                            tooltip: isPlaying ? 'Pausar' : 'Reproduzir',
                          ),

                          // Próximo
                          IconButton(
                            icon: Icon(Icons.skip_next),
                            onPressed: isLoading
                                ? null
                                : widget.playerProvider.seekToNext,
                            tooltip: 'Próximo',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
