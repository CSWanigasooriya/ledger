import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _user;
  AppUser? _appUser;
  bool _isLoading = false;
  String? _error;
  bool _isUnauthorized = false;
  StreamSubscription? _userDocSubscription;

  User? get user => _user;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _appUser != null;
  bool get isUnauthorized => _isUnauthorized;
  String? get error => _error;
  UserRole? get role => _appUser?.role;
  bool get isAdmin => _appUser?.isAdmin ?? false;
  bool get isTeacher => _appUser?.isTeacher ?? false;
  bool get isMarker => _appUser?.isMarker ?? false;

  AuthProvider() {
    _authService.authStateChanges.listen((user) {
      _user = user;
      if (user != null) {
        _loadUserRole(user);
      } else {
        _appUser = null;
        _isUnauthorized = false;
        _userDocSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserRole(User firebaseUser) async {
    try {
      // Check if user exists in Firestore
      final existingUser = await _userService.getUser(firebaseUser.uid);

      if (existingUser != null) {
        _appUser = existingUser;
        _isUnauthorized = false;
        _listenToUserDoc(firebaseUser.uid);
        notifyListeners();
        return;
      }

      // No user doc — check if this is the first user ever
      final hasUsers = await _userService.hasAnyUsers();

      if (!hasUsers) {
        // First user becomes admin automatically
        final newUser = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? '',
          role: UserRole.admin,
        );
        await _userService.createUser(newUser);
        _appUser = newUser;
        _isUnauthorized = false;
        _listenToUserDoc(firebaseUser.uid);
      } else {
        // Not the first user and no role assigned — unauthorized
        _appUser = null;
        _isUnauthorized = true;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user role: $e');
      _error = 'Failed to load user profile';
      notifyListeners();
    }
  }

  void _listenToUserDoc(String uid) {
    _userDocSubscription?.cancel();
    _userDocSubscription = _userService.getUserStream(uid).listen((appUser) {
      if (appUser == null) {
        // User doc deleted — revoke access
        _appUser = null;
        _isUnauthorized = true;
      } else {
        _appUser = appUser;
        _isUnauthorized = false;
      }
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return result != null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in FirebaseAuth error: ${e.code} - ${e.message}');
      _error = 'Auth error (${e.code}): ${e.message}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      _error = 'Google sign-in failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _userDocSubscription?.cancel();
    _appUser = null;
    _isUnauthorized = false;
    await _authService.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    super.dispose();
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}
