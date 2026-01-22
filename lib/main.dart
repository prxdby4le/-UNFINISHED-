// lib/main.dart
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/config/supabase_config.dart';
import 'core/cache/audio_cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar background audio
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.trashtalk.audio',
    androidNotificationChannelName: 'Trashtalk Audio',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
  );
  
  // Inicializar Supabase
  await SupabaseConfig.initialize();
  
  // Inicializar cache
  await AudioCacheManager().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trashtalk Records',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Central de Gravadora - Em desenvolvimento'),
        ),
      ),
    );
  }
}
