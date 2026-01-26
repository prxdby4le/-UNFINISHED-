// lib/core/utils/responsive.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Responsive {
  /// Breakpoint para desktop (largura mínima)
  static const double desktopBreakpoint = 1024;
  
  /// Breakpoint para tablet (largura mínima)
  static const double tabletBreakpoint = 768;
  
  /// Verifica se está rodando em desktop (web com largura >= 1024px)
  static bool isDesktop(BuildContext context) {
    if (!kIsWeb) return false;
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
  
  /// Verifica se está rodando em tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }
  
  /// Verifica se está rodando em mobile
  static bool isMobile(BuildContext context) {
    return !isDesktop(context) && !isTablet(context);
  }
  
  /// Retorna largura máxima para conteúdo centralizado em desktop
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1200; // Largura máxima para desktop
    }
    return double.infinity; // Mobile/tablet usa toda largura
  }
  
  /// Retorna padding horizontal baseado no dispositivo
  static double getHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) {
      return 48;
    } else if (isTablet(context)) {
      return 32;
    }
    return 20;
  }
}
