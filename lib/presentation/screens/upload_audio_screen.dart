// lib/presentation/screens/upload_audio_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/repositories/audio_repository.dart';

class UploadAudioScreen extends StatefulWidget {
  final String projectId;

  const UploadAudioScreen({super.key, required this.projectId});

  @override
  State<UploadAudioScreen> createState() => _UploadAudioScreenState();
}

class _UploadAudioScreenState extends State<UploadAudioScreen> {
  List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, double> _uploadProgress = {}; // fileName -> progress
  Map<String, bool> _uploadStatus = {}; // fileName -> isCompleted
  bool _isDragging = false;

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wav', 'flac', 'mp3', 'aiff', 'm4a'],
        allowMultiple: true, // Permitir múltiplos arquivos
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result.files);
          // Inicializar progresso para novos arquivos
          for (var file in result.files) {
            _uploadProgress[file.name] = 0.0;
            _uploadStatus[file.name] = false;
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao selecionar arquivos: $e';
      });
    }
  }

  void _removeFile(PlatformFile file) {
    setState(() {
      _selectedFiles.remove(file);
      _uploadProgress.remove(file.name);
      _uploadStatus.remove(file.name);
    });
  }

  Future<void> _handleUpload() async {
    if (_selectedFiles.isEmpty) {
      setState(() => _errorMessage = 'Selecione pelo menos um arquivo');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Resetar progresso
      for (var file in _selectedFiles) {
        _uploadProgress[file.name] = 0.0;
        _uploadStatus[file.name] = false;
      }
    });

    try {
      final audioRepo = AudioRepository();
      int successCount = 0;
      int failCount = 0;

      // Upload de cada arquivo
      for (var file in _selectedFiles) {
        try {
          List<int>? fileBytes = file.bytes;
          
          if (fileBytes == null) {
            throw Exception('Não foi possível ler os bytes do arquivo');
          }

          // Usar nome do arquivo (sem extensão) como nome da versão
          final fileName = file.name;
          final nameWithoutExt = fileName.split('.').first;

          await audioRepo.uploadAudioFromBytes(
            projectId: widget.projectId,
            fileBytes: fileBytes,
            fileName: fileName,
            name: nameWithoutExt, // Nome padrão baseado no arquivo
            description: null, // Sem descrição inicial - pode editar depois
            isMaster: false, // Não marcar como master por padrão - pode editar depois
            onProgress: (progress) {
              if (mounted) {
                setState(() {
                  _uploadProgress[file.name] = progress;
                });
              }
            },
          );

          if (mounted) {
            setState(() {
              _uploadStatus[file.name] = true;
              _uploadProgress[file.name] = 1.0;
            });
          }
          successCount++;
        } catch (e) {
          debugPrint('Erro ao fazer upload de ${file.name}: $e');
          failCount++;
          if (mounted) {
            setState(() {
              _uploadStatus[file.name] = false;
            });
          }
        }
      }

      if (mounted) {
        _isLoading = false;
        
        if (successCount > 0) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                failCount > 0
                    ? '$successCount arquivo(s) enviado(s). $failCount falhou(ram).'
                    : '$successCount arquivo(s) enviado(s) com sucesso!',
              ),
              backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Falha ao enviar todos os arquivos';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro no upload: ${e.toString().split(':').last.trim()}';
          _isLoading = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white70),
        ),
        title: const Text(
          'Upload de Áudio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info sobre edição posterior
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.withOpacity(0.8), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Você pode editar nome, descrição e marcar como master depois do upload',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // File picker area
            GestureDetector(
              onTap: _isLoading ? null : _pickFiles,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: _selectedFiles.isEmpty ? 180 : null,
                padding: _selectedFiles.isEmpty ? null : const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDragging 
                      ? const Color(0xFFE91E8C).withOpacity(0.1)
                      : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isDragging
                        ? const Color(0xFFE91E8C)
                        : _selectedFiles.isNotEmpty
                            ? const Color(0xFFE91E8C).withOpacity(0.5)
                            : Colors.white.withOpacity(0.1),
                    width: _isDragging || _selectedFiles.isNotEmpty ? 2 : 1,
                  ),
                ),
                child: _selectedFiles.isEmpty
                    ? _buildFilePlaceholder()
                    : _buildSelectedFilesList(),
              ),
            ),
            
            // Erro
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Botão de upload
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || _selectedFiles.isEmpty) ? null : _handleUpload,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.upload_rounded),
                label: _isLoading
                    ? Text('Enviando ${_selectedFiles.length} arquivo(s)...')
                    : Text('Enviar ${_selectedFiles.length} arquivo(s)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E8C),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE91E8C).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Formatos suportados
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: ['WAV', 'FLAC', 'MP3', 'AIFF', 'M4A'].map((format) {
                  final isLossless = ['WAV', 'FLAC', 'AIFF'].contains(format);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLossless
                          ? const Color(0xFFE91E8C).withOpacity(0.1)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isLossless
                            ? const Color(0xFFE91E8C).withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      format,
                      style: TextStyle(
                        color: isLossless
                            ? const Color(0xFFE91E8C)
                            : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE91E8C).withOpacity(0.2),
                const Color(0xFFE91E8C).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _isDragging ? Icons.file_download_rounded : Icons.audio_file_rounded,
            color: const Color(0xFFE91E8C),
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isDragging ? 'Solte os arquivos aqui' : 'Clique para selecionar arquivos',
          style: TextStyle(
            color: _isDragging ? const Color(0xFFE91E8C) : Colors.white70,
            fontSize: 15,
            fontWeight: _isDragging ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.high_quality_rounded,
                size: 14,
                color: Colors.white.withOpacity(0.4),
              ),
              const SizedBox(width: 6),
              Text(
                'WAV • FLAC • MP3 • AIFF • M4A',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFilesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_selectedFiles.length} arquivo(s) selecionado(s)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _isLoading ? null : _pickFiles,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Adicionar mais'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE91E8C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._selectedFiles.map((file) => _buildFileItem(file)),
      ],
    );
  }

  Widget _buildFileItem(PlatformFile file) {
    final extension = file.name.split('.').last.toUpperCase();
    final isLossless = ['WAV', 'FLAC', 'AIFF'].contains(extension);
    final progress = _uploadProgress[file.name] ?? 0.0;
    final isCompleted = _uploadStatus[file.name] ?? false;
    final isUploading = _isLoading && !isCompleted && progress < 1.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E8C), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    extension,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            file.name,
                            style: TextStyle(
                              color: isCompleted ? Colors.green : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLossless) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LOSSLESS',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFileSize(file.size),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status/Remove button
              if (isCompleted)
                const Icon(Icons.check_circle, color: Colors.green, size: 24)
              else
                IconButton(
                  onPressed: _isLoading ? null : () => _removeFile(file),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withOpacity(0.4),
                    size: 20,
                  ),
                ),
            ],
          ),
          
          // Progress bar
          if (isUploading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFE91E8C)),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
