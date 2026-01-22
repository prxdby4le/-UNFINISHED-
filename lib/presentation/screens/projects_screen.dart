// lib/presentation/screens/projects_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_animations.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/project_provider.dart';
import '../widgets/common/gradient_background.dart';
import '../widgets/common/custom_input.dart';
import '../widgets/common/custom_button.dart';
import 'login_screen.dart';
import 'project_detail_screen.dart';
import 'create_project_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchController = TextEditingController();
  final _authRepo = AuthRepository();

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
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com saudação
              FadeSlideIn(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg, 
                    AppTheme.spacingMd, 
                    AppTheme.spacingLg, 
                    0,
                  ),
                  child: _buildHeader(),
                ),
              ),
              
              // Barra de busca
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: SearchInput(
                    controller: _searchController,
                    hint: 'Buscar projetos...',
                    onChanged: (value) {
                      if (value.isEmpty) {
                        context.read<ProjectProvider>().loadProjects();
                      } else {
                        context.read<ProjectProvider>().searchProjects(value);
                      }
                    },
                    onClear: () {
                      context.read<ProjectProvider>().loadProjects();
                    },
                  ),
                ),
              ),
              
              // Título da seção
              FadeSlideIn(
                delay: const Duration(milliseconds: 150),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                    vertical: AppTheme.spacingSm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Projetos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Consumer<ProjectProvider>(
                        builder: (context, provider, _) {
                          if (provider.projects.isEmpty) return const SizedBox.shrink();
                          return Container(
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
                              '${provider.projects.length}',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Lista de projetos
              Expanded(
                child: Consumer<ProjectProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.projects.isEmpty) {
                      return _buildLoading();
                    }

                    if (provider.errorMessage != null && provider.projects.isEmpty) {
                      return _buildError(provider);
                    }

                    if (provider.projects.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () => provider.refresh(),
                      color: AppTheme.primary,
                      backgroundColor: AppTheme.surfaceVariant,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacing3xl,
                        ),
                        itemCount: provider.projects.length,
                        itemBuilder: (context, index) {
                          final project = provider.projects[index];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 50 * index),
                            child: ProjectCard(
                              title: project.name,
                              subtitle: project.description,
                              date: _formatDate(project.createdAt),
                              onTap: () => _navigateToProject(project.id),
                              accentColor: _getProjectColor(index),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FadeSlideIn(
        delay: const Duration(milliseconds: 300),
        offset: const Offset(0, 20),
        child: GradientFab(
          icon: Icons.add_rounded,
          tooltip: 'Novo projeto',
          onPressed: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const CreateProjectScreen(),
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
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.headset_rounded,
              size: 18,
              color: AppTheme.surface,
            ),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'TRASHTALK',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconBtn(
          icon: Icons.logout_rounded,
          onPressed: () async {
            await _authRepo.signOut();
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
          size: 40,
          tooltip: 'Sair',
        ),
        const SizedBox(width: AppTheme.spacingSm),
      ],
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;
    
    if (hour < 12) {
      greeting = 'Bom dia';
      icon = Icons.wb_sunny_rounded;
    } else if (hour < 18) {
      greeting = 'Boa tarde';
      icon = Icons.wb_cloudy_rounded;
    } else {
      greeting = 'Boa noite';
      icon = Icons.nights_stay_rounded;
    }

    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinAnimation(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.headset_rounded,
                color: AppTheme.surface,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Carregando projetos...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ProjectProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Ops! Algo deu errado',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              provider.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            CustomButton(
              label: 'Tentar novamente',
              onPressed: () => provider.refresh(),
              variant: ButtonVariant.outline,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.1),
                    AppTheme.secondary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 56,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Nenhum projeto ainda',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Crie seu primeiro projeto para\ncomeçar a organizar suas músicas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            CustomButton(
              label: 'Criar primeiro projeto',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateProjectScreen(),
                  ),
                );
              },
              icon: Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProject(String projectId) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProjectDetailScreen(projectId: projectId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getProjectColor(int index) {
    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      const Color(0xFF00B8FF),
      const Color(0xFFFF6B35),
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
    ];
    return colors[index % colors.length];
  }
}

/// Card de projeto premium (movido para cá para funcionar com o import)
class ProjectCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? date;
  final int? trackCount;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? accentColor;

  const ProjectCard({
    super.key,
    required this.title,
    this.subtitle,
    this.date,
    this.trackCount,
    this.onTap,
    this.isSelected = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primary;
    
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isSelected ? color : AppTheme.surfaceHighlight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ] : AppTheme.shadowSm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Ícone/Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.folder_special_rounded,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (trackCount != null) ...[
                          _InfoChip(
                            icon: Icons.audiotrack_rounded,
                            label: '$trackCount tracks',
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (date != null)
                          _InfoChip(
                            icon: Icons.access_time_rounded,
                            label: date!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Seta
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighlight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textTertiary),
          const SizedBox(width: 4),
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
