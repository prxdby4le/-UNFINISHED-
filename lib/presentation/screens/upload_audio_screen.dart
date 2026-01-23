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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  bool _isMaster = false;
  String? _errorMessage;
  double _uploadProgress = 0;
  bool _isDragging = false;

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
        allowedExtensions: ['wav', 'flac', 'mp3', 'aiff', 'm4a'],
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          if (_nameController.text.isEmpty) {
            // Auto-fill name from file
            final fileName = _selectedFile!.name;
            final nameWithoutExt = fileName.split('.').first;
            _nameController.text = nameWithoutExt;
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick file: $e';
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      setState(() => _errorMessage = 'Please select a file first');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _uploadProgress = 0;
    });

    try {
      final audioRepo = AudioRepository();
      
      List<int>? fileBytes;
      if (kIsWeb) {
        fileBytes = _selectedFile!.bytes;
      } else {
        // Mobile/Desktop: use bytes if available
        fileBytes = _selectedFile!.bytes;
      }

      if (fileBytes == null) {
        throw Exception('Could not read file bytes');
      }

      await audioRepo.uploadAudioFromBytes(
        projectId: widget.projectId,
        fileBytes: fileBytes,
        fileName: _selectedFile!.name,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isMaster: _isMaster,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Upload successful!'),
            backgroundColor: const Color(0xFF1E1E1E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Upload failed: ${e.toString().split(':').last.trim()}';
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
          'Upload Audio',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File picker area with drag and drop
              DragTarget<Object>(
                onWillAcceptWithDetails: (details) {
                  setState(() => _isDragging = true);
                  return true;
                },
                onLeave: (data) {
                  setState(() => _isDragging = false);
                },
                onAcceptWithDetails: (details) {
                  setState(() => _isDragging = false);
                  // O drag and drop no Flutter Web precisa de tratamento especial
                  // Por enquanto, mostrar mensagem para usar o seletor de arquivos
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Use o botão para selecionar arquivos'),
                      backgroundColor: Color(0xFF1E1E1E),
                    ),
                  );
                },
                builder: (context, candidateData, rejectedData) {
                  return GestureDetector(
                    onTap: _isLoading ? null : _pickFile,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: _isDragging 
                            ? const Color(0xFFE91E8C).withOpacity(0.1)
                            : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isDragging
                              ? const Color(0xFFE91E8C)
                              : _selectedFile != null
                                  ? const Color(0xFFE91E8C).withOpacity(0.5)
                                  : Colors.white.withOpacity(0.1),
                          width: _isDragging || _selectedFile != null ? 2 : 1,
                          style: _isDragging ? BorderStyle.solid : BorderStyle.solid,
                        ),
                      ),
                      child: _selectedFile != null
                          ? _buildSelectedFile()
                          : _buildFilePlaceholder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Nome da versão
              const Text(
                'Version Name',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('e.g., Mix 1, Final Master...'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Descrição
              const Text(
                'Notes (Optional)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: _inputDecoration('Add notes about this version...'),
              ),
              const SizedBox(height: 24),
              
              // Master toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isMaster
                        ? const Color(0xFFFFD700).withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isMaster
                            ? const Color(0xFFFFD700).withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: _isMaster
                            ? const Color(0xFFFFD700)
                            : Colors.white38,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Master Version',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Mark as the final/master version',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isMaster,
                      onChanged: (value) => setState(() => _isMaster = value),
                      activeColor: const Color(0xFFFFD700),
                    ),
                  ],
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
              
              const SizedBox(height: 32),
              
              // Progress bar durante upload
              if (_isLoading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFE91E8C)),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Botão de upload
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleUpload,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.upload_rounded),
                  label: _isLoading
                      ? const Text('Uploading...')
                      : const Text('Upload'),
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
          _isDragging ? 'Solte o arquivo aqui' : 'Clique ou arraste um arquivo',
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

  Widget _buildSelectedFile() {
    final extension = _selectedFile!.name.split('.').last.toUpperCase();
    final isLossless = ['WAV', 'FLAC', 'AIFF'].contains(extension);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E8C), Color(0xFF9C27B0)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  extension,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Selected file',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    if (isLossless) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LOSSLESS',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedFile!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatFileSize(_selectedFile!.size),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // Remove button
          IconButton(
            onPressed: () => setState(() => _selectedFile = null),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE91E8C)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
