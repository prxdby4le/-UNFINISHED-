// lib/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_animations.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/common/gradient_background.dart';
import '../widgets/common/custom_input.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glass_card.dart';
import 'projects_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authRepo = AuthRepository();

      if (_isSignUp) {
        final signUpResponse = await authRepo.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
        );
        
        if (signUpResponse.user != null && signUpResponse.session == null) {
          if (mounted) {
            setState(() {
              _successMessage = 'Conta criada com sucesso! Verifique seu email para confirmar.';
              _isLoading = false;
            });
            return;
          }
        }
        
        if (signUpResponse.session != null) {
          if (mounted) {
            _navigateToProjects();
          }
          return;
        }
      } else {
        await authRepo.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (mounted) {
          _navigateToProjects();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _navigateToProjects() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            const ProjectsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticleBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo animado
                      FadeSlideIn(
                        duration: const Duration(milliseconds: 800),
                        offset: const Offset(0, -30),
                        child: _buildLogo(),
                      ),
                      const SizedBox(height: AppTheme.spacing2xl),
                      
                      // Card do formulário
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppTheme.spacingLg),
                          blur: 15,
                          opacity: 0.15,
                          borderColor: AppTheme.surfaceHighlight.withOpacity(0.3),
                          borderRadius: AppTheme.radiusXl,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Título
                              Text(
                                _isSignUp ? 'Criar Conta' : 'Entrar',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isSignUp 
                                    ? 'Junte-se ao coletivo' 
                                    : 'Bem-vindo de volta',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppTheme.spacingLg),
                              
                              // Campo Nome (apenas no signup)
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                child: _isSignUp
                                    ? Column(
                                        children: [
                                          CustomInput(
                                            controller: _nameController,
                                            label: 'Nome',
                                            hint: 'Seu nome artístico',
                                            prefixIcon: Icons.person_outline_rounded,
                                            textCapitalization: TextCapitalization.words,
                                          ),
                                          const SizedBox(height: AppTheme.spacingMd),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              
                              // Campo Email
                              CustomInput(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'seu@email.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Insira seu email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Email inválido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              
                              // Campo Senha
                              CustomInput(
                                controller: _passwordController,
                                label: 'Senha',
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Insira sua senha';
                                  }
                                  if (value.length < 6) {
                                    return 'Mínimo 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppTheme.spacingLg),
                              
                              // Mensagens de erro/sucesso
                              if (_errorMessage != null)
                                _buildMessage(
                                  _errorMessage!,
                                  isError: true,
                                ),
                              if (_successMessage != null)
                                _buildMessage(
                                  _successMessage!,
                                  isError: false,
                                ),
                              
                              // Botão principal
                              CustomButton(
                                label: _isSignUp ? 'Criar Conta' : 'Entrar',
                                onPressed: _isLoading ? null : _handleSubmit,
                                isLoading: _isLoading,
                                isExpanded: true,
                                size: ButtonSize.large,
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              
                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: AppTheme.surfaceHighlight,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingMd,
                                    ),
                                    child: Text(
                                      'ou',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textTertiary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: AppTheme.surfaceHighlight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              
                              // Toggle Sign In / Sign Up
                              CustomButton(
                                label: _isSignUp
                                    ? 'Já tenho uma conta'
                                    : 'Criar uma conta',
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isSignUp = !_isSignUp;
                                          _errorMessage = null;
                                          _successMessage = null;
                                        });
                                      },
                                variant: ButtonVariant.ghost,
                                isExpanded: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Footer
                      const SizedBox(height: AppTheme.spacingXl),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 400),
                        child: Text(
                          '© 2026 Trashtalk Records',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoAnimation.value,
          child: child,
        );
      },
      child: Column(
        children: [
          // Ícone com glow
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.headset_rounded,
              size: 48,
              color: AppTheme.surface,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          
          // Nome
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'TRASHTALK',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            'RECORDS',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              letterSpacing: 8,
              color: AppTheme.textTertiary,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String message, {required bool isError}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: (isError ? AppTheme.error : AppTheme.success).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: (isError ? AppTheme.error : AppTheme.success).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError 
                ? Icons.error_outline_rounded 
                : Icons.check_circle_outline_rounded,
            color: isError ? AppTheme.error : AppTheme.success,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isError ? AppTheme.error : AppTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
