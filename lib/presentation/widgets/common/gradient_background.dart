// lib/presentation/widgets/common/gradient_background.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Background com gradiente e efeitos visuais
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool showPattern;
  final bool showGlow;

  const GradientBackground({
    super.key,
    required this.child,
    this.showPattern = true,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surface,
            Color(0xFF0A0A10),
            AppTheme.surface,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Padrão de grid sutil
          if (showPattern) const _GridPattern(),
          
          // Efeitos de glow
          if (showGlow) ...[
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.15),
                      AppTheme.primary.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.secondary.withOpacity(0.1),
                      AppTheme.secondary.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
          
          // Conteúdo
          child,
        ],
      ),
    );
  }
}

class _GridPattern extends StatelessWidget {
  const _GridPattern();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.03,
      child: CustomPaint(
        painter: _GridPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    const spacing = 40.0;

    // Linhas verticais
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Linhas horizontais
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Background com partículas animadas (para tela de login)
class ParticleBackground extends StatefulWidget {
  final Widget child;

  const ParticleBackground({super.key, required this.child});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _particles = List.generate(30, (_) => _Particle());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D0D12),
            Color(0xFF080810),
            Color(0xFF0D0D12),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Partículas
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _ParticlePainter(_particles, _controller.value),
                size: Size.infinite,
              );
            },
          ),
          
          // Glow effects
          Positioned(
            top: -200,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondary.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Conteúdo
          widget.child,
        ],
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble(),
        size = math.Random().nextDouble() * 3 + 1,
        speed = math.Random().nextDouble() * 0.5 + 0.2,
        opacity = math.Random().nextDouble() * 0.3 + 0.1;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = particle.x * size.width;
      final y = ((particle.y + animationValue * particle.speed) % 1.0) * size.height;
      
      final paint = Paint()
        ..color = AppTheme.primary.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

/// Visualizador de ondas de áudio (decorativo)
class AudioWaveBackground extends StatefulWidget {
  final Widget child;
  final bool isPlaying;

  const AudioWaveBackground({
    super.key,
    required this.child,
    this.isPlaying = false,
  });

  @override
  State<AudioWaveBackground> createState() => _AudioWaveBackgroundState();
}

class _AudioWaveBackgroundState extends State<AudioWaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant AudioWaveBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ondas de áudio no fundo
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _WavePainter(
                  _controller.value,
                  isAnimating: widget.isPlaying,
                ),
              );
            },
          ),
        ),
        // Conteúdo
        widget.child,
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final bool isAnimating;

  _WavePainter(this.animationValue, {this.isAnimating = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withOpacity(isAnimating ? 0.15 : 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final centerY = size.height * 0.8;
    
    path.moveTo(0, centerY);
    
    for (double x = 0; x <= size.width; x++) {
      final normalizedX = x / size.width;
      final amplitude = isAnimating ? 30.0 : 15.0;
      final y = centerY + 
          math.sin((normalizedX * 4 + animationValue * 2) * math.pi) * amplitude +
          math.sin((normalizedX * 8 + animationValue * 3) * math.pi) * (amplitude * 0.5);
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
    
    // Segunda onda com defasagem
    final path2 = Path();
    path2.moveTo(0, centerY);
    
    for (double x = 0; x <= size.width; x++) {
      final normalizedX = x / size.width;
      final amplitude = isAnimating ? 20.0 : 10.0;
      final y = centerY + 
          math.sin((normalizedX * 6 + animationValue * 2.5 + 1) * math.pi) * amplitude +
          math.sin((normalizedX * 10 + animationValue * 4) * math.pi) * (amplitude * 0.3);
      path2.lineTo(x, y);
    }
    
    paint.color = AppTheme.secondary.withOpacity(isAnimating ? 0.1 : 0.03);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => 
      oldDelegate.animationValue != animationValue || 
      oldDelegate.isAnimating != isAnimating;
}
