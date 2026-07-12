import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/startup_model.dart';
import '../../../core/constants/app_constants.dart';

class StartupRepository {
  final FirebaseFirestore _firestore;

  StartupRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<StartupModel?> getStartupById(String id) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.startupsCollection)
          .doc(id)
          .get();
      if (!doc.exists) return null;
      return StartupModel.fromFirestore(doc);
    } catch (e) {
      print('[StartupRepository] getStartupById error: $e');
      return null;
    }
  }

  Stream<StartupModel?> watchStartup(String id) {
    return (() async* {
      try {
        final stream = _firestore.collection(AppConstants.startupsCollection).doc(id).snapshots();
        await for (final doc in stream) {
          yield doc.exists ? StartupModel.fromFirestore(doc) : null;
        }
      } catch (e) {
        print('[StartupRepository] watchStartup error: $e');
        yield null;
      }
    })();
  }

  Stream<List<StartupModel>> watchApprovedStartups() {
    return (() async* {
      try {
        final stream = _firestore
            .collection(AppConstants.startupsCollection)
            .where('verificationStatus', isEqualTo: 'approved')
            .orderBy('name')
            .snapshots();
        await for (final snap in stream) {
          yield snap.docs.map((doc) => StartupModel.fromFirestore(doc)).toList();
        }
      } catch (e) {
        print('[StartupRepository] watchApprovedStartups error: $e');
        yield <StartupModel>[];
      }
    })();
  }

  Future<void> updateStartup(StartupModel startup) async {
    await _firestore
        .collection(AppConstants.startupsCollection)
        .doc(startup.id)
        .update({
      ...startup.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  
  Future<StartupModel> createStartup({
    required String ownerId,
    required String name,
    required String tagline,
    required String category,
    required String description,
    required String email,
    String verificationStatus = 'pending',
  }) async {
    final now = DateTime.now();
    final startup = StartupModel(
      id: ownerId,
      ownerId: ownerId,
      name: name,
      tagline: tagline,
      description: description,
      category: category,
      verificationStatus: verificationStatus,
      email: email,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(AppConstants.startupsCollection)
        .doc(ownerId)
        .set(startup.toFirestore());

    return startup;
  }

  
  static const List<String> demoValidCodes = ['DEMO-001'];

  
  Future<bool> verifyStartupCode({
    required String code,
    required String startupId,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return false;

    if (demoValidCodes.contains(normalized)) return true;

    try {
      final docRef = _firestore
          .collection(AppConstants.aluStartupCodesCollection)
          .doc(normalized);
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final alreadyUsed = data['used'] == true;
      final usedBy = data['usedBy'] as String?;
      if (alreadyUsed && usedBy != startupId) return false;

      await docRef.set({
        'used': true,
        'usedBy': startupId,
        'usedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('[StartupRepository] verifyStartupCode error: $e');
      return false;
    }
  }
}