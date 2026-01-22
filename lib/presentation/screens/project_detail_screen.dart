// lib/presentation/screens/project_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_animations.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/audio_repository.dart';
import '../../data/models/project.dart';
import '../../data/models/audio_version.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/common/gradient_background.dart';
import '../widgets/common/custom_button.dart';
import 'upload_audio_screen.dart';
import 'player_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Project? _project;
  List<AudioVersion> _versions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final projectRepo = ProjectRepository();
      final audioRepo = AudioRepository();

      final project = await projectRepo.getProjectById(widget.projectId);
      final versions = await audioRepo.getVersionsByProject(widget.projectId);

      if (mounted) {
        setState(() {
          _project = project;
          _versions = versions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar dados: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: CustomScrollView(
          slivers: [
            // App Bar com efeito
            _buildSliverAppBar(),
            
            // Conteúdo
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: SpinAnimation(
                    child: Icon(
                      Icons.album_rounded,
                      size: 48,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: _buildError(),
              )
            else ...[
              // Header do projeto
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: _buildProjectHeader(),
                ),
              ),
              
              // Título da seção
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingLg,
                      AppTheme.spacingLg,
                      AppTheme.spacingLg,
                      AppTheme.spacingMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Versões de Áudio',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_versions.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '${_versions.length}',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Lista de versões ou estado vazio
              if (_versions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final version = _versions[index];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 50 * index),
                        child: _AudioTrackCard(
                          version: version,
                          isPlaying: _isTrackPlaying(version.id),
                          onTap: () => _playTrack(version),
                        ),
                      );
                    },
                    childCount: _versions.length,
                  ),
                ),
              
              // Espaço para o player
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ],
        ),
      ),
      
      // Mini player
      bottomNavigationBar: Consumer<AudioPlayerProvider>(
        builder: (context, playerProvider, child) {
          if (playerProvider.currentProjectId != widget.projectId ||
              playerProvider.currentVersions?.isEmpty == true) {
            return const SizedBox.shrink();
          }
          return _MiniPlayer(
            playerProvider: playerProvider,
            onTap: () => _openFullPlayer(),
          );
        },
      ),
      
      // FAB
      floatingActionButton: FadeSlideIn(
        delay: const Duration(milliseconds: 300),
        offset: const Offset(0, 20),
        child: GradientFab(
          icon: Icons.upload_rounded,
          tooltip: 'Upload de áudio',
          onPressed: () => _navigateToUpload(),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.surface.withOpacity(0.9),
      leading: IconBtn(
        icon: Icons.arrow_back_rounded,
        onPressed: () => Navigator.pop(context),
        size: 40,
      ),
      actions: [
        if (_versions.isNotEmpty)
          Consumer<AudioPlayerProvider>(
            builder: (context, playerProvider, _) {
              if (playerProvider.currentProjectId == widget.projectId) {
                return IconBtn(
                  icon: Icons.equalizer_rounded,
                  onPressed: _openFullPlayer,
                  color: AppTheme.primary,
                  size: 40,
                  tooltip: 'Player',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        IconBtn(
          icon: Icons.more_vert_rounded,
          onPressed: () => _showOptionsMenu(),
          size: 40,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary.withOpacity(0.2),
                    AppTheme.surface,
                  ],
                ),
              ),
            ),
            // Padrão decorativo
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Ícone central
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.glowPrimary,
                ),
                child: const Icon(
                  Icons.album_rounded,
                  size: 40,
                  color: AppTheme.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _project?.name ?? 'Projeto',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_project?.description != null) ...[
            const SizedBox(height: 8),
            Text(
              _project!.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingMd),
          
          // Stats
          Row(
            children: [
              _StatChip(
                icon: Icons.audiotrack_rounded,
                label: '${_versions.length} versões',
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.calendar_today_rounded,
                label: _formatDate(_project?.createdAt ?? DateTime.now()),
              ),
            ],
          ),
          
          // Botão Play All
          if (_versions.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingLg),
            CustomButton(
              label: 'Reproduzir Tudo',
              icon: Icons.play_arrow_rounded,
              onPressed: _playAll,
              isExpanded: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_off_rounded,
              size: 48,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Nenhuma versão de áudio',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Faça upload da primeira versão!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          CustomButton(
            label: 'Fazer Upload',
            icon: Icons.upload_rounded,
            onPressed: _navigateToUpload,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Tentar novamente',
            onPressed: _loadData,
            variant: ButtonVariant.outline,
          ),
        ],
      ),
    );
  }

  bool _isTrackPlaying(String versionId) {
    final provider = context.read<AudioPlayerProvider>();
    if (provider.currentProjectId != widget.projectId) return false;
    final versions = provider.currentVersions;
    if (versions == null || versions.isEmpty) return false;
    // Simplificado - pode precisar ajustar baseado no currentIndex
    return false;
  }

  Future<void> _playTrack(AudioVersion version) async {
    final playerProvider = context.read<AudioPlayerProvider>();
    
    if (playerProvider.currentProjectId == widget.projectId) {
      final versions = playerProvider.currentVersions;
      if (versions != null) {
        final index = versions.indexWhere((v) => v.id == version.id);
        if (index != -1) {
          await playerProvider.player.seek(Duration.zero, index: index);
          await playerProvider.play();
          return;
        }
      }
    }
    
    final success = await playerProvider.loadProjectVersions(
      projectId: widget.projectId,
    );
    
    if (success && mounted) {
      final versions = playerProvider.currentVersions;
      if (versions != null) {
        final index = versions.indexWhere((v) => v.id == version.id);
        if (index != -1) {
          await playerProvider.player.seek(Duration.zero, index: index);
          await playerProvider.play();
        }
      }
    }
  }

  Future<void> _playAll() async {
    final playerProvider = context.read<AudioPlayerProvider>();
    final success = await playerProvider.loadProjectVersions(
      projectId: widget.projectId,
    );
    if (success) {
      await playerProvider.play();
    }
  }

  void _openFullPlayer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToUpload() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            UploadAudioScreen(projectId: widget.projectId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) => _loadData());
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceHighlight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Editar projeto'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar edição
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: AppTheme.error),
              title: Text('Excluir projeto', style: TextStyle(color: AppTheme.error)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar exclusão
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighlight,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioTrackCard extends StatelessWidget {
  final AudioVersion version;
  final bool isPlaying;
  final VoidCallback onTap;

  const _AudioTrackCard({
    required this.version,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isPlaying 
              ? AppTheme.primary.withOpacity(0.1) 
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isPlaying 
                ? AppTheme.primary.withOpacity(0.5) 
                : version.isMaster 
                    ? AppTheme.gold.withOpacity(0.5) 
                    : AppTheme.surfaceHighlight,
            width: isPlaying || version.isMaster ? 2 : 1,
          ),
          boxShadow: isPlaying ? [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.15),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ] : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Botão de play
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isPlaying
                      ? AppTheme.primaryGradient
                      : LinearGradient(
                          colors: [
                            AppTheme.surfaceHighlight,
                            AppTheme.surfaceElevated,
                          ],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: isPlaying ? AppTheme.glowPrimary : null,
                ),
                child: Icon(
                  isPlaying 
                      ? Icons.pause_rounded 
                      : Icons.play_arrow_rounded,
                  color: isPlaying 
                      ? AppTheme.surface 
                      : AppTheme.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            version.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isPlaying ? AppTheme.primary : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (version.isMaster) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.gold,
                                  AppTheme.gold.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Text(
                              'MASTER',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (version.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        version.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, 
                            size: 12, 
                            color: AppTheme.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          version.formattedDuration,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.storage_outlined, 
                            size: 12, 
                            color: AppTheme.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          version.formattedFileSize,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Icon(
                Icons.more_vert_rounded,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final AudioPlayerProvider playerProvider;
  final VoidCallback onTap;

  const _MiniPlayer({
    required this.playerProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          border: Border(
            top: BorderSide(
              color: AppTheme.surfaceHighlight,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: AppTheme.surface,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playerProvider.currentVersions?.firstOrNull?.name ?? 'Tocando',
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      StreamBuilder<Duration>(
                        stream: playerProvider.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          return StreamBuilder<Duration?>(
                            stream: playerProvider.durationStream,
                            builder: (context, durSnapshot) {
                              final duration = durSnapshot.data ?? Duration.zero;
                              final progress = duration.inMilliseconds > 0
                                  ? position.inMilliseconds / duration.inMilliseconds
                                  : 0.0;
                              return LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                backgroundColor: AppTheme.surfaceHighlight,
                                valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Controls
                IconBtn(
                  icon: playerProvider.isPlaying 
                      ? Icons.pause_rounded 
                      : Icons.play_arrow_rounded,
                  onPressed: () {
                    if (playerProvider.isPlaying) {
                      playerProvider.pause();
                    } else {
                      playerProvider.play();
                    }
                  },
                  backgroundColor: AppTheme.primary,
                  color: AppTheme.surface,
                  size: 44,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
