import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

// ─── States ────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}


class AuthLoggedOut extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {}

// ─── Cubit ───

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    emit(AuthLoading());
    try {
      final user = await _loadCurrentUserProfileWithRetry();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<UserModel?> _loadCurrentUserProfileWithRetry() async {
    const attempts = 3;
    for (var i = 0; i < attempts; i++) {
      final user = await _authRepository.getCurrentUserProfile();
      if (user != null) return user;
      if (i < attempts - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    return null;
  }

  Future<void> signUpStudent({
    required String email,
    required String password,
    required String fullName,
    required String program,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUpStudent(
        email: email,
        password: password,
        fullName: fullName,
        program: program,
      );
      emit(AuthAuthenticated(user));
    } on Exception catch (e) {
      emit(AuthError(_parseError(e)));
    }
  }

  Future<void> signUpStartup({
    required String email,
    required String password,
    required String fullName,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUpStartup(
        email: email,
        password: password,
        fullName: fullName,
      );
      emit(AuthAuthenticated(user));
    } on Exception catch (e) {
      emit(AuthError(_parseError(e)));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(user));
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('AuthCubit.signIn failed: $e');
      }
      emit(AuthError(_parseError(e)));
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    emit(AuthLoggedOut());
  }

  // Refreshes the in-memory authenticated user (e.g. after saving skills or
  // other profile fields on the Edit Profile screen) so the rest of the app
  // -- recommendations, the profile screen, etc. -- reflects the change
  // immediately instead of only after a restart/re-login.
  void updateLocalUser(UserModel user) {
    if (state is AuthAuthenticated) {
      emit(AuthAuthenticated(user));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPasswordResetEmail(email);
      emit(AuthPasswordResetSent());
    } on Exception catch (e) {
      emit(AuthError(_parseError(e)));
    }
  }

  String _parseError(Exception e) {
    if (e is FirebaseAuthException) {
      final code = e.code.toLowerCase();
      final message = e.message?.toLowerCase() ?? '';

      if (kDebugMode) {
        debugPrint('FirebaseAuthException code=$code message=$message');
      }

      if (code == 'invalid-credential' || code == 'wrong-password') {
        return 'Incorrect email or password. Please try again.';
      }
      if (code == 'user-not-found') return 'No account found with this email.';
      if (code == 'email-already-in-use') return 'This email is already registered.';
      if (code == 'weak-password') return 'Password is too weak. Use at least 6 characters.';
      if (code == 'invalid-email') return 'Please enter a valid email address.';
      if (code == 'network-request-failed') return 'No internet connection. Please check your network.';
      if (code == 'requires-recent-login') return 'Please sign in again and retry this action.';
      if (code == 'operation-not-allowed') return 'Email/password sign-in is not enabled for this Firebase project.';
      if (code == 'unauthorized-domain' || code == 'app-not-authorized') {
        return 'This web domain is not authorized in Firebase Authentication.';
      }
      if (code == 'invalid-api-key') return 'The Firebase API key is invalid or blocked.';
      if (code == 'too-many-requests') return 'Too many attempts. Please wait a moment and try again.';
      if (code == 'popup-closed-by-user') return 'The sign-in popup was closed before completion.';
      if (code == 'web-storage-unsupported') return 'This browser is blocking authentication storage. Try a different browser or allow cookies.';
      if (code == 'unauthorized-domain') return 'This web domain is not allowed in Firebase Authentication.';
      if (message.contains('auth/domain-config-required')) return 'The Firebase auth domain is not configured correctly for this app.';
    }

    final msg = e.toString().toLowerCase();
    if (msg.contains('email-already-in-use')) return 'This email is already registered.';
    if (msg.contains('wrong-password')) return 'Incorrect password. Please try again.';
    if (msg.contains('user-not-found')) return 'No account found with this email.';
    if (msg.contains('weak-password')) return 'Password is too weak. Use at least 6 characters.';
    if (msg.contains('invalid-email')) return 'Please enter a valid email address.';
    if (msg.contains('network-request-failed')) return 'No internet connection. Please check your network.';
    if (msg.contains('requires-recent-login')) return 'Please sign in again and retry this action.';
    if (msg.contains('operation-not-allowed')) return 'Email/password sign-in is not enabled for this Firebase project.';
    if (msg.contains('popup-closed-by-user')) return 'The sign-in popup was closed before completion.';
    if (msg.contains('auth/domain-config-required')) return 'The Firebase auth domain is not configured correctly for this app.';
    if (msg.contains('invalid-api-key')) return 'The Firebase API key is invalid or blocked.';
    if (msg.contains('too-many-requests')) return 'Too many attempts. Please wait a moment and try again.';
    if (msg.contains('web-storage-unsupported')) return 'This browser is blocking authentication storage. Try a different browser or allow cookies.';
    return 'Authentication failed. Please check your Firebase project settings and try again.';
  }
}