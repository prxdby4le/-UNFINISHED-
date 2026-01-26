// lib/presentation/screens/project_detail_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/audio_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/feedback_repository.dart';
import '../../data/models/project.dart';
import '../../data/models/audio_version.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/feedback_list_widget.dart' show FeedbackListWidget, FeedbackListWidgetState;
import '../widgets/feedback_form_widget.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/empty_state_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:typed_data';
import '../widgets/edit_version_modal.dart';
import '../widgets/edit_project_modal.dart';
import '../widgets/authenticated_image.dart';
import '../../data/repositories/image_repository.dart';
import '../../core/utils/color_extractor.dart';
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
  final _imageRepo = ImageRepository();
  
  // Cor dinâmica baseada na capa
  Color _dominantColor = const Color(0xFF1E88E5);
  String? _coverImageUrl; // URL assinada da capa
  
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

  Future<void> _loadData({bool preserveCoverUrl = false}) async {
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
        });
        
        // Obter URL do proxy para a capa (evita CORS) e extrair cores
        if (_project?.coverImageUrl != null) {
          String? proxyUrl;
          if (!_project!.coverImageUrl!.startsWith('http')) {
            // Usar proxy diretamente (evita CORS)
            proxyUrl = _imageRepo.getProxyImageUrl(_project!.coverImageUrl!);
          } else {
            proxyUrl = _project!.coverImageUrl;
          }
          
          if (mounted && proxyUrl != null) {
            setState(() {
              _coverImageUrl = proxyUrl;
            });
            
            // Extrair cor dominante da capa
            _extractColorFromCover(proxyUrl);
          }
        } else {
          if (mounted) {
            setState(() {
              _coverImageUrl = null;
            });
          }
        }
        
        _colorController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Extrai cor dominante da capa do projeto
  Future<void> _extractColorFromCover(String imageUrl) async {
    try {
      final color = await ColorExtractor.extractDominantColor(imageUrl);
      if (mounted) {
        setState(() {
          _dominantColor = color;
        });
        _colorController.forward(from: 0.0);
      }
    } catch (e) {
      debugPrint('[ProjectDetail] Erro ao extrair cor: $e');
      // Fallback para cor baseada no nome
      if (mounted) {
        setState(() {
          _dominantColor = _generateProjectColor(_project?.name ?? '');
        });
      }
    }
  }

  // Gera uma cor única baseada no nome do projeto (fallback)
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
        body: LoadingWidget(
          message: 'Carregando projeto...',
          color: _dominantColor,
        ),
      );
    }

    if (_project == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ErrorDisplayWidget(
          title: 'Projeto não encontrado',
          message: 'O projeto que você está procurando não existe ou foi removido.',
          onRetry: () {
            Navigator.pop(context);
          },
          retryLabel: 'Voltar',
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
          RefreshIndicator(
            onRefresh: _loadData,
            color: _dominantColor,
            backgroundColor: const Color(0xFF1A1A1F),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
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
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          onPressed: () => _showProjectOptions(),
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
                    child: _coverImageUrl != null
                        ? AuthenticatedImage(
                            imageUrl: _coverImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: _buildPlaceholderCover(),
                            errorWidget: _buildPlaceholderCover(),
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
                onPressed: () {
                  if (_versions.isNotEmpty) {
                    _downloadVersion(_versions[0]);
                  }
                },
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
      return EmptyStateWidget(
        title: 'Nenhuma faixa ainda',
        message: 'Adicione sua primeira faixa para começar',
        icon: Icons.music_off_outlined,
        iconColor: _dominantColor,
        action: ElevatedButton.icon(
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
        
        // Botão de adicionar faixa (sempre visível)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton.icon(
            onPressed: () => _navigateToUpload(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar faixa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _dominantColor,
              side: BorderSide(color: _dominantColor.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
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
              onComments: () => _showFeedbackModal(context, version),
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

  void _showFeedbackModal(BuildContext context, AudioVersion version) {
    final playerProvider = context.read<AudioPlayerProvider>();
    // Usar GlobalKey para acessar o state do widget
    final feedbackListKey = GlobalKey<FeedbackListWidgetState>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    color: _dominantColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comentários',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          version.name,
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
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF2A2A2F)),
            // Lista de comentários
            Expanded(
              child: FeedbackListWidget(
                key: feedbackListKey,
                audioVersionId: version.id,
                onCountChanged: (count) {
                  // Atualizar contagem se necessário
                },
              ),
            ),
            // Formulário de comentário
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1F),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: StreamBuilder<Duration>(
                stream: playerProvider.getCurrentVersion()?.id == version.id
                    ? playerProvider.positionStream
                    : null,
                builder: (context, snapshot) {
                  final timestamp = snapshot.data?.inSeconds;
                  return FeedbackFormWidget(
                    audioVersionId: version.id,
                    currentTimestamp: timestamp,
                    onSubmitted: () {
                      // Recarregar lista de comentários
                      feedbackListKey.currentState?.reload();
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
    // Redirecionar para o novo método de opções do projeto
    _showProjectOptions();
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
            leading: Icon(Icons.comment_outlined, color: _dominantColor),
            title: const Text('Comentários', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showFeedbackModal(context, version);
            },
          ),
          ListTile(
            leading: Icon(Icons.edit_outlined, color: _dominantColor),
            title: const Text('Editar', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _editVersion(version);
            },
          ),
          ListTile(
            leading: Icon(Icons.download_outlined, color: _dominantColor),
            title: const Text('Baixar', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _downloadVersion(version);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              _deleteVersion(version);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _editVersion(AudioVersion version) async {
    await showDialog(
      context: context,
      builder: (context) => EditVersionModal(
        version: version,
        onUpdated: () {
          _loadData();
        },
      ),
    );
  }

  Future<void> _deleteVersion(AudioVersion version) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1F),
        title: const Text(
          'Excluir Versão',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Tem certeza que deseja excluir "${version.name}"?\n\n'
          'Esta ação não pode ser desfeita.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = AudioRepository();
      await repository.deleteVersion(version.id);
      
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Versão "${version.name}" excluída'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProjectOptions() {
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
          if (_project != null) ...[
            ListTile(
              leading: Icon(Icons.edit_outlined, color: _dominantColor),
              title: const Text('Editar Projeto', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _editProject();
              },
            ),
            ListTile(
              leading: Icon(Icons.image_outlined, color: _dominantColor),
              title: const Text('Mudar Capa', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _changeCover();
              },
            ),
            ListTile(
              leading: Icon(
                _project!.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                color: _dominantColor,
              ),
              title: Text(
                _project!.isArchived ? 'Desarquivar' : 'Arquivar',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleArchive();
              },
            ),
            const Divider(color: Color(0xFF2A2A2F)),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _editProject() async {
    if (_project == null) return;
    
    await showDialog(
      context: context,
      builder: (context) => EditProjectModal(
        project: _project!,
        onUpdated: () {
          _loadData();
        },
      ),
    );
  }

  Future<void> _changeCover() async {
    if (_project == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: kIsWeb, // No web, precisamos dos bytes diretamente
      );

      if (result != null && result.files.single.size > 0) {
        Uint8List bytes;
        String fileName;
        
        if (kIsWeb) {
          // No web, usar bytes diretamente
          bytes = result.files.single.bytes!;
          fileName = result.files.single.name;
        } else {
          // Em mobile/desktop, usar path
          if (result.files.single.path == null) {
            throw Exception('Caminho do arquivo não disponível');
          }
          final file = File(result.files.single.path!);
          bytes = await file.readAsBytes();
          fileName = file.path.split('/').last;
        }
        
        setState(() {
          _isLoading = true;
        });

        try {
          final imageRepo = ImageRepository();
          final coverImageUrl = await imageRepo.uploadImage(
            imageBytes: bytes,
            fileName: fileName,
            folder: 'covers',
          );

          final projectRepo = ProjectRepository();
          final updatedProject = await projectRepo.updateProject(
            id: _project!.id,
            coverImageUrl: coverImageUrl,
          );

          if (mounted) {
            // Atualizar o projeto localmente primeiro
            setState(() {
              _project = updatedProject;
              _coverImageUrl = null; // Limpar URL antiga para forçar reload
            });
            
            // Obter URL do proxy para a nova capa (evita CORS)
            try {
              debugPrint('[ChangeCover] Obtendo URL do proxy para: $coverImageUrl');
              final proxyUrl = _imageRepo.getProxyImageUrl(coverImageUrl);
              debugPrint('[ChangeCover] URL do proxy: $proxyUrl');
              
              if (mounted) {
                setState(() {
                  _coverImageUrl = proxyUrl;
                });
                debugPrint('[ChangeCover] Estado atualizado com nova URL do proxy');
                
                // Extrair cor dominante da nova capa
                _extractColorFromCover(proxyUrl);
              }
            } catch (e) {
              debugPrint('[ChangeCover] Erro ao obter URL do proxy: $e');
              // Se falhar, tentar usar a URL diretamente (pode ser que já seja uma URL completa)
              if (mounted) {
                setState(() {
                  _coverImageUrl = coverImageUrl.startsWith('http') 
                      ? coverImageUrl 
                      : null;
                });
              }
            }
            
            // Recarregar dados para garantir sincronização (preservando a URL assinada)
            // Fazer isso de forma assíncrona para não bloquear a UI
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _loadData(preserveCoverUrl: true);
              }
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Capa atualizada com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao fazer upload: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadVersion(AudioVersion version) async {
    try {
      // Obter URL assinada
      final repository = AudioRepository();
      final signedUrl = await repository.getSignedUrl(version.fileUrl);
      
      // Abrir URL no navegador para download
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download iniciado: ${version.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Não foi possível abrir a URL de download');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao baixar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleArchive() async {
    if (_project == null) return;

    final isArchiving = !_project!.isArchived;
    final action = isArchiving ? 'arquivar' : 'desarquivar';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1F),
        title: Text(
          isArchiving ? 'Arquivar Projeto' : 'Desarquivar Projeto',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Tem certeza que deseja $action "${_project!.name}"?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action, style: const TextStyle(color: Color(0xFF1E88E5))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ProjectRepository();
      await repository.updateProject(
        id: _project!.id,
        isArchived: isArchiving,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Projeto ${isArchiving ? 'arquivado' : 'desarquivado'} com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Voltar para lista de projetos
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao $action: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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

class _TrackTile extends StatefulWidget {
  final int index;
  final AudioVersion version;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onMore;
  final VoidCallback onComments;

  const _TrackTile({
    required this.index,
    required this.version,
    required this.accentColor,
    required this.onTap,
    required this.onMore,
    required this.onComments,
  });

  @override
  State<_TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<_TrackTile> {
  int _commentCount = 0;
  bool _isLoadingCount = true;
  final _feedbackRepo = FeedbackRepository();

  @override
  void initState() {
    super.initState();
    _loadCommentCount();
  }

  Future<void> _loadCommentCount() async {
    try {
      final count = await _feedbackRepo.getFeedbackCount(widget.version.id);
      if (mounted) {
        setState(() {
          _commentCount = count;
          _isLoadingCount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCount = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<AudioPlayerProvider>();
    final currentVersion = playerProvider.getCurrentVersion();
    final isPlaying = currentVersion?.id == widget.version.id && playerProvider.isPlaying;
    final isCurrentTrack = currentVersion?.id == widget.version.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              // Número ou animação
              SizedBox(
                width: 32,
                child: isPlaying
                    ? _PlayingAnimation(color: widget.accentColor)
                    : Text(
                        '${widget.index}',
                        style: TextStyle(
                          color: isCurrentTrack ? widget.accentColor : Colors.white.withOpacity(0.5),
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
                      widget.version.name,
                      style: TextStyle(
                        color: isCurrentTrack ? widget.accentColor : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (_isLossless(widget.version.format)) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LOSSLESS',
                              style: TextStyle(
                                color: widget.accentColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          widget.version.format?.toUpperCase() ?? 'WAV',
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
              
              // Botão de comentários (se houver)
              if (_commentCount > 0 || _isLoadingCount) ...[
                GestureDetector(
                  onTap: widget.onComments,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 14,
                          color: widget.accentColor,
                        ),
                        const SizedBox(width: 4),
                        _isLoadingCount
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                                ),
                              )
                            : Text(
                                '$_commentCount',
                                style: TextStyle(
                                  color: widget.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              // Duração
              Text(
                widget.version.formattedDuration,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              
              // Menu
              IconButton(
                icon: Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.5), size: 20),
                onPressed: widget.onMore,
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

// Widget para o conteúdo do modal de feedback
class _FeedbackModalContent extends StatefulWidget {
  final AudioVersion version;
  final Color accentColor;
  final AudioPlayerProvider playerProvider;
  
  const _FeedbackModalContent({
    required this.version,
    required this.accentColor,
    required this.playerProvider,
  });
  
  @override
  State<_FeedbackModalContent> createState() => _FeedbackModalContentState();
}

class _FeedbackModalContentState extends State<_FeedbackModalContent> {
  final _listKey = GlobalKey<FeedbackListWidgetState>();
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  color: widget.accentColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comentários',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.version.name,
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
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A2F)),
          // Lista de comentários
          Expanded(
            child: FeedbackListWidget(
              key: _listKey,
              audioVersionId: widget.version.id,
              onCountChanged: (count) {
                // Atualizar contagem se necessário
              },
            ),
          ),
          // Formulário de comentário
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: StreamBuilder<Duration>(
              stream: widget.playerProvider.getCurrentVersion()?.id == widget.version.id
                  ? widget.playerProvider.positionStream
                  : null,
              builder: (context, snapshot) {
                final timestamp = snapshot.data?.inSeconds;
                return FeedbackFormWidget(
                  audioVersionId: widget.version.id,
                  currentTimestamp: timestamp,
                  onSubmitted: () {
                    // Recarregar lista de comentários
                    _listKey.currentState?.reload();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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
