// lib/core/utils/color_extractor.dart
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:http/http.dart' as http;
import '../../core/config/r2_config.dart';

class ColorExtractor {
  /// Extrai a cor dominante de uma imagem a partir de sua URL
  static Future<Color> extractDominantColor(String imageUrl) async {
    try {
      // Se for URL do proxy, usar diretamente
      // Se for caminho relativo, construir URL do proxy
      final url = imageUrl.startsWith('http')
          ? imageUrl
          : '${R2Config.proxyBaseUrl}/$imageUrl';

      // Buscar imagem com autenticação
      final headers = R2Config.getAuthHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode != 200) {
        return _getDefaultColor();
      }

      // Converter bytes para ImageProvider
      final imageBytes = response.bodyBytes;
      final imageProvider = MemoryImage(Uint8List.fromList(imageBytes));

      // Extrair paleta de cores
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 5,
      );

      // Obter cor dominante vibrante ou fallback para cor dominante
      final vibrantColor = paletteGenerator.vibrantColor?.color ??
          paletteGenerator.dominantColor?.color ??
          paletteGenerator.mutedColor?.color;

      if (vibrantColor != null) {
        // Ajustar saturação e brilho para melhor visualização
        final hsl = HSLColor.fromColor(vibrantColor);
        return hsl
            .withSaturation(math.min(0.7, hsl.saturation))
            .withLightness(math.max(0.3, math.min(0.6, hsl.lightness)))
            .toColor();
      }

      return _getDefaultColor();
    } catch (e) {
      debugPrint('[ColorExtractor] Erro ao extrair cor: $e');
      return _getDefaultColor();
    }
  }

  /// Extrai múltiplas cores de uma imagem (para gradientes)
  static Future<List<Color>> extractColorPalette(String imageUrl, {int count = 3}) async {
    try {
      final url = imageUrl.startsWith('http')
          ? imageUrl
          : '${R2Config.proxyBaseUrl}/$imageUrl';

      final headers = R2Config.getAuthHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode != 200) {
        return _getDefaultPalette();
      }

      final imageBytes = response.bodyBytes;
      final imageProvider = MemoryImage(Uint8List.fromList(imageBytes));

      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: count + 2,
      );

      final colors = <Color>[];

      // Adicionar cores na ordem de preferência
      if (paletteGenerator.vibrantColor != null) {
        colors.add(_adjustColor(paletteGenerator.vibrantColor!.color));
      }
      if (paletteGenerator.dominantColor != null && !colors.contains(paletteGenerator.dominantColor!.color)) {
        colors.add(_adjustColor(paletteGenerator.dominantColor!.color));
      }
      if (paletteGenerator.mutedColor != null && !colors.contains(paletteGenerator.mutedColor!.color)) {
        colors.add(_adjustColor(paletteGenerator.mutedColor!.color));
      }
      if (paletteGenerator.lightVibrantColor != null && colors.length < count) {
        colors.add(_adjustColor(paletteGenerator.lightVibrantColor!.color));
      }
      if (paletteGenerator.darkVibrantColor != null && colors.length < count) {
        colors.add(_adjustColor(paletteGenerator.darkVibrantColor!.color));
      }

      // Preencher com cores padrão se necessário
      while (colors.length < count) {
        colors.add(_getDefaultColor());
      }

      return colors.take(count).toList();
    } catch (e) {
      debugPrint('[ColorExtractor] Erro ao extrair paleta: $e');
      return _getDefaultPalette();
    }
  }

  /// Ajusta uma cor para melhor visualização (saturação e brilho)
  static Color _adjustColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(math.min(0.7, hsl.saturation))
        .withLightness(math.max(0.3, math.min(0.6, hsl.lightness)))
        .toColor();
  }

  static Color _getDefaultColor() {
    return const Color(0xFF1E88E5);
  }

  static List<Color> _getDefaultPalette() {
    return [
      const Color(0xFF1E88E5),
      const Color(0xFF1E88E5).withOpacity(0.6),
      const Color(0xFF1E88E5).withOpacity(0.3),
    ];
  }
}
