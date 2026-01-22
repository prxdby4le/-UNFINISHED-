// lib/presentation/screens/create_project_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_animations.dart';
import '../providers/project_provider.dart';
import '../widgets/common/gradient_background.dart';
import '../widgets/common/custom_input.dart';
import '../widgets/common/custom_button.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  int _selectedColorIndex = 0;

  final List<Color> _projectColors = [
    AppTheme.primary,
    AppTheme.secondary,
    const Color(0xFF00B8FF),
    const Color(0xFFFF6B35),
    const Color(0xFF9B59B6),
    const Color(0xFF1ABC9C),
    const Color(0xFFE74C3C),
    const Color(0xFF3498DB),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<ProjectProvider>().createProject(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.success),
                const SizedBox(width: 12),
                const Text('Projeto criado com sucesso!'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar projeto: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
        setState(() => _isLoading = false);
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
          'Novo Projeto',
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
                  
                  // Ícone do projeto (preview)
                  FadeSlideIn(
                    child: Center(
                      child: _buildProjectPreview(),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2xl),
                  
                  // Seletor de cor
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cor do Projeto',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        _buildColorSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  
                  // Campo nome
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: CustomInput(
                      controller: _nameController,
                      label: 'Nome do Projeto',
                      hint: 'Ex: EP Summer 2026',
                      prefixIcon: Icons.folder_rounded,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite um nome para o projeto';
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
                      hint: 'Adicione detalhes sobre o projeto...',
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2xl),
                  
                  // Botão criar
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 400),
                    child: CustomButton(
                      label: 'Criar Projeto',
                      onPressed: _isLoading ? null : _createProject,
                      isLoading: _isLoading,
                      isExpanded: true,
                      size: ButtonSize.large,
                      icon: Icons.add_rounded,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  
                  // Dica
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHighlight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.surfaceHighlight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Após criar o projeto, você poderá fazer upload de versões de áudio.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectPreview() {
    final color = _projectColors[_selectedColorIndex];
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Icon(
        Icons.folder_special_rounded,
        size: 56,
        color: color,
      ),
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(_projectColors.length, (index) {
        final color = _projectColors[index];
        final isSelected = _selectedColorIndex == index;
        
        return ScaleOnTap(
          onTap: () => setState(() => _selectedColorIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ] : null,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 24,
                  )
                : null,
          ),
        );
      }),
    );
  }
}
