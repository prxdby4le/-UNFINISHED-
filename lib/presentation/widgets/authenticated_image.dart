// lib/presentation/widgets/authenticated_image.dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/r2_config.dart';

/// Widget que carrega uma imagem de uma URL que requer autenticação
class AuthenticatedImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AuthenticatedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _imageBytes = null;
    });

    try {
      final headers = R2Config.getAuthHeaders();
      final response = await http.get(
        Uri.parse(widget.imageUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Verificar se a resposta é JSON (erro - Edge Function retornou URL assinada)
        final contentType = response.headers['content-type'] ?? '';
        final bodyString = String.fromCharCodes(response.bodyBytes.take(100));
        
        if (contentType.contains('application/json') || bodyString.trim().startsWith('{')) {
          // A Edge Function retornou JSON em vez da imagem
          // Tentar extrair a URL e fazer nova requisição
          try {
            final jsonData = json.decode(response.body);
            if (jsonData is Map && jsonData.containsKey('url')) {
              final signedUrl = jsonData['url'] as String;
              debugPrint('[AuthenticatedImage] Edge Function retornou JSON, usando URL assinada: $signedUrl');
              
              // Fazer nova requisição para a URL assinada
              final signedResponse = await http.get(Uri.parse(signedUrl));
              if (signedResponse.statusCode == 200) {
                if (mounted) {
                  setState(() {
                    _imageBytes = signedResponse.bodyBytes;
                    _isLoading = false;
                  });
                }
                return;
              }
            }
          } catch (e) {
            debugPrint('[AuthenticatedImage] Erro ao processar JSON: $e');
          }
          throw Exception('Edge Function retornou JSON em vez de imagem');
        }
        
        // É uma imagem válida
        if (mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AuthenticatedImage] Erro ao carregar imagem: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError || _imageBytes == null) {
      return widget.errorWidget ?? const Icon(
        Icons.error_outline,
        color: Colors.red,
      );
    }

    return Image.memory(
      _imageBytes!,
      fit: widget.fit,
      width: null,
      height: null,
    );
  }
}
