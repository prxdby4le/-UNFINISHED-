// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de design do Trashtalk Records
/// 
/// Inspirado em estúdios de gravação profissionais:
/// - Dark mode como base (conforto visual em sessões longas)
/// - Acentos em ciano/turquesa (como VU meters e displays LED)
/// - Gradientes sutis que remetem a ondas sonoras
/// - Tipografia moderna e legível

class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PALETA DE CORES
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Cores primárias - Ciano/Turquesa (como LEDs de estúdio)
  static const Color primary = Color(0xFF00E5CC);
  static const Color primaryDark = Color(0xFF00B8A3);
  static const Color primaryLight = Color(0xFF5EFFF2);
  
  // Cores secundárias - Magenta (contraste complementar)
  static const Color secondary = Color(0xFFFF006E);
  static const Color secondaryDark = Color(0xFFCC0058);
  static const Color secondaryLight = Color(0xFFFF4D94);
  
  // Cores de superfície - Tons escuros profundos
  static const Color surface = Color(0xFF0D0D12);
  static const Color surfaceVariant = Color(0xFF16161D);
  static const Color surfaceElevated = Color(0xFF1E1E28);
  static const Color surfaceHighlight = Color(0xFF2A2A38);
  
  // Cores de texto
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFB8B8C0);
  static const Color textTertiary = Color(0xFF6E6E7A);
  
  // Cores de estado
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF448AFF);
  
  // Cores especiais
  static const Color gold = Color(0xFFFFD700); // Para "Master" tracks
  static const Color waveform = Color(0xFF00E5CC); // Visualização de áudio
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF00B8FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surface, surfaceVariant],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TIPOGRAFIA
  // ═══════════════════════════════════════════════════════════════════════════
  
  static TextTheme get textTheme {
    return TextTheme(
      // Display - títulos grandes e impactantes
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 45,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      
      // Headlines - cabeçalhos de seção
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      
      // Títulos - cards e listas
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textPrimary,
      ),
      
      // Body - texto principal
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: textSecondary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: textTertiary,
      ),
      
      // Labels - botões e inputs
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textTertiary,
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ESPAÇAMENTOS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacing2xl = 48;
  static const double spacing3xl = 64;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // RAIOS DE BORDA
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SOMBRAS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get glowPrimary => [
    BoxShadow(
      color: primary.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: -4,
    ),
  ];
  
  static List<BoxShadow> get glowSecondary => [
    BoxShadow(
      color: secondary.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: -4,
    ),
  ];
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TEMA COMPLETO
  // ═══════════════════════════════════════════════════════════════════════════
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Esquema de cores
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: surface,
        primaryContainer: primaryDark,
        onPrimaryContainer: textPrimary,
        secondary: secondary,
        onSecondary: textPrimary,
        secondaryContainer: secondaryDark,
        onSecondaryContainer: textPrimary,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceElevated,
        error: error,
        onError: textPrimary,
      ),
      
      // Tipografia
      textTheme: textTheme,
      
      // Scaffold
      scaffoldBackgroundColor: surface,
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Botões elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: surface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Botões de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Botões outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      
      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: surfaceHighlight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textTertiary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textTertiary),
        prefixIconColor: textTertiary,
        suffixIconColor: textTertiary,
      ),
      
      // Dividers
      dividerTheme: const DividerThemeData(
        color: surfaceHighlight,
        thickness: 1,
        space: 1,
      ),
      
      // Icons
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
      
      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        tileColor: Colors.transparent,
        selectedTileColor: surfaceHighlight,
      ),
      
      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceVariant,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceHighlight,
      ),
      
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceHighlight,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withOpacity(0.5);
          return surfaceHighlight;
        }),
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHighlight,
        selectedColor: primary.withOpacity(0.2),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXTENSÕES ÚTEIS
// ═══════════════════════════════════════════════════════════════════════════════

extension ColorExtension on Color {
  /// Adiciona um brilho/glow ao redor de widgets
  List<BoxShadow> get glow => [
    BoxShadow(
      color: withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: -4,
    ),
  ];
}
