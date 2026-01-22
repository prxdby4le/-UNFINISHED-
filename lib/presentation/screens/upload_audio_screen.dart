// lib/presentation/screens/upload_audio_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_animations.dart';
import '../../data/repositories/audio_repository.dart';
import '../widgets/common/gradient_background.dart';
import '../widgets/common/custom_input.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glass_card.dart';

class UploadAudioScreen extends StatefulWidget {
  final String projectId;

  const UploadAudioScreen({super.key, required this.projectId});

  @override
  State<UploadAudioScreen> createState() => _UploadAudioScreenState();
}

class _UploadAudioScreenState extends State<UploadAudioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  bool _isMaster = false;
  double _uploadProgress = 0;
  String? _errorMessage;

  final List<String> _allowedExtensions = ['wav', 'flac', 'mp3', 'aiff', 'm4a'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        setState(() {
          _selectedFile = file;
          _errorMessage = null;
          
          // Preencher nome automaticamente se vazio
          if (_nameController.text.isEmpty) {
            final nameWithoutExt = file.name.replaceAll(
              RegExp(r'\.(wav|flac|mp3|aiff|m4a)$', caseSensitive: false),
              '',
            );
            _nameController.text = nameWithoutExt;
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao selecionar arquivo: $e';
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      setState(() => _errorMessage = 'Selecione um arquivo de áudio');
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
      _errorMessage = null;
    });

    try {
      final audioRepo = AudioRepository();
      
      // Simular progresso de upload
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() => _uploadProgress = (i + 1) * 0.15);
        }
      }

      await audioRepo.uploadAudioFromBytes(
        projectId: widget.projectId,
        fileName: _selectedFile!.name,
        fileBytes: _selectedFile!.bytes!.toList(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        isMaster: _isMaster,
      );

      if (mounted) {
        setState(() => _uploadProgress = 1.0);
        await Future.delayed(const Duration(milliseconds: 500));
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.success),
                const SizedBox(width: 12),
                const Text('Upload realizado com sucesso!'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro no upload: $e';
          _isLoading = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconBtn(
          icon: Icons.close_rounded,
          onPressed: () => Navigator.pop(context),
          size: 44,
        ),
        title: Text(
          'Upload de Áudio',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.spacingMd),
                  
                  // Área de seleção de arquivo
                  FadeSlideIn(
                    child: _buildFileSelector(),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  
                  // Informações do arquivo selecionado
                  if (_selectedFile != null)
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: _buildFileInfo(),
                    ),
                  
                  const SizedBox(height: AppTheme.spacingLg),
                  
                  // Campo nome
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: CustomInput(
                      controller: _nameController,
                      label: 'Nome da Versão',
                      hint: 'Ex: Mix Final, Master V2',
                      prefixIcon: Icons.label_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite um nome para a versão';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  
                  // Campo descrição
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: CustomInput(
                      controller: _descriptionController,
                      label: 'Descrição (opcional)',
                      hint: 'Notas sobre esta versão...',
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  
                  // Toggle Master
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 400),
                    child: _buildMasterToggle(),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  
                  // Mensagem de erro
                  if (_errorMessage != null)
                    FadeSlideIn(
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: AppTheme.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Barra de progresso
                  if (_isLoading)
                    FadeSlideIn(
                      child: _buildProgressIndicator(),
                    ),
                  
                  const SizedBox(height: AppTheme.spacingLg),
                  
                  // Botão upload
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 500),
                    child: CustomButton(
                      label: _isLoading ? 'Enviando...' : 'Fazer Upload',
                      onPressed: (_isLoading || _selectedFile == null) 
                          ? null 
                          : _handleUpload,
                      isLoading: _isLoading,
                      isExpanded: true,
                      size: ButtonSize.large,
                      icon: Icons.cloud_upload_rounded,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLg),
                  
                  // Formatos suportados
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 600),
                    child: _buildSupportedFormats(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileSelector() {
    return ScaleOnTap(
      onTap: _isLoading ? null : _pickFile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 180,
        decoration: BoxDecoration(
          color: _selectedFile != null
              ? AppTheme.primary.withOpacity(0.1)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: _selectedFile != null
                ? AppTheme.primary.withOpacity(0.5)
                : AppTheme.surfaceHighlight,
            width: 2,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        child: _selectedFile != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: AppTheme.glowPrimary,
                    ),
                    child: const Icon(
                      Icons.audiotrack_rounded,
                      size: 32,
                      color: AppTheme.surface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFile!.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toque para alterar',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHighlight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 32,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selecionar arquivo de áudio',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'WAV, FLAC, MP3, AIFF, M4A',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFileInfo() {
    final sizeInMB = (_selectedFile!.size / (1024 * 1024)).toStringAsFixed(1);
    final extension = _selectedFile!.extension?.toUpperCase() ?? 'N/A';
    
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceHighlight,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Center(
              child: Text(
                extension,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arquivo selecionado',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
                Text(
                  '$sizeInMB MB',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          IconBtn(
            icon: Icons.close_rounded,
            onPressed: () => setState(() => _selectedFile = null),
            size: 36,
            color: AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildMasterToggle() {
    return ScaleOnTap(
      onTap: () => setState(() => _isMaster = !_isMaster),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: _isMaster 
              ? AppTheme.gold.withOpacity(0.1) 
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: _isMaster 
                ? AppTheme.gold.withOpacity(0.5) 
                : AppTheme.surfaceHighlight,
            width: _isMaster ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isMaster 
                    ? AppTheme.gold 
                    : AppTheme.surfaceHighlight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_rounded,
                color: _isMaster ? Colors.black87 : AppTheme.textTertiary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Versão Master',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _isMaster ? AppTheme.gold : null,
                    ),
                  ),
                  Text(
                    'Marcar como versão final/principal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: _isMaster ? AppTheme.gold : AppTheme.surfaceHighlight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _isMaster 
                    ? Alignment.centerRight 
                    : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _isMaster ? Colors.black87 : AppTheme.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enviando...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: AppTheme.surfaceHighlight,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedFormats() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighlight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                'Formatos suportados',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FormatChip(label: 'WAV', isLossless: true),
              _FormatChip(label: 'FLAC', isLossless: true),
              _FormatChip(label: 'AIFF', isLossless: true),
              _FormatChip(label: 'MP3', isLossless: false),
              _FormatChip(label: 'M4A', isLossless: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final bool isLossless;

  const _FormatChip({required this.label, required this.isLossless});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isLossless 
            ? AppTheme.success.withOpacity(0.1) 
            : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isLossless 
              ? AppTheme.success.withOpacity(0.3) 
              : AppTheme.surfaceHighlight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isLossless ? AppTheme.success : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isLossless) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.check_circle_rounded,
              size: 12,
              color: AppTheme.success,
            ),
          ],
        ],
      ),
    );
  }
}
