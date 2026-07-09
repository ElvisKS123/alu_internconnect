import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/application_model.dart';
import '../../../core/constants/app_constants.dart';

class ApplicationRepository {
  final FirebaseFirestore _firestore;

  ApplicationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Watch student's own applications (real-time)
  // NOTE: single equality field only (no .orderBy() chained in Firestore) --
  // combining an equality filter with orderBy on a different field requires
  // a manually-created composite index. We avoid that entirely by sorting
  // client-side instead, same pattern used in OpportunityRepository.
  Stream<List<ApplicationModel>> watchStudentApplications(String studentId) {
    return (() async* {
      try {
        final stream = _firestore
            .collection(AppConstants.applicationsCollection)
            .where('applicantId', isEqualTo: studentId)
            .snapshots();
        await for (final snap in stream) {
          final apps =
              snap.docs.map((doc) => ApplicationModel.fromFirestore(doc)).toList();
          apps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          yield apps;
        }
      } catch (e) {
        debugPrint('[ApplicationRepository] watchStudentApplications error: $e');
        yield <ApplicationModel>[];
      }
    })();
  }

  // Watch startup's incoming applications (real-time)
  // Same reasoning: single equality field (startupId) queried in Firestore;
  // optional opportunityId/status filters and sorting are applied
  // client-side so no composite index is ever required, regardless of
  // which filter combination is active.
  Stream<List<ApplicationModel>> watchStartupApplications(
    String startupId, {
    String? opportunityId,
    String? status,
  }) {
    return (() async* {
      try {
        final stream = _firestore
            .collection(AppConstants.applicationsCollection)
            .where('startupId', isEqualTo: startupId)
            .snapshots();
        await for (final snap in stream) {
          var apps =
              snap.docs.map((doc) => ApplicationModel.fromFirestore(doc)).toList();

          if (opportunityId != null) {
            apps = apps.where((a) => a.opportunityId == opportunityId).toList();
          }
          if (status != null) {
            apps = apps.where((a) => a.status == status).toList();
          }

          apps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          yield apps;
        }
      } catch (e) {
        debugPrint('[ApplicationRepository] watchStartupApplications error: $e');
        yield <ApplicationModel>[];
      }
    })();
  }

  Future<bool> hasApplied({
    required String studentId,
    required String opportunityId,
  }) async {
    try {
      final snap = await _firestore
          .collection(AppConstants.applicationsCollection)
          .where('applicantId', isEqualTo: studentId)
          .where('opportunityId', isEqualTo: opportunityId)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[ApplicationRepository] hasApplied error: $e');
      return false;
    }
  }

  Future<ApplicationModel> submitApplication({
    required String opportunityId,
    required String opportunityTitle,
    required String startupId,
    required String startupName,
    String? startupLogoUrl,
    required String applicantId,
    required String applicantName,
    required String applicantEmail,
    String? applicantPhotoUrl,
    required String coverLetter,
    String? portfolioUrl,
    String? resumeUrl,
    List<String> relevantSkills = const [],
  }) async {
    // Check for duplicate
    final alreadyApplied = await hasApplied(
      studentId: applicantId,
      opportunityId: opportunityId,
    );
    if (alreadyApplied) throw Exception('You have already applied for this opportunity.');

    final ref = _firestore.collection(AppConstants.applicationsCollection).doc();

    final application = ApplicationModel(
      id: ref.id,
      opportunityId: opportunityId,
      opportunityTitle: opportunityTitle,
      startupId: startupId,
      startupName: startupName,
      startupLogoUrl: startupLogoUrl,
      applicantId: applicantId,
      applicantName: applicantName,
      applicantEmail: applicantEmail,
      applicantPhotoUrl: applicantPhotoUrl,
      coverLetter: coverLetter,
      portfolioUrl: portfolioUrl,
      resumeUrl: resumeUrl,
      relevantSkills: relevantSkills,
      status: 'pending',
      appliedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.set(application.toFirestore());

    // Increment application count on opportunity. Best-effort: the
    // application itself has already been created successfully above, so a
    // failure here shouldn't surface as an error to the user.
    try {
      await _firestore
          .collection(AppConstants.opportunitiesCollection)
          .doc(opportunityId)
          .update({'applicationCount': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('[ApplicationRepository] submitApplication count update failed: $e');
    }

    return application;
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
    String? note,
    DateTime? interviewDate,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': Timestamp.now(),
    };
    if (note != null) updates['startupNote'] = note;
    if (interviewDate != null) {
      updates['interviewDate'] = Timestamp.fromDate(interviewDate);
    }

    await _firestore
        .collection(AppConstants.applicationsCollection)
        .doc(applicationId)
        .update(updates);
  }

  Future<void> withdrawApplication(String applicationId, String opportunityId) async {
    await _firestore
        .collection(AppConstants.applicationsCollection)
        .doc(applicationId)
        .delete();

    try {
      await _firestore
          .collection(AppConstants.opportunitiesCollection)
          .doc(opportunityId)
          .update({'applicationCount': FieldValue.increment(-1)});
    } catch (e) {
      debugPrint('[ApplicationRepository] withdrawApplication count update failed: $e');
    }
  }
}