// lib/presentation/widgets/real_waveform_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/utils/waveform_generator.dart';

/// Widget que carrega e exibe waveform real de um arquivo de áudio
class RealWaveformWidget extends StatefulWidget {
  final double progress;
  final Color accentColor;
  final String? trackId;
  final String? audioUrl;

  const RealWaveformWidget({
    super.key,
    required this.progress,
    required this.accentColor,
    this.trackId,
    this.audioUrl,
  });

  @override
  State<RealWaveformWidget> createState() => _RealWaveformWidgetState();
}

class _RealWaveformWidgetState extends State<RealWaveformWidget> {
  List<double>? _waveformData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWaveform();
  }

  @override
  void didUpdateWidget(RealWaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackId != widget.trackId || oldWidget.audioUrl != widget.audioUrl) {
      _loadWaveform();
    }
  }

  Future<void> _loadWaveform() async {
    if (widget.audioUrl == null) {
      setState(() {
        _waveformData = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final waveform = await WaveformGenerator.generateWaveform(
        audioUrl: widget.audioUrl!,
        samples: 80,
      );
      
      if (mounted) {
        setState(() {
          _waveformData = waveform;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[RealWaveform] Erro ao carregar waveform: $e');
      if (mounted) {
        setState(() {
          _waveformData = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 64,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final waveData = _waveformData;
    if (waveData == null || waveData.isEmpty) {
      // Fallback para waveform simulado
      return _buildFallbackWaveform();
    }

    return CustomPaint(
      size: const Size(double.infinity, 64),
      painter: _WaveformPainter(
        progress: widget.progress,
        accentColor: widget.accentColor,
        trackId: widget.trackId,
        waveformData: waveData,
      ),
    );
  }

  Widget _buildFallbackWaveform() {
    // Gerar waveform simulado baseado no trackId
    final fallbackData = _generateFallbackWaveform(widget.trackId ?? 'default');
    return CustomPaint(
      size: const Size(double.infinity, 64),
      painter: _WaveformPainter(
        progress: widget.progress,
        accentColor: widget.accentColor,
        trackId: widget.trackId,
        waveformData: fallbackData,
      ),
    );
  }

  List<double> _generateFallbackWaveform(String seed) {
    final hash = seed.hashCode;
    final random = _SeededRandom(hash);
    const count = 80;
    final data = <double>[];
    
    for (int i = 0; i < count; i++) {
      double value = 0.3 + random.next() * 0.4;
      if (i % 4 == 0) value = math.min(1.0, value + 0.2);
      data.add(value.clamp(0.1, 1.0));
    }
    
    return data;
  }
}

class _SeededRandom {
  int _seed;
  _SeededRandom(this._seed);
  
  double next() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return (_seed & 0x7fffffff) / 0x7fffffff;
  }
}

// Classe auxiliar para pintar o waveform
class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final String? trackId;
  final List<double> waveformData;

  _WaveformPainter({
    required this.progress,
    required this.accentColor,
    this.trackId,
    required this.waveformData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / waveformData.length;
    final centerY = size.height / 2;
    final maxHeight = size.height * 0.85;
    final progressX = size.width * progress;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final barHeight = waveformData[i] * maxHeight;
      final isPlayed = x <= progressX;

      final paint = Paint()..style = PaintingStyle.fill;

      if (isPlayed) {
        paint.shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [accentColor, accentColor.withOpacity(0.6)],
        ).createShader(Rect.fromLTWH(x - barWidth * 0.35, centerY - barHeight / 2, barWidth * 0.7, barHeight));
      } else {
        paint.color = Colors.white.withOpacity(0.12);
      }

      // Barra superior
      final topRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth * 0.35, centerY - barHeight / 2, barWidth * 0.7, barHeight / 2),
        const Radius.circular(2),
      );
      canvas.drawRRect(topRect, paint);

      // Barra inferior (espelhada)
      final bottomRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth * 0.35, centerY, barWidth * 0.7, barHeight / 2),
        const Radius.circular(2),
      );
      canvas.drawRRect(bottomRect, paint);
    }

    // Cursor
    if (progress > 0.005 && progress < 0.995) {
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(progressX, centerY - 16),
        Offset(progressX, centerY + 16),
        linePaint,
      );

      final cursorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(progressX, centerY), 5, cursorPaint);

      final glowPaint = Paint()
        ..color = accentColor.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(progressX, centerY), 8, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) {
    return progress != old.progress || 
           waveformData != old.waveformData ||
           trackId != old.trackId;
  }
}
