// lib/presentation/screens/cache_settings_screen.dart
import 'package:flutter/material.dart';
import '../../core/cache/audio_cache_manager.dart';

class CacheSettingsScreen extends StatefulWidget {
  const CacheSettingsScreen({super.key});

  @override
  State<CacheSettingsScreen> createState() => _CacheSettingsScreenState();
}

class _CacheSettingsScreenState extends State<CacheSettingsScreen> {
  final AudioCacheManager _cacheManager = AudioCacheManager();
  bool _isLoading = false;
  bool _wifiOnlyCache = false;
  CacheStats? _stats;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStats();
  }
  
  Future<void> _loadSettings() async {
    await _cacheManager.initialize();
    setState(() {
      _wifiOnlyCache = _cacheManager.wifiOnlyCache;
    });
  }
  
  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final stats = await _cacheManager.getStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar estatísticas: $e')),
        );
      }
    }
  }
  
  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Cache'),
        content: const Text(
          'Tem certeza que deseja limpar todo o cache? '
          'Todos os arquivos baixados serão removidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _cacheManager.clearCache();
      await _loadStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache limpo com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao limpar cache: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _toggleWifiOnly(bool value) {
    setState(() {
      _wifiOnlyCache = value;
      _cacheManager.wifiOnlyCache = value;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Cache'),
        backgroundColor: const Color(0xFF1A1A1F),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1A1A1F),
      body: _isLoading && _stats == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Estatísticas do Cache
                Card(
                  color: const Color(0xFF2A2A2F),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estatísticas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_stats != null) ...[
                          _buildStatRow(
                            'Tamanho do Cache',
                            _stats!.formattedSize,
                            Icons.storage,
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            'Arquivos em Cache',
                            '${_stats!.fileCount}',
                            Icons.audiotrack,
                          ),
                        ] else
                          const Text(
                            'Carregando...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadStats,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Atualizar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Configurações
                Card(
                  color: const Color(0xFF2A2A2F),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configurações',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text(
                            'Cache apenas em Wi-Fi',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Fazer cache apenas quando conectado via Wi-Fi',
                            style: TextStyle(color: Colors.white60),
                          ),
                          value: _wifiOnlyCache,
                          onChanged: _toggleWifiOnly,
                          activeColor: const Color(0xFF1E88E5),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Ações
                Card(
                  color: const Color(0xFF2A2A2F),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ações',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _stats?.totalSizeBytes == 0 || _isLoading
                                ? null
                                : _clearCache,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Limpar Cache'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Informações
                Card(
                  color: const Color(0xFF2A2A2F),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Sobre o Cache',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'O cache armazena arquivos de áudio localmente para '
                          'reprodução offline e melhor performance. O limite máximo '
                          'é de 500MB e os arquivos menos usados são removidos '
                          'automaticamente quando necessário.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
