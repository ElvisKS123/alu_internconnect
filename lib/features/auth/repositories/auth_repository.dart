import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../startup/models/startup_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _cachedRoleKey = 'auth.cached_role';
  static const _cachedFullNameKey = 'auth.cached_full_name';

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String _normalizedEmail(String email) => email.trim();

  Future<void> _cacheSession({
    required String role,
    required String fullName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedRoleKey, role);
    await prefs.setString(_cachedFullNameKey, fullName);
  }

  Future<void> _clearCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedRoleKey);
    await prefs.remove(_cachedFullNameKey);
  }

  Future<UserModel> signUpStudent({
    required String email,
    required String password,
    required String fullName,
    required String program,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: _normalizedEmail(email),
      password: password,
    );

    await credential.user!.updateDisplayName(fullName);
    await credential.user!.sendEmailVerification();

    final user = UserModel(
      id: credential.user!.uid,
      email: _normalizedEmail(email),
      fullName: fullName,
      role: 'student',
      program: program,
      location: 'Kigali, Rwanda',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(user.toFirestore());
    await _cacheSession(role: 'student', fullName: fullName);

    return user;
  }

  Future<UserModel> signUpStartup({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: _normalizedEmail(email),
      password: password,
    );

    await credential.user!.updateDisplayName(fullName);

    final user = UserModel(
      id: credential.user!.uid,
      email: _normalizedEmail(email),
      fullName: fullName,
      role: 'startup',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(user.toFirestore());

    // Startup profile fields (name, tagline, category, description) are no
    // longer collected at signup. Fill sensible placeholders here; the
    // startup can fill in real details later from their profile screen.
    final startup = StartupModel(
      id: credential.user!.uid,
      ownerId: credential.user!.uid,
      name: "$fullName's Startup",
      tagline: '',
      description: '',
      category: 'Engineering',
      verificationStatus: 'approved',
      email: email,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('startups')
        .doc(credential.user!.uid)
        .set(startup.toFirestore());
    await _cacheSession(role: 'startup', fullName: fullName);

    return user;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: _normalizedEmail(email),
      password: password,
    );

    final authUser = credential.user!;
    final doc = await _firestore
        .collection('users')
        .doc(authUser.uid)
        .get();

    late final UserModel user;
    if (doc.exists) {
      user = UserModel.fromFirestore(doc);
    } else {
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString(_cachedRoleKey);
      final cachedFullName = prefs.getString(_cachedFullNameKey);
      final startupDoc = await _firestore.collection('startups').doc(authUser.uid).get();
      final recoveredRole = cachedRole ?? (startupDoc.exists ? 'startup' : 'student');
      final recoveredFullName = (cachedFullName != null && cachedFullName.trim().isNotEmpty)
          ? cachedFullName.trim()
          : (authUser.displayName?.trim().isNotEmpty == true
              ? authUser.displayName!.trim()
              : (authUser.email?.split('@').first ?? 'User'));

      user = UserModel(
        id: authUser.uid,
        email: authUser.email ?? _normalizedEmail(email),
        fullName: recoveredFullName,
        role: recoveredRole,
        location: 'Kigali, Rwanda',
        isEmailVerified: authUser.emailVerified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await _firestore
            .collection('users')
            .doc(authUser.uid)
            .set(user.toFirestore(), SetOptions(merge: true));
      } catch (_) {
        // Auth is already valid; keep the fallback profile in memory.
      }
    }
    await _cacheSession(role: user.role, fullName: user.fullName);
    return user;
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final authUser = _auth.currentUser;
    if (authUser == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(authUser.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }

      // User doc missing: build from auth + cached data (so Home can open).
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString(_cachedRoleKey);
      final cachedFullName = prefs.getString(_cachedFullNameKey);

      // Try to infer role from startups doc, but don't fail if it can't be read.
      String recoveredRole;
      try {
        final startupDoc = await _firestore.collection('startups').doc(authUser.uid).get();
        recoveredRole = cachedRole ?? (startupDoc.exists ? 'startup' : 'student');
      } catch (_) {
        recoveredRole = cachedRole ?? 'student';
      }

      final fallbackFullName = (cachedFullName != null && cachedFullName.trim().isNotEmpty)
          ? cachedFullName.trim()
          : (authUser.displayName?.trim().isNotEmpty == true
              ? authUser.displayName!.trim()
              : (authUser.email?.split('@').first ?? 'User'));

      return UserModel(
        id: authUser.uid,
        email: authUser.email ?? '',
        fullName: fallbackFullName,
        role: recoveredRole,
        location: 'Kigali, Rwanda',
        isEmailVerified: authUser.emailVerified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (_) {
      // Firestore read failed due to rules/network: also fallback to auth data.
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString(_cachedRoleKey);
      final cachedFullName = prefs.getString(_cachedFullNameKey);

      final fallbackFullName = (cachedFullName != null && cachedFullName.trim().isNotEmpty)
          ? cachedFullName.trim()
          : (authUser.displayName?.trim().isNotEmpty == true
              ? authUser.displayName!.trim()
              : (authUser.email?.split('@').first ?? 'User'));

      return UserModel(
        id: authUser.uid,
        email: authUser.email ?? '',
        fullName: fallbackFullName,
        role: cachedRole ?? 'student',
        location: 'Kigali, Rwanda',
        isEmailVerified: authUser.emailVerified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }


  Future<void> signOut() async {
    await _auth.signOut();
    await _clearCachedSession();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: _normalizedEmail(email));
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.id)
        .update(user.toFirestore());
    await _auth.currentUser?.updateDisplayName(user.fullName);
  }
}