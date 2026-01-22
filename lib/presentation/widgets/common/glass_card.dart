// lib/presentation/widgets/common/glass_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_animations.dart';

/// Card com efeito glassmorphism
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool showGlow;
  final Color? glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderColor,
    this.borderRadius = AppTheme.radiusMd,
    this.onTap,
    this.showGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppTheme.surfaceHighlight.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: showGlow && glowColor != null
                ? [
                    BoxShadow(
                      color: glowColor!.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      card = ScaleOnTap(onTap: onTap, child: card);
    }

    return card;
  }
}

/// Card de projeto com visual premium
class ProjectCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? date;
  final int? trackCount;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? accentColor;

  const ProjectCard({
    super.key,
    required this.title,
    this.subtitle,
    this.date,
    this.trackCount,
    this.onTap,
    this.isSelected = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primary;
    
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isSelected ? color : AppTheme.surfaceHighlight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ] : AppTheme.shadowSm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Ícone/Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.folder_special_rounded,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (trackCount != null) ...[
                          _InfoChip(
                            icon: Icons.audiotrack_rounded,
                            label: '$trackCount tracks',
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (date != null)
                          _InfoChip(
                            icon: Icons.access_time_rounded,
                            label: date!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Seta
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighlight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textTertiary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de track/versão de áudio
class AudioTrackCard extends StatelessWidget {
  final String title;
  final String? description;
  final String? duration;
  final String? fileSize;
  final String? date;
  final bool isMaster;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;

  const AudioTrackCard({
    super.key,
    required this.title,
    this.description,
    this.duration,
    this.fileSize,
    this.date,
    this.isMaster = false,
    this.isPlaying = false,
    this.onTap,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isPlaying 
              ? AppTheme.primary.withOpacity(0.1) 
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isPlaying 
                ? AppTheme.primary.withOpacity(0.5) 
                : isMaster 
                    ? AppTheme.gold.withOpacity(0.5) 
                    : AppTheme.surfaceHighlight,
            width: isPlaying || isMaster ? 2 : 1,
          ),
          boxShadow: isPlaying ? [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.15),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ] : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Botão de play
              GestureDetector(
                onTap: onPlayTap,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isPlaying
                        ? AppTheme.primaryGradient
                        : LinearGradient(
                            colors: [
                              AppTheme.surfaceHighlight,
                              AppTheme.surfaceElevated,
                            ],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: isPlaying ? AppTheme.glowPrimary : null,
                  ),
                  child: Icon(
                    isPlaying 
                        ? Icons.pause_rounded 
                        : Icons.play_arrow_rounded,
                    color: isPlaying 
                        ? AppTheme.surface 
                        : AppTheme.textPrimary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isPlaying ? AppTheme.primary : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMaster) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.gold,
                                  AppTheme.gold.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Text(
                              'MASTER',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (duration != null) ...[
                          Icon(Icons.timer_outlined, 
                              size: 12, 
                              color: AppTheme.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            duration!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (fileSize != null) ...[
                          Icon(Icons.storage_outlined, 
                              size: 12, 
                              color: AppTheme.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            fileSize!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Waveform decorativo
              if (isPlaying)
                _MiniWaveform()
              else
                Icon(
                  Icons.more_vert_rounded,
                  color: AppTheme.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniWaveform extends StatefulWidget {
  @override
  State<_MiniWaveform> createState() => _MiniWaveformState();
}

class _MiniWaveformState extends State<_MiniWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
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
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            final delay = index * 0.15;
            final value = (((_controller.value + delay) % 1.0) * 2 - 1).abs();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 3,
              height: 8 + (value * 12),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
