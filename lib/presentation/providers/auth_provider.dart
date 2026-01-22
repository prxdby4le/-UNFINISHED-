// lib/presentation/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  UserProfile? _currentProfile;
  bool _isLoading = false;

  UserProfile? get currentProfile => _currentProfile;
  bool get isAuthenticated => _authRepository.isAuthenticated;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authRepository.authStateChanges.listen((state) async {
      if (state.event == AuthChangeEvent.signedIn) {
        await loadProfile();
      } else if (state.event == AuthChangeEvent.signedOut) {
        _currentProfile = null;
        notifyListeners();
      }
    });

    if (_authRepository.isAuthenticated) {
      await loadProfile();
    }
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentProfile = await _authRepository.getCurrentProfile();
    } catch (e) {
      print('Erro ao carregar perfil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      await loadProfile();
      return true;
    } catch (e) {
      print('Erro no login: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, {String? fullName}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      // Após signup, fazer login automático
      await signIn(email, password);
      return true;
    } catch (e) {
      print('Erro no signup: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.signOut();
      _currentProfile = null;
    } catch (e) {
      print('Erro no logout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
      );
      await loadProfile();
    } catch (e) {
      print('Erro ao atualizar perfil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
