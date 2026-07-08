import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';
import '../../../core/constants/app_constants.dart';

class ApplicationRepository {
  final FirebaseFirestore _firestore;

  ApplicationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Watch student's own applications (real-time)
  Stream<List<ApplicationModel>> watchStudentApplications(String studentId) {
    return (() async* {
      try {
        final stream = _firestore
            .collection(AppConstants.applicationsCollection)
            .where('applicantId', isEqualTo: studentId)
            .orderBy('appliedAt', descending: true)
            .snapshots();
        await for (final snap in stream) {
          yield snap.docs.map((doc) => ApplicationModel.fromFirestore(doc)).toList();
        }
      } catch (e) {
        print('[ApplicationRepository] watchStudentApplications error: $e');
        yield <ApplicationModel>[];
      }
    })();
  }

  // Watch startup's incoming applications (real-time)
  Stream<List<ApplicationModel>> watchStartupApplications(
    String startupId, {
    String? opportunityId,
    String? status,
  }) {
    Query query = _firestore
        .collection(AppConstants.applicationsCollection)
        .where('startupId', isEqualTo: startupId)
        .orderBy('appliedAt', descending: true);

    if (opportunityId != null) {
      query = query.where('opportunityId', isEqualTo: opportunityId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return (() async* {
      try {
        final stream = query.snapshots();
        await for (final snap in stream) {
          yield snap.docs.map((doc) => ApplicationModel.fromFirestore(doc)).toList();
        }
      } catch (e) {
        print('[ApplicationRepository] watchStartupApplications error: $e');
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
      print('[ApplicationRepository] hasApplied error: $e');
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

    // Increment application count on opportunity
    await _firestore
        .collection(AppConstants.opportunitiesCollection)
        .doc(opportunityId)
        .update({'applicationCount': FieldValue.increment(1)});

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

    await _firestore
        .collection(AppConstants.opportunitiesCollection)
        .doc(opportunityId)
        .update({'applicationCount': FieldValue.increment(-1)});
  }
}
