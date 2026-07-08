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

  // For admin: all pending startups
  Stream<List<StartupModel>> watchPendingStartups() {
    return (() async* {
      try {
        final stream = _firestore
            .collection(AppConstants.startupsCollection)
            .where('verificationStatus', isEqualTo: 'pending')
            .snapshots();
        await for (final snap in stream) {
          yield snap.docs.map((doc) => StartupModel.fromFirestore(doc)).toList();
        }
      } catch (e) {
        print('[StartupRepository] watchPendingStartups error: $e');
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

  Future<void> approveStartup(String startupId, {String? note}) async {
    await _firestore
        .collection(AppConstants.startupsCollection)
        .doc(startupId)
        .update({
      'verificationStatus': 'approved',
      'verificationNote': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectStartup(String startupId, {required String reason}) async {
    await _firestore
        .collection(AppConstants.startupsCollection)
        .doc(startupId)
        .update({
      'verificationStatus': 'rejected',
      'verificationNote': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
