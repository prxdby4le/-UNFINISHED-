// lib/presentation/screens/projects_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/project.dart';
import '../providers/project_provider.dart';
import '../providers/audio_player_provider.dart';
import 'login_screen.dart';
import 'project_detail_screen.dart';
import 'create_project_screen.dart';
import 'cache_settings_screen.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/empty_state_widget.dart';
import '../widgets/common/skeleton_loader.dart';
import '../widgets/authenticated_image.dart';
import '../../data/repositories/image_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../core/utils/color_extractor.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _authRepo = AuthRepository();
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer<ProjectProvider>(
                builder: (context, provider, _) {
                  // Mostrar erro se houver
                  if (provider.errorMessage != null && provider.projects.isEmpty) {
                    return ErrorDisplayWidget(
                      title: 'Erro ao carregar projetos',
                      message: provider.errorMessage!,
                      onRetry: () => provider.loadProjects(),
                    );
                  }
                  
                  // Mostrar loading apenas na primeira vez
                  if (provider.isLoading && provider.projects.isEmpty) {
                    return _buildLoading();
                  }
                  
                  // Mostrar empty state
                  if (provider.projects.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  // Mostrar conteúdo
                  return _buildContent(provider);
                },
              ),
            ),
            // Mini player global (se estiver tocando)
            _buildGlobalMiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          // Logo
          const Text(
            '[UNFINISHED]',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Ações
          _HeaderIcon(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _HeaderIcon(
            icon: Icons.person_outline_rounded,
            onTap: () => _showProfileMenu(),
          ),
          const SizedBox(width: 8),
          _HeaderIcon(
            icon: Icons.search_rounded,
            onTap: () => setState(() => _isSearching = !_isSearching),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 20),
        // Skeleton loaders
        ...List.generate(3, (index) => const ProjectCardSkeleton()),
      ],
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      title: 'Start your first project',
      message: 'Create a home for your work-in-progress music',
      icon: Icons.library_music_rounded,
      iconColor: const Color(0xFF1E88E5),
      action: ElevatedButton.icon(
        onPressed: () => _navigateToCreateProject(),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('New Project'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ProjectProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: const Color(0xFF1E88E5),
      backgroundColor: const Color(0xFF1A1A1F),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // Search bar (se ativo)
          if (_isSearching) ...[
            _buildSearchBar(),
            const SizedBox(height: 20),
          ],
          
          // Seção "My Projects"
          Row(
            children: [
              const Text(
                'My projects',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${provider.projects.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.sort_rounded, color: Colors.white54, size: 20),
                onPressed: _showSortOptions,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Lista de projetos
          ...provider.projects.asMap().entries.map((entry) {
            final index = entry.key;
            final project = entry.value;
            return _ProjectCard(
              project: project,
              onTap: () => _navigateToProject(project.id),
              delay: Duration(milliseconds: 50 * index),
            );
          }),
          
          // Botão de adicionar
          const SizedBox(height: 12),
          _AddProjectButton(onTap: _navigateToCreateProject),
          const SizedBox(height: 100), // Espaço para mini-player
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search projects...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          // TODO: Implementar busca
        },
      ),
    );
  }

  Widget _buildGlobalMiniPlayer() {
    return Consumer<AudioPlayerProvider>(
      builder: (context, provider, _) {
        final currentVersion = provider.getCurrentVersion();
        if (currentVersion == null) return const SizedBox.shrink();
        
        return _GlobalMiniPlayer(
          trackName: currentVersion.name,
          projectId: provider.currentProjectId,
          isPlaying: provider.isPlaying,
          onPlayPause: () {
            if (provider.isPlaying) {
              provider.pause();
            } else {
              provider.play();
            }
          },
          onTap: () {
            if (provider.currentProjectId != null) {
              _navigateToProject(provider.currentProjectId!);
            }
          },
        );
      },
    );
  }

  void _showSortOptions() {
    HapticFeedback.lightImpact();
    final provider = context.read<ProjectProvider>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
            const SizedBox(height: 24),
            const Text(
              'Ordenar projetos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildSortOption(
              'Mais recentes',
              Icons.access_time,
              ProjectSortOption.newest,
              provider.sortOption == ProjectSortOption.newest,
            ),
            _buildSortOption(
              'Mais antigos',
              Icons.history,
              ProjectSortOption.oldest,
              provider.sortOption == ProjectSortOption.oldest,
            ),
            _buildSortOption(
              'Nome (A-Z)',
              Icons.sort_by_alpha,
              ProjectSortOption.nameAsc,
              provider.sortOption == ProjectSortOption.nameAsc,
            ),
            _buildSortOption(
              'Nome (Z-A)',
              Icons.sort_by_alpha,
              ProjectSortOption.nameDesc,
              provider.sortOption == ProjectSortOption.nameDesc,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, IconData icon, ProjectSortOption option, bool isSelected) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF1E88E5) : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1E88E5) : Colors.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF1E88E5))
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<ProjectProvider>().setSortOption(option);
        Navigator.pop(context);
      },
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1F),
        title: const Text(
          'Configurações',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'As configurações estão em desenvolvimento.\nPor enquanto, você pode gerenciar o cache através do menu do perfil.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF1E88E5))),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.storage_outlined, color: Colors.white70),
              title: const Text('Gerenciar Cache', style: TextStyle(color: Colors.white)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CacheSettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.white70),
              title: const Text('Configurações', style: TextStyle(color: Colors.white)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(context);
                _showSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () async {
                Navigator.pop(context);
                await _authRepo.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateProject() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CreateProjectScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) => context.read<ProjectProvider>().loadProjects());
  }

  void _navigateToProject(String projectId) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ProjectDetailScreen(projectId: projectId),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}

// ==================== WIDGETS ====================

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback onTap;
  final Duration delay;

  const _ProjectCard({
    required this.project,
    required this.onTap,
    this.delay = Duration.zero,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  Color _color = const Color(0xFF1E88E5);
  bool _isLoadingColor = true;

  @override
  void initState() {
    super.initState();
    _loadColor();
  }

  @override
  void didUpdateWidget(_ProjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.coverImageUrl != widget.project.coverImageUrl) {
      _loadColor();
    }
  }

  Future<void> _loadColor() async {
    if (widget.project.coverImageUrl != null) {
      try {
        final imageRepo = ImageRepository();
        final proxyUrl = widget.project.coverImageUrl!.startsWith('http')
            ? widget.project.coverImageUrl!
            : imageRepo.getProxyImageUrl(widget.project.coverImageUrl!);
        
        final color = await ColorExtractor.extractDominantColor(proxyUrl);
        if (mounted) {
          setState(() {
            _color = color;
            _isLoadingColor = false;
          });
        }
      } catch (e) {
        debugPrint('[ProjectCard] Erro ao extrair cor: $e');
        if (mounted) {
          setState(() {
            _color = _generateColor(widget.project.name);
            _isLoadingColor = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _color = _generateColor(widget.project.name);
          _isLoadingColor = false;
        });
      }
    }
  }

  Color _generateColor(String name) {
    final hash = name.hashCode;
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.5, 0.45).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141418),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            children: [
              // Capa
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: widget.project.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildCoverImage(widget.project.coverImageUrl!, color),
                      )
                    : _buildIcon(color),
              ),
              const SizedBox(width: 14),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.project.description?.isNotEmpty == true
                          ? widget.project.description!
                          : _formatDate(widget.project.createdAt),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Play
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.3),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(String coverImageUrl, Color color) {
    final imageRepo = ImageRepository();
    final proxyUrl = coverImageUrl.startsWith('http')
        ? coverImageUrl
        : imageRepo.getProxyImageUrl(coverImageUrl);
    
    return AuthenticatedImage(
      imageUrl: proxyUrl,
      fit: BoxFit.cover,
      placeholder: _buildIcon(color),
      errorWidget: _buildIcon(color),
    );
  }

  Widget _buildIcon(Color color) {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        color: Colors.white.withOpacity(0.6),
        size: 24,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _AddProjectButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProjectButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1E88E5).withOpacity(0.3),
            width: 1.5,
          ),
          color: const Color(0xFF1E88E5).withOpacity(0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Color(0xFF1E88E5), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'New Project',
              style: TextStyle(
                color: Color(0xFF1E88E5),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalMiniPlayer extends StatefulWidget {
  final String trackName;
  final String? projectId;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onTap;

  const _GlobalMiniPlayer({
    required this.trackName,
    this.projectId,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onTap,
  });

  @override
  State<_GlobalMiniPlayer> createState() => _GlobalMiniPlayerState();
}

class _GlobalMiniPlayerState extends State<_GlobalMiniPlayer> {
  String? _coverImageUrl;

  @override
  void initState() {
    super.initState();
    _loadCoverImage();
  }

  @override
  void didUpdateWidget(_GlobalMiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _loadCoverImage();
    }
  }

  Future<void> _loadCoverImage() async {
    if (widget.projectId == null) {
      setState(() => _coverImageUrl = null);
      return;
    }

    try {
      final projectRepo = ProjectRepository();
      final project = await projectRepo.getProjectById(widget.projectId!);
      if (project != null && project.coverImageUrl != null) {
        final imageRepo = ImageRepository();
        final proxyUrl = imageRepo.getProxyImageUrl(project.coverImageUrl!);
        if (mounted) {
          setState(() => _coverImageUrl = proxyUrl);
        }
      } else {
        if (mounted) {
          setState(() => _coverImageUrl = null);
        }
      }
    } catch (e) {
      debugPrint('[MiniPlayer] Erro ao carregar capa: $e');
      if (mounted) {
        setState(() => _coverImageUrl = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: Row(
          children: [
            // Capa do projeto ou indicador de playing
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _coverImageUrl != null
                  ? AuthenticatedImage(
                      imageUrl: _coverImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: _buildPlaceholder(),
                      errorWidget: _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.trackName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.isPlaying ? 'Playing' : 'Paused',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            
            // Play/Pause
            GestureDetector(
              onTap: widget.onPlayPause,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E88E5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5).withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: widget.isPlaying
          ? const _PlayingBars()
          : const Icon(Icons.music_note, color: Color(0xFF1E88E5), size: 20),
    );
  }
}

class _PlayingBars extends StatefulWidget {
  const _PlayingBars();

  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final offset = i * 0.2;
            final value = ((_controller.value + offset) % 1.0);
            return Container(
              width: 3,
              height: 8 + (value * 10),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
