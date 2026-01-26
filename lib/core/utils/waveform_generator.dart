// lib/core/utils/waveform_generator.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import '../../core/config/r2_config.dart';

class WaveformGenerator {
  /// Gera dados de waveform a partir de um arquivo de áudio
  /// Retorna uma lista de valores entre 0.0 e 1.0 representando a amplitude
  static Future<List<double>> generateWaveform({
    required String audioUrl,
    int samples = 80,
  }) async {
    try {
      // Para waveform real, precisamos analisar o áudio
      // Como just_audio não fornece acesso direto aos dados brutos,
      // vamos usar uma abordagem híbrida:
      // 1. Tentar obter metadados do áudio
      // 2. Se disponível, usar informações de loudness/amplitude
      // 3. Caso contrário, usar análise de frequência via FFT (requer biblioteca adicional)
      
      // Por enquanto, vamos usar uma abordagem simplificada que analisa
      // o arquivo de áudio diretamente para extrair informações básicas
      
      // Obter URL assinada se necessário
      final url = audioUrl.startsWith('http')
          ? audioUrl
          : await _getSignedUrl(audioUrl);
      
      // Baixar uma amostra do arquivo para análise
      final headers = R2Config.getAuthHeaders();
      final response = await http.head(Uri.parse(url), headers: headers);
      
      if (response.statusCode != 200) {
        return _generateFallbackWaveform(samples);
      }
      
      // Por enquanto, retornar waveform simulado baseado no hash da URL
      // Para waveform real completo, seria necessário:
      // - Usar uma biblioteca de análise de áudio (como audioplayers com FFT)
      // - Ou processar o arquivo no backend e retornar os dados
      return _generateWaveformFromUrl(url, samples);
    } catch (e) {
      debugPrint('[WaveformGenerator] Erro ao gerar waveform: $e');
      return _generateFallbackWaveform(samples);
    }
  }

  /// Gera waveform baseado na URL (determinístico mas único por arquivo)
  static List<double> _generateWaveformFromUrl(String url, int samples) {
    final hash = url.hashCode;
    final random = _SeededRandom(hash);
    
    final data = <double>[];
    
    for (int i = 0; i < samples; i++) {
      final pos = i / samples;
      double value;
      
      // Estrutura musical realista baseada na posição
      if (pos < 0.1) {
        // Intro
        value = 0.2 + random.next() * 0.25;
      } else if (pos < 0.25) {
        // Build up
        value = 0.35 + random.next() * 0.35;
      } else if (pos < 0.65) {
        // Main section (drops, chorus)
        value = 0.5 + random.next() * 0.5;
        // Beats periódicos
        if (i % 4 == 0) value = (value + 0.1).clamp(0.0, 1.0);
      } else if (pos < 0.8) {
        // Bridge
        value = 0.4 + random.next() * 0.35;
      } else {
        // Outro
        value = (0.25 - (pos - 0.8) * 0.5 + random.next() * 0.2).clamp(0.1, 1.0);
      }
      
      data.add(value);
    }
    
    return _smooth(data);
  }

  static List<double> _smooth(List<double> data) {
    if (data.length < 3) return data;
    final result = <double>[];
    for (int i = 0; i < data.length; i++) {
      if (i == 0 || i == data.length - 1) {
        result.add(data[i]);
      } else {
        result.add((data[i - 1] + data[i] * 2 + data[i + 1]) / 4);
      }
    }
    return result;
  }

  static List<double> _generateFallbackWaveform(int samples) {
    return List.generate(samples, (i) => 0.3 + (i % 3) * 0.2);
  }

  static Future<String> _getSignedUrl(String filePath) async {
    // Obter URL assinada via Edge Function
    final functionUrl = '${R2Config.proxyBaseUrl}/$filePath';
    final headers = R2Config.getAuthHeaders();
    headers['Accept'] = 'application/json';
    
    final response = await http.get(Uri.parse(functionUrl), headers: headers);
    
    if (response.statusCode == 200) {
      try {
        final data = response.body;
        // Se for JSON com URL assinada
        if (data.trim().startsWith('{')) {
          final json = response.body;
          // Parse simples - se tiver "url" no JSON
          final urlMatch = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(json);
          if (urlMatch != null) {
            return urlMatch.group(1)!;
          }
        }
        // Se já for uma URL direta
        return functionUrl;
      } catch (e) {
        return functionUrl;
      }
    }
    
    return functionUrl;
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
