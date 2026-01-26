// lib/presentation/widgets/feedback_list_widget.dart
import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../data/repositories/feedback_repository.dart';
import '../../data/models/feedback.dart' as models;

class FeedbackListWidget extends StatefulWidget {
  final String audioVersionId;
  final Function(int)? onCountChanged;
  
  const FeedbackListWidget({
    super.key,
    required this.audioVersionId,
    this.onCountChanged,
  });
  
  @override
  State<FeedbackListWidget> createState() => FeedbackListWidgetState();
}

// Expor state para permitir reload externo
class FeedbackListWidgetState extends State<FeedbackListWidget> {
  final _repository = FeedbackRepository();
  List<models.Feedback> _feedback = [];
  bool _isLoading = true;
  String? _error;
  
  // Método público para recarregar
  void reload() {
    _loadFeedback();
  }
  
  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }
  
  Future<void> _loadFeedback() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final feedback = await _repository.getFeedbackByVersion(widget.audioVersionId);
      if (mounted) {
        setState(() {
          _feedback = feedback;
          _isLoading = false;
        });
        widget.onCountChanged?.call(feedback.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar comentários: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_feedback.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _loadFeedback,
      color: Theme.of(context).primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _feedback.length,
        itemBuilder: (context, index) {
          return _FeedbackItem(
            feedback: _feedback[index],
            onDeleted: () => _loadFeedback(),
            onUpdated: () => _loadFeedback(),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum comentário ainda',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seja o primeiro a comentar!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFeedback,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackItem extends StatelessWidget {
  final models.Feedback feedback;
  final VoidCallback onDeleted;
  final VoidCallback onUpdated;
  
  const _FeedbackItem({
    required this.feedback,
    required this.onDeleted,
    required this.onUpdated,
  });
  
  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
    final isOwnComment = feedback.isOwnComment(currentUserId);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com autor e ações
            Row(
              children: [
                // Avatar ou inicial
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.3),
                  child: Text(
                    feedback.authorName?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Nome e data
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback.authorName ?? 'Usuário',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        feedback.formattedRelativeDate,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botões de ação (se for próprio comentário)
                if (isOwnComment) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showEditDialog(context),
                    color: Colors.white.withOpacity(0.6),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () => _showDeleteDialog(context),
                    color: Colors.red.withOpacity(0.7),
                    tooltip: 'Deletar',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Conteúdo do comentário
            Text(
              feedback.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            // Timestamp (se houver)
            if (feedback.formattedTimestamp != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '@ ${feedback.formattedTimestamp}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: feedback.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Editar Comentário',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Escreva seu comentário...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comentário não pode estar vazio')),
                );
                return;
              }
              
              try {
                final repository = FeedbackRepository();
                await repository.updateFeedback(
                  id: feedback.id,
                  content: controller.text.trim(),
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  onUpdated();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comentário atualizado!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Deletar Comentário',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tem certeza que deseja deletar este comentário? Esta ação não pode ser desfeita.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = FeedbackRepository();
                await repository.deleteFeedback(feedback.id);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  onDeleted();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comentário deletado!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }
}
