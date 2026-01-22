// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/config/supabase_config.dart';
import 'core/cache/audio_cache_manager.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/project_provider.dart';
import 'presentation/providers/audio_player_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/projects_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar status bar para tema escuro
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Orientação preferida
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Inicializar background audio (apenas para mobile)
  if (!kIsWeb) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.trashtalk.audio',
        androidNotificationChannelName: 'Trashtalk Audio',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
      );
    } catch (e) {
      debugPrint('Erro ao inicializar JustAudioBackground: $e');
    }
  }
  
  // Inicializar Supabase
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('❌ Erro crítico ao inicializar Supabase: $e');
    debugPrint('   O app pode não funcionar corretamente.');
  }
  
  // Inicializar cache (apenas para mobile/desktop, não web)
  if (!kIsWeb) {
    try {
      await AudioCacheManager().initialize();
    } catch (e) {
      debugPrint('Erro ao inicializar cache: $e');
    }
  }
  
  runApp(const TrashtalkApp());
}

class TrashtalkApp extends StatelessWidget {
  const TrashtalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        Provider(create: (_) => AudioPlayerProvider()),
      ],
      child: MaterialApp(
        title: 'Trashtalk Records',
        debugShowCheckedModeBanner: false,
        
        // Aplicar tema customizado
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        
        // Tela inicial baseada na autenticação
        home: const AuthWrapper(),
        
        // Configuração de scroll
        scrollBehavior: const _CustomScrollBehavior(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepository();
    
    // Verificar se usuário está autenticado
    if (authRepo.isAuthenticated) {
      return const ProjectsScreen();
    } else {
      return const LoginScreen();
    }
  }
}

// Comportamento de scroll customizado
class _CustomScrollBehavior extends ScrollBehavior {
  const _CustomScrollBehavior();
  
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
