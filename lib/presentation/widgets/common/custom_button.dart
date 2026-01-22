// lib/presentation/widgets/common/custom_button.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_animations.dart';

enum ButtonVariant { primary, secondary, outline, ghost }
enum ButtonSize { small, medium, large }

/// Botão customizado com várias variantes
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final Color? color;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppTheme.primary;
    
    // Dimensões baseadas no tamanho
    final (double height, double fontSize, double iconSize, EdgeInsets padding) = switch (size) {
      ButtonSize.small => (36.0, 12.0, 16.0, const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      ButtonSize.medium => (48.0, 14.0, 20.0, const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
      ButtonSize.large => (56.0, 16.0, 24.0, const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
    };
    
    // Estilos baseados na variante
    final (Color bgColor, Color fgColor, Border? border, List<BoxShadow>? shadow) = switch (variant) {
      ButtonVariant.primary => (
        buttonColor,
        AppTheme.surface,
        null,
        [BoxShadow(color: buttonColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      ButtonVariant.secondary => (
        buttonColor.withOpacity(0.15),
        buttonColor,
        Border.all(color: buttonColor.withOpacity(0.3)),
        null,
      ),
      ButtonVariant.outline => (
        Colors.transparent,
        buttonColor,
        Border.all(color: buttonColor, width: 1.5),
        null,
      ),
      ButtonVariant.ghost => (
        Colors.transparent,
        buttonColor,
        null,
        null,
      ),
    };

    Widget buttonContent = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fgColor,
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: fgColor),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: fgColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

    return ScaleOnTap(
      onTap: (isLoading || onPressed == null) ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: onPressed == null ? bgColor.withOpacity(0.5) : bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: border,
          boxShadow: onPressed == null ? null : shadow,
        ),
        child: buttonContent,
      ),
    );
  }
}

/// Botão circular com ícone
class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final bool showGlow;
  final String? tooltip;

  const IconBtn({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 48,
    this.showGlow = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppTheme.textPrimary;
    final bgColor = backgroundColor ?? AppTheme.surfaceHighlight;
    
    Widget button = ScaleOnTap(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: showGlow ? [
            BoxShadow(
              color: iconColor.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ] : null,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: size * 0.5,
        ),
      ),
    );
    
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    
    return button;
  }
}

/// Botão de play grande com gradiente
class PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onPressed;
  final double size;

  const PlayButton({
    super.key,
    required this.isPlaying,
    this.onPressed,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: AppTheme.glowPrimary,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: AppTheme.surface,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// FAB customizado com gradiente
class GradientFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool mini;

  const GradientFab({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = mini ? 48.0 : 56.0;
    
    Widget fab = ScaleOnTap(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.glowPrimary,
        ),
        child: Icon(
          icon,
          color: AppTheme.surface,
          size: mini ? 24 : 28,
        ),
      ),
    );
    
    if (tooltip != null) {
      fab = Tooltip(message: tooltip!, child: fab);
    }
    
    return fab;
  }
}
