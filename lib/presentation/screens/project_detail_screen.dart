// lib/presentation/screens/project_detail_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/audio_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/models/project.dart';
import '../../data/models/audio_version.dart';
import '../providers/audio_player_provider.dart';
import 'upload_audio_screen.dart';
import 'player_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> 
    with TickerProviderStateMixin {
  Project? _project;
  List<AudioVersion> _versions = [];
  bool _isLoading = true;
  bool _isInLibrary = false;
  bool _isTogglingLibrary = false;
  final _libraryRepo = LibraryRepository();
  
  // Cor dinâmica baseada na capa
  Color _dominantColor = const Color(0xFF1E88E5);
  
  late AnimationController _colorController;

  @override
  void initState() {
    super.initState();
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadData();
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final projectRepo = ProjectRepository();
      final audioRepo = AudioRepository();

      final results = await Future.wait([
        projectRepo.getProjectById(widget.projectId),
        audioRepo.getVersionsByProject(widget.projectId),
        _libraryRepo.isInLibrary(widget.projectId),
      ]);

      if (mounted) {
        setState(() {
          _project = results[0] as Project?;
          _versions = results[1] as List<AudioVersion>;
          _isInLibrary = results[2] as bool;
          _isLoading = false;
          
          // Gerar cor baseada no nome do projeto (simulação)
          _dominantColor = _generateProjectColor(_project?.name ?? '');
        });
        _colorController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Gera uma cor única baseada no nome do projeto
  Color _generateProjectColor(String name) {
    if (name.isEmpty) return const Color(0xFF1E88E5);
    
    final hash = name.hashCode;
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.4).toColor();
  }

  Future<void> _toggleLibrary() async {
    if (_isTogglingLibrary || !mounted) return;
    
    HapticFeedback.lightImpact();
    setState(() => _isTogglingLibrary = true);
    
    try {
      if (_isInLibrary) {
        await _libraryRepo.removeFromLibrary(widget.projectId);
        if (mounted) {
          setState(() => _isInLibrary = false);
        }
      } else {
        await _libraryRepo.addToLibrary(widget.projectId);
        if (mounted) {
          setState(() => _isInLibrary = true);
        }
      }
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) {
        setState(() => _isTogglingLibrary = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _dominantColor),
              const SizedBox(height: 16),
              Text(
                'Carregando projeto...',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      );
    }

    if (_project == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(
          child: Text('Projeto não encontrado', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Background gradient baseado na cor dominante
          _buildDynamicBackground(),
          
          // Conteúdo principal
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar com gradiente
              _buildSliverAppBar(),
              
              // Conteúdo
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildTracksList(),
                      const SizedBox(height: 120), // Espaço para mini-player
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Mini-player fixo na parte inferior
          _buildMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildDynamicBackground() {
    return AnimatedBuilder(
      animation: _colorController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _dominantColor.withOpacity(0.3 * _colorController.value),
                _dominantColor.withOpacity(0.1 * _colorController.value),
                const Color(0xFF0A0A0F),
                const Color(0xFF0A0A0F),
              ],
              stops: const [0.0, 0.2, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    final totalDuration = _versions.fold<Duration>(
      Duration.zero,
      (prev, v) => prev + Duration(seconds: v.durationSeconds ?? 0),
    );
    
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeader(totalDuration),
      ),
    );
  }

  Widget _buildHeader(Duration totalDuration) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Capa e info lado a lado
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Capa do álbum
              Hero(
                tag: 'cover_${widget.projectId}',
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _dominantColor.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _project?.coverImageUrl != null
                        ? Image.network(
                            _project!.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
                          )
                        : _buildPlaceholderCover(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${_versions.length} TRACKS · ${_formatDuration(totalDuration)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _project?.name ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _project?.description ?? '[UNFINISHED]',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Botões de ação
          Row(
            children: [
              // Play button
              Expanded(
                child: _PlayButton(
                  color: _dominantColor,
                  onPressed: _playAll,
                ),
              ),
              const SizedBox(width: 12),
              
              // Add to library
              _ActionIcon(
                icon: _isInLibrary ? Icons.check : Icons.add,
                isActive: _isInLibrary,
                color: _dominantColor,
                onPressed: _toggleLibrary,
                isLoading: _isTogglingLibrary,
              ),
              const SizedBox(width: 12),
              
              // Download
              _ActionIcon(
                icon: Icons.download_outlined,
                color: _dominantColor,
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              
              // More options
              _ActionIcon(
                icon: Icons.more_horiz,
                color: _dominantColor,
                onPressed: () => _showMoreOptions(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _dominantColor.withOpacity(0.8),
            _dominantColor.withOpacity(0.4),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.album,
          size: 64,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildTracksList() {
    if (_versions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.music_off_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma faixa ainda',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToUpload(),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar faixa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _dominantColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider com linha
        Container(
          height: 1,
          color: Colors.white.withOpacity(0.1),
        ),
        const SizedBox(height: 16),
        
        // Lista de tracks
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _versions.length,
          itemBuilder: (context, index) {
            final version = _versions[index];
            return _TrackTile(
              index: index + 1,
              version: version,
              accentColor: _dominantColor,
              onTap: () => _playTrack(version, index),
              onMore: () => _showTrackOptions(version),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniPlayer() {
    return Consumer<AudioPlayerProvider>(
      builder: (context, playerProvider, _) {
        final currentVersion = playerProvider.getCurrentVersion();
        final isThisProject = playerProvider.currentProjectId == widget.projectId;
        
        if (currentVersion == null || !isThisProject) {
          return const SizedBox.shrink();
        }
        
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _MiniPlayerWidget(
            version: currentVersion,
            accentColor: _dominantColor,
            onTap: () => _openFullPlayer(),
          ),
        );
      },
    );
  }

  void _playTrack(AudioVersion version, int index) async {
    HapticFeedback.lightImpact();
    final playerProvider = context.read<AudioPlayerProvider>();
    
    await playerProvider.loadProjectVersions(
      projectId: widget.projectId,
      startIndex: index,
    );
    await playerProvider.play();
    
    if (mounted) setState(() {});
  }

  void _playAll() async {
    if (_versions.isEmpty) return;
    HapticFeedback.mediumImpact();
    
    final playerProvider = context.read<AudioPlayerProvider>();
    await playerProvider.loadProjectVersions(projectId: widget.projectId);
    await playerProvider.play();
    
    if (mounted) setState(() {});
  }

  void _openFullPlayer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PlayerScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToUpload() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadAudioScreen(projectId: widget.projectId),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _showMoreOptions() {
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
            leading: Icon(Icons.add, color: _dominantColor),
            title: const Text('Adicionar faixa', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _navigateToUpload();
            },
          ),
          ListTile(
            leading: Icon(Icons.edit_outlined, color: _dominantColor),
            title: const Text('Editar projeto', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.share_outlined, color: _dominantColor),
            title: const Text('Compartilhar', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showTrackOptions(AudioVersion version) {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _dominantColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.music_note, color: _dominantColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        version.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${version.format?.toUpperCase() ?? 'WAV'} · ${version.formattedFileSize}',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.play_arrow, color: _dominantColor),
            title: const Text('Reproduzir', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              final index = _versions.indexOf(version);
              _playTrack(version, index);
            },
          ),
          ListTile(
            leading: Icon(Icons.download_outlined, color: _dominantColor),
            title: const Text('Baixar', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

// ==================== WIDGETS AUXILIARES ====================

class _PlayButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;

  const _PlayButton({required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, color: Colors.black, size: 24),
              SizedBox(width: 8),
              Text(
                'Play',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isActive;
  final bool isLoading;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isActive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? color.withOpacity(0.2) : Colors.white.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isActive ? color : Colors.white,
                  ),
                )
              : Icon(
                  icon,
                  color: isActive ? color : Colors.white,
                  size: 22,
                ),
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final int index;
  final AudioVersion version;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _TrackTile({
    required this.index,
    required this.version,
    required this.accentColor,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<AudioPlayerProvider>();
    final currentVersion = playerProvider.getCurrentVersion();
    final isPlaying = currentVersion?.id == version.id && playerProvider.isPlaying;
    final isCurrentTrack = currentVersion?.id == version.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              // Número ou animação
              SizedBox(
                width: 32,
                child: isPlaying
                    ? _PlayingAnimation(color: accentColor)
                    : Text(
                        '$index',
                        style: TextStyle(
                          color: isCurrentTrack ? accentColor : Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(width: 12),
              
              // Info da track
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      version.name,
                      style: TextStyle(
                        color: isCurrentTrack ? accentColor : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (_isLossless(version.format)) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LOSSLESS',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          version.format?.toUpperCase() ?? 'WAV',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Duração
              Text(
                version.formattedDuration,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              
              // Menu
              IconButton(
                icon: Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.5), size: 20),
                onPressed: onMore,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
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
}

class _PlayingAnimation extends StatefulWidget {
  final Color color;
  const _PlayingAnimation({required this.color});

  @override
  State<_PlayingAnimation> createState() => _PlayingAnimationState();
}

class _PlayingAnimationState extends State<_PlayingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final value = math.sin((_controller.value + delay) * math.pi);
            return Container(
              width: 3,
              height: 8 + (value.abs() * 8),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

// ==================== MINI PLAYER ====================

class _MiniPlayerWidget extends StatelessWidget {
  final AudioVersion version;
  final Color accentColor;
  final VoidCallback onTap;

  const _MiniPlayerWidget({
    required this.version,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Waveform / Progress
            _MiniWaveform(accentColor: accentColor),
            
            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
              child: Row(
                children: [
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          version.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          version.format?.toUpperCase() ?? 'WAV',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Controls
                  Consumer<AudioPlayerProvider>(
                    builder: (context, provider, _) {
                      final isPlaying = provider.isPlaying;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous, color: Colors.white),
                            onPressed: provider.seekToPrevious,
                            iconSize: 28,
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (isPlaying) {
                                  provider.pause();
                                } else {
                                  provider.play();
                                }
                              },
                              iconSize: 24,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next, color: Colors.white),
                            onPressed: provider.seekToNext,
                            iconSize: 28,
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
}

class _MiniWaveform extends StatelessWidget {
  final Color accentColor;
  const _MiniWaveform({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, provider, _) {
        return StreamBuilder<Duration>(
          stream: provider.positionStream,
          builder: (context, posSnapshot) {
            return StreamBuilder<Duration?>(
              stream: provider.durationStream,
              builder: (context, durSnapshot) {
                final position = posSnapshot.data ?? Duration.zero;
                final duration = durSnapshot.data ?? Duration.zero;
                final progress = duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0;

                return Container(
                  height: 32,
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      size: const Size(double.infinity, 32),
                      painter: _MiniWaveformPainter(
                        progress: progress.clamp(0.0, 1.0),
                        accentColor: accentColor,
                        trackId: provider.getCurrentVersion()?.id,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MiniWaveformPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final String? trackId;

  static final Map<String, List<double>> _waveCache = {};

  _MiniWaveformPainter({
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
    
    const count = 60;
    final data = <double>[];
    
    for (int i = 0; i < count; i++) {
      final pos = i / count;
      double value;
      
      // Estrutura de música simulada
      if (pos < 0.15) {
        value = 0.3 + random.next() * 0.3;
      } else if (pos < 0.3) {
        value = 0.4 + random.next() * 0.4;
      } else if (pos < 0.7) {
        value = 0.6 + random.next() * 0.4;
      } else if (pos < 0.85) {
        value = 0.4 + random.next() * 0.35;
      } else {
        value = 0.25 + random.next() * 0.25;
      }
      
      data.add(value.clamp(0.15, 1.0));
    }
    
    return data;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / _waveData.length;
    final progressX = size.width * progress;

    for (int i = 0; i < _waveData.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final barHeight = _waveData[i] * size.height * 0.9;
      final isPlayed = x <= progressX;

      final paint = Paint()
        ..color = isPlayed ? accentColor : Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, size.height / 2),
          width: barWidth * 0.6,
          height: barHeight,
        ),
        const Radius.circular(2),
      );
      
      canvas.drawRRect(rect, paint);
    }

    // Cursor
    if (progress > 0.01 && progress < 0.99) {
      final cursorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(progressX, size.height / 2), 4, cursorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniWaveformPainter old) {
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
