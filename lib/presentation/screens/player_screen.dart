// lib/presentation/screens/player_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/audio_version.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/models/project.dart';
import '../providers/audio_player_provider.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _colorController;
  late AnimationController _pulseController;
  
  Color _accentColor = const Color(0xFF1E88E5);
  Project? _project;
  
  @override
  void initState() {
    super.initState();
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _loadProjectInfo();
  }

  @override
  void dispose() {
    _colorController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectInfo() async {
    final provider = context.read<AudioPlayerProvider>();
    final projectId = provider.currentProjectId;
    
    if (projectId != null) {
      final project = await ProjectRepository().getProjectById(projectId);
      if (mounted && project != null) {
        setState(() {
          _project = project;
          _accentColor = _generateProjectColor(project.name);
        });
      }
    }
  }

  Color _generateProjectColor(String name) {
    if (name.isEmpty) return const Color(0xFF1E88E5);
    final hash = name.hashCode;
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.45).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<AudioPlayerProvider>();
    final currentVersion = playerProvider.getCurrentVersion();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Background gradient dinâmico
          _buildBackground(),
          
          // Conteúdo principal
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Conteúdo scrollable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          
                          // Artwork
                          _buildArtwork(currentVersion),
                          const SizedBox(height: 32),
                          
                          // Track info
                          _buildTrackInfo(currentVersion),
                          const SizedBox(height: 32),
                          
                          // Waveform + Progress
                          _buildWaveformSection(playerProvider),
                          const SizedBox(height: 24),
                          
                          // Time labels
                          _buildTimeLabels(playerProvider),
                          const SizedBox(height: 32),
                          
                          // Main controls
                          _buildMainControls(playerProvider),
                          const SizedBox(height: 32),
                          
                          // Volume
                          _buildVolumeControl(playerProvider),
                          const SizedBox(height: 24),
                          
                          // Secondary actions
                          _buildSecondaryActions(playerProvider),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _colorController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [
                _accentColor.withOpacity(0.4 * _colorController.value),
                _accentColor.withOpacity(0.15 * _colorController.value),
                const Color(0xFF0A0A0F),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 24),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                'PLAYING FROM',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _project?.name ?? '[UNFINISHED]',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
            onPressed: () => _showOptionsMenu(),
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork(AudioVersion? version) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = 1.0 + (_pulseController.value * 0.02);
        return Transform.scale(
          scale: pulseValue,
          child: child,
        );
      },
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.4),
              blurRadius: 60,
              spreadRadius: -10,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _project?.coverImageUrl != null
              ? Image.network(
                  _project!.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderArtwork(),
                )
              : _buildPlaceholderArtwork(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderArtwork() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentColor,
            _accentColor.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.album,
          size: 100,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(AudioVersion? version) {
    return Column(
      children: [
        Text(
          version?.name ?? 'Sem título',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (version != null && _isLossless(version.format)) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accentColor.withOpacity(0.4)),
                ),
                child: Text(
                  'LOSSLESS',
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              version?.format?.toUpperCase() ?? 'WAV',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            Text(
              ' · ${version?.formattedFileSize ?? '0 MB'}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaveformSection(AudioPlayerProvider playerProvider) {
    return StreamBuilder<Duration>(
      stream: playerProvider.positionStream,
      builder: (context, posSnapshot) {
        return StreamBuilder<Duration?>(
          stream: playerProvider.durationStream,
          builder: (context, durSnapshot) {
            final position = posSnapshot.data ?? Duration.zero;
            final duration = durSnapshot.data ?? Duration.zero;
            final progress = duration.inMilliseconds > 0
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0;

            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                final box = context.findRenderObject() as RenderBox;
                final width = box.size.width;
                final dx = details.localPosition.dx.clamp(0.0, width);
                final newProgress = dx / width;
                final newPosition = Duration(
                  milliseconds: (duration.inMilliseconds * newProgress).round(),
                );
                playerProvider.seek(newPosition);
              },
              onTapDown: (details) {
                HapticFeedback.lightImpact();
                final box = context.findRenderObject() as RenderBox;
                final width = box.size.width;
                final dx = details.localPosition.dx.clamp(0.0, width);
                final newProgress = dx / width;
                final newPosition = Duration(
                  milliseconds: (duration.inMilliseconds * newProgress).round(),
                );
                playerProvider.seek(newPosition);
              },
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(
                    size: const Size(double.infinity, 64),
                    painter: _WaveformPainter(
                      progress: progress.clamp(0.0, 1.0),
                      accentColor: _accentColor,
                      trackId: playerProvider.getCurrentVersion()?.id,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeLabels(AudioPlayerProvider playerProvider) {
    return StreamBuilder<Duration>(
      stream: playerProvider.positionStream,
      builder: (context, posSnapshot) {
        return StreamBuilder<Duration?>(
          stream: playerProvider.durationStream,
          builder: (context, durSnapshot) {
            final position = posSnapshot.data ?? Duration.zero;
            final duration = durSnapshot.data ?? Duration.zero;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '-${_formatDuration(duration - position)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMainControls(AudioPlayerProvider playerProvider) {
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
            StreamBuilder<bool>(
              stream: playerProvider.player.shuffleModeEnabledStream,
              builder: (context, snapshot) {
                final shuffleEnabled = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: shuffleEnabled ? _accentColor : Colors.white.withOpacity(0.5),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    playerProvider.toggleShuffle();
                  },
                );
              },
            ),
            const SizedBox(width: 16),
            
            // Previous
            _ControlButton(
              icon: Icons.skip_previous,
              size: 48,
              onPressed: () {
                HapticFeedback.lightImpact();
                playerProvider.seekToPrevious();
              },
            ),
            const SizedBox(width: 16),
            
            // Play/Pause
            if (isLoading)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  if (isPlaying) {
                    playerProvider.pause();
                  } else {
                    playerProvider.play();
                  }
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _accentColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            const SizedBox(width: 16),
            
            // Next
            _ControlButton(
              icon: Icons.skip_next,
              size: 48,
              onPressed: () {
                HapticFeedback.lightImpact();
                playerProvider.seekToNext();
              },
            ),
            const SizedBox(width: 16),
            
            // Loop
            StreamBuilder<LoopMode>(
              stream: playerProvider.player.loopModeStream,
              builder: (context, snapshot) {
                final loopMode = snapshot.data ?? LoopMode.off;
                IconData icon;
                Color color;
                
                switch (loopMode) {
                  case LoopMode.one:
                    icon = Icons.repeat_one;
                    color = _accentColor;
                    break;
                  case LoopMode.all:
                    icon = Icons.repeat;
                    color = _accentColor;
                    break;
                  default:
                    icon = Icons.repeat;
                    color = Colors.white.withOpacity(0.5);
                }
                
                return IconButton(
                  icon: Icon(icon, color: color),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    playerProvider.toggleLoopMode();
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildVolumeControl(AudioPlayerProvider playerProvider) {
    return Row(
      children: [
        Icon(Icons.volume_down, color: Colors.white.withOpacity(0.5), size: 20),
        Expanded(
          child: StreamBuilder<double>(
            stream: playerProvider.player.volumeStream,
            builder: (context, snapshot) {
              final volume = snapshot.data ?? 1.0;
              return SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: _accentColor,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                  thumbColor: Colors.white,
                  overlayColor: _accentColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: volume,
                  onChanged: (value) => playerProvider.setVolume(value),
                ),
              );
            },
          ),
        ),
        Icon(Icons.volume_up, color: Colors.white.withOpacity(0.5), size: 20),
      ],
    );
  }

  Widget _buildSecondaryActions(AudioPlayerProvider playerProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.favorite_border,
          label: 'Curtir',
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Adicionado aos favoritos!'),
                backgroundColor: _accentColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
        _ActionButton(
          icon: Icons.playlist_play,
          label: 'Fila',
          onTap: () => _showPlaylist(playerProvider),
        ),
        _ActionButton(
          icon: Icons.tune,
          label: 'Ajustes',
          onTap: () => _showAdjustments(playerProvider),
        ),
        _ActionButton(
          icon: Icons.share_outlined,
          label: 'Compartilhar',
          onTap: () {},
        ),
      ],
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.info_outline, color: _accentColor),
            title: const Text('Informações da faixa', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.download_outlined, color: _accentColor),
            title: const Text('Baixar', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.timer_outlined, color: _accentColor),
            title: const Text('Timer de sono', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showPlaylist(AudioPlayerProvider playerProvider) {
    final versions = playerProvider.currentVersions ?? [];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Fila de reprodução',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: versions.length,
                itemBuilder: (context, index) {
                  final version = versions[index];
                  final isCurrent = playerProvider.currentIndex == index;
                  
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCurrent ? _accentColor.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCurrent ? Icons.graphic_eq : Icons.music_note,
                        color: isCurrent ? _accentColor : Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      version.name,
                      style: TextStyle(
                        color: isCurrent ? _accentColor : Colors.white,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      version.formattedDuration,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                    onTap: () {
                      playerProvider.skipToTrack(index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustments(AudioPlayerProvider playerProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ajustes de reprodução',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              
              // Speed
              Row(
                children: [
                  Text('Velocidade', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                  const Spacer(),
                  Text(
                    '${playerProvider.currentSpeed.toStringAsFixed(1)}x',
                    style: TextStyle(color: _accentColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _accentColor,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                  thumbColor: _accentColor,
                ),
                child: Slider(
                  value: playerProvider.currentSpeed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  onChanged: (value) {
                    playerProvider.setSpeed(value);
                    setModalState(() {});
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Presets
              Wrap(
                spacing: 8,
                children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                  final isSelected = playerProvider.currentSpeed == speed;
                  return GestureDetector(
                    onTap: () {
                      playerProvider.setSpeed(speed);
                      setModalState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _accentColor : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${speed}x',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              if (!kIsWeb) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text('Pitch', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                    const Spacer(),
                    Text(
                      '${playerProvider.currentPitch.toStringAsFixed(1)}x',
                      style: TextStyle(color: _accentColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _accentColor,
                    inactiveTrackColor: Colors.white.withOpacity(0.2),
                    thumbColor: _accentColor,
                  ),
                  child: Slider(
                    value: playerProvider.currentPitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    onChanged: (value) {
                      playerProvider.setPitch(value);
                      setModalState(() {});
                    },
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.withOpacity(0.8), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pitch não disponível no navegador',
                          style: TextStyle(color: Colors.orange.withOpacity(0.8), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  bool _isLossless(String? format) {
    if (format == null) return false;
    return ['wav', 'flac', 'aiff', 'alac'].contains(format.toLowerCase());
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// ==================== WIDGETS AUXILIARES ====================

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== WAVEFORM PAINTER ====================

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final String? trackId;

  static final Map<String, List<double>> _waveCache = {};

  _WaveformPainter({
    required this.progress,
    required this.accentColor,
    this.trackId,
  });

  List<double> get _waveData {
    final key = trackId ?? 'default';
    return _waveCache.putIfAbsent(key, () => _generateWave(key));
  }

  static List<double> _generateWave(String seed) {
    final hash = seed.hashCode;
    final random = _SeededRandom(hash);
    
    const count = 80;
    final data = <double>[];
    
    for (int i = 0; i < count; i++) {
      final pos = i / count;
      double value;
      
      // Estrutura musical realista
      if (pos < 0.1) {
        // Intro
        value = 0.2 + random.next() * 0.25;
      } else if (pos < 0.25) {
        // Build up
        value = 0.35 + random.next() * 0.35;
      } else if (pos < 0.65) {
        // Main section (drops, chorus)
        value = 0.5 + random.next() * 0.5;
        // Beats periódicos
        if (i % 4 == 0) value = math.min(1.0, value + 0.1);
      } else if (pos < 0.8) {
        // Bridge
        value = 0.4 + random.next() * 0.35;
      } else {
        // Outro
        value = 0.25 - (pos - 0.8) * 0.5 + random.next() * 0.2;
      }
      
      data.add(value.clamp(0.1, 1.0));
    }
    
    // Suavização
    return _smooth(data);
  }

  static List<double> _smooth(List<double> data) {
    if (data.length < 3) return data;
    final result = <double>[];
    for (int i = 0; i < data.length; i++) {
      if (i == 0 || i == data.length - 1) {
        result.add(data[i]);
      } else {
        result.add((data[i - 1] + data[i] * 2 + data[i + 1]) / 4);
      }
    }
    return result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / _waveData.length;
    final centerY = size.height / 2;
    final maxHeight = size.height * 0.85;
    final progressX = size.width * progress;

    for (int i = 0; i < _waveData.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final barHeight = _waveData[i] * maxHeight;
      final isPlayed = x <= progressX;

      final paint = Paint()
        ..style = PaintingStyle.fill;

      if (isPlayed) {
        paint.shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [accentColor, accentColor.withOpacity(0.6)],
        ).createShader(Rect.fromLTWH(x - barWidth * 0.35, centerY - barHeight / 2, barWidth * 0.7, barHeight));
      } else {
        paint.color = Colors.white.withOpacity(0.12);
      }

      // Barra superior
      final topRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth * 0.35, centerY - barHeight / 2, barWidth * 0.7, barHeight / 2),
        const Radius.circular(2),
      );
      canvas.drawRRect(topRect, paint);

      // Barra inferior (espelhada)
      final bottomRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth * 0.35, centerY, barWidth * 0.7, barHeight / 2),
        const Radius.circular(2),
      );
      canvas.drawRRect(bottomRect, paint);
    }

    // Cursor
    if (progress > 0.005 && progress < 0.995) {
      // Linha vertical
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(progressX, centerY - 16),
        Offset(progressX, centerY + 16),
        linePaint,
      );

      // Círculo
      final cursorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(progressX, centerY), 5, cursorPaint);

      // Glow
      final glowPaint = Paint()
        ..color = accentColor.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(progressX, centerY), 8, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) {
    return progress != old.progress || trackId != old.trackId;
  }
}

class _SeededRandom {
  int _seed;
  _SeededRandom(this._seed);
  
  double next() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }
}
