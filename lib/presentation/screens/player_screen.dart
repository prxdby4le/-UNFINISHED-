// lib/presentation/screens/player_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_animations.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/common/gradient_background.dart';
import '../widgets/common/custom_button.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    
    // Iniciar rotação se estiver tocando
    final provider = context.read<AudioPlayerProvider>();
    if (provider.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<AudioPlayerProvider>();
    final currentVersion = playerProvider.currentVersions?.isNotEmpty == true
        ? playerProvider.currentVersions!.first
        : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconBtn(
          icon: Icons.keyboard_arrow_down_rounded,
          onPressed: () => Navigator.pop(context),
          size: 44,
        ),
        actions: [
          IconBtn(
            icon: Icons.playlist_play_rounded,
            onPressed: () => _showPlaylist(context),
            size: 44,
          ),
          IconBtn(
            icon: Icons.more_vert_rounded,
            onPressed: () {},
            size: 44,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Artwork com rotação
              Expanded(
                flex: 5,
                child: Center(
                  child: FadeSlideIn(
                    child: _buildArtwork(playerProvider),
                  ),
                ),
              ),
              
              // Info da track
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
                  child: Column(
                    children: [
                      Text(
                        currentVersion?.name ?? 'Sem título',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (currentVersion?.description != null)
                        Text(
                          currentVersion!.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              
              // Progress bar
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: _buildProgressBar(playerProvider),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              
              // Controles
              FadeSlideIn(
                delay: const Duration(milliseconds: 300),
                child: _buildControls(playerProvider),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              
              // Controles secundários
              FadeSlideIn(
                delay: const Duration(milliseconds: 400),
                child: _buildSecondaryControls(playerProvider),
              ),
              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(AudioPlayerProvider playerProvider) {
    // Controlar animação baseado no estado de reprodução
    if (playerProvider.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!playerProvider.isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * math.pi,
          child: child,
        );
      },
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppTheme.surfaceElevated,
              AppTheme.surfaceVariant,
              AppTheme.surface,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 60,
              spreadRadius: -10,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Círculos decorativos (vinil)
            ...List.generate(5, (index) {
              final radius = 80.0 + (index * 20);
              return Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.surfaceHighlight.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              );
            }),
            
            // Centro (label do disco)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: AppTheme.glowPrimary,
              ),
              child: const Icon(
                Icons.music_note_rounded,
                size: 48,
                color: AppTheme.surface,
              ),
            ),
            
            // Buraco do centro
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(AudioPlayerProvider playerProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      child: StreamBuilder<Duration>(
        stream: playerProvider.positionStream,
        builder: (context, positionSnapshot) {
          final position = positionSnapshot.data ?? Duration.zero;
          return StreamBuilder<Duration?>(
            stream: playerProvider.durationStream,
            builder: (context, durationSnapshot) {
              final duration = durationSnapshot.data ?? Duration.zero;
              final progress = duration.inMilliseconds > 0
                  ? position.inMilliseconds / duration.inMilliseconds
                  : 0.0;

              return Column(
                children: [
                  // Slider customizado
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: _CustomThumbShape(),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.surfaceHighlight,
                      thumbColor: AppTheme.primary,
                      overlayColor: AppTheme.primary.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (value) {
                        final newPosition = Duration(
                          milliseconds: (value * duration.inMilliseconds).toInt(),
                        );
                        playerProvider.seek(newPosition);
                      },
                    ),
                  ),
                  
                  // Tempos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
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
    );
  }

  Widget _buildControls(AudioPlayerProvider playerProvider) {
    return StreamBuilder<PlayerState>(
      stream: playerProvider.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final isPlaying = playerState?.playing ?? false;
        final isLoading = playerState?.processingState == ProcessingState.loading ||
            playerState?.processingState == ProcessingState.buffering;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shuffle
            IconBtn(
              icon: Icons.shuffle_rounded,
              onPressed: () {},
              color: AppTheme.textTertiary,
              size: 44,
            ),
            const SizedBox(width: AppTheme.spacingMd),
            
            // Anterior
            IconBtn(
              icon: Icons.skip_previous_rounded,
              onPressed: playerProvider.seekToPrevious,
              backgroundColor: AppTheme.surfaceHighlight,
              size: 56,
            ),
            const SizedBox(width: AppTheme.spacingMd),
            
            // Play/Pause
            if (isLoading)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.glowPrimary,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: AppTheme.surface,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              )
            else
              PlayButton(
                isPlaying: isPlaying,
                onPressed: () {
                  if (isPlaying) {
                    playerProvider.pause();
                  } else {
                    playerProvider.play();
                  }
                },
                size: 80,
              ),
            const SizedBox(width: AppTheme.spacingMd),
            
            // Próximo
            IconBtn(
              icon: Icons.skip_next_rounded,
              onPressed: playerProvider.seekToNext,
              backgroundColor: AppTheme.surfaceHighlight,
              size: 56,
            ),
            const SizedBox(width: AppTheme.spacingMd),
            
            // Repeat
            IconBtn(
              icon: Icons.repeat_rounded,
              onPressed: () {},
              color: AppTheme.textTertiary,
              size: 44,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecondaryControls(AudioPlayerProvider playerProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SecondaryButton(
            icon: Icons.favorite_border_rounded,
            label: 'Curtir',
            onTap: () {},
          ),
          _SecondaryButton(
            icon: Icons.comment_outlined,
            label: 'Feedback',
            onTap: () {},
          ),
          _SecondaryButton(
            icon: Icons.share_outlined,
            label: 'Compartilhar',
            onTap: () {},
          ),
          _SecondaryButton(
            icon: Icons.download_outlined,
            label: 'Download',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showPlaylist(BuildContext context) {
    final playerProvider = context.read<AudioPlayerProvider>();
    final versions = playerProvider.currentVersions ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHighlight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      'Fila de reprodução',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: versions.length,
                  itemBuilder: (context, index) {
                    final version = versions[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHighlight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      title: Text(version.name),
                      subtitle: Text(version.formattedDuration),
                      trailing: const Icon(Icons.drag_handle_rounded),
                      onTap: () async {
                        await playerProvider.player.seek(Duration.zero, index: index);
                        await playerProvider.play();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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

class _CustomThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(16, 16);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    
    // Glow
    final glowPaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 10, glowPaint);
    
    // Thumb
    final paint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, paint);
    
    // Inner circle
    final innerPaint = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, innerPaint);
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
