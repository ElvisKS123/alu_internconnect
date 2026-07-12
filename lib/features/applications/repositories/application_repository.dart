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

  Future<ApplicationModel?> getApplicationById(String id) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.applicationsCollection)
          .doc(id)
          .get();
      if (!doc.exists) return null;
      return ApplicationModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[ApplicationRepository] getApplicationById error: $e');
      return null;
    }
  }

  // Real-time single-application stream, used by the Application Details
  // screen so students see status changes, rejection reasons, and
  // scheduled meetings as soon as a startup updates them.
  Stream<ApplicationModel?> watchApplicationById(String id) {
    return (() async* {
      try {
        final stream = _firestore
            .collection(AppConstants.applicationsCollection)
            .doc(id)
            .snapshots();
        await for (final doc in stream) {
          yield doc.exists ? ApplicationModel.fromFirestore(doc) : null;
        }
      } catch (e) {
        debugPrint('[ApplicationRepository] watchApplicationById error: $e');
        yield null;
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
    bool isPaid = false,
    String? compensation,
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
      isPaid: isPaid,
      compensation: compensation,
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
    String? rejectionReason,
    // Optional context used only to fire a rejection notification below.
    String? applicantId,
    String? startupName,
    String? opportunityTitle,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': Timestamp.now(),
    };
    if (note != null) updates['startupNote'] = note;
    if (interviewDate != null) {
      updates['interviewDate'] = Timestamp.fromDate(interviewDate);
    }
    if (status == 'rejected' && rejectionReason != null) {
      updates['rejectionReason'] = rejectionReason;
    }

    await _firestore
        .collection(AppConstants.applicationsCollection)
        .doc(applicationId)
        .update(updates);

    if (status == 'rejected' && applicantId != null) {
      try {
        final ref = _firestore.collection(AppConstants.notificationsCollection).doc();
        await ref.set({
          'userId': applicantId,
          'type': 'application_rejected',
          'title': 'Application update from ${startupName ?? 'a startup'}',
          'body': opportunityTitle != null
              ? 'Your application for "$opportunityTitle" was not successful this time.'
              : 'Your application was not successful this time.',
          'applicationId': applicationId,
          'read': false,
          'createdAt': Timestamp.now(),
        });
      } catch (e) {
        debugPrint('[ApplicationRepository] rejection notification failed: $e');
      }
    }
  }

  // Let a student edit the editable fields of an application they already
  // submitted (cover letter, portfolio link, relevant skills).
  Future<void> updateApplication({
    required String applicationId,
    required String coverLetter,
    String? portfolioUrl,
    List<String> relevantSkills = const [],
  }) async {
    await _firestore
        .collection(AppConstants.applicationsCollection)
        .doc(applicationId)
        .update({
      'coverLetter': coverLetter,
      'portfolioUrl': portfolioUrl,
      'relevantSkills': relevantSkills,
      'updatedAt': Timestamp.now(),
    });
  }

  // Startup schedules a meeting with an accepted applicant. This updates
  // the application doc with the meeting details and drops a notification
  // for the student in the notifications collection.
  Future<void> scheduleMeeting({
    required String applicationId,
    required String applicantId,
    required DateTime meetingDate,
    required String meetingTime,
    required String meetingLocation,
    required String startupName,
    required String opportunityTitle,
  }) async {
    await _firestore
        .collection(AppConstants.applicationsCollection)
        .doc(applicationId)
        .update({
      'meetingDate': Timestamp.fromDate(meetingDate),
      'meetingTime': meetingTime,
      'meetingLocation': meetingLocation,
      'meetingStatus': 'scheduled',
      'updatedAt': Timestamp.now(),
    });

    try {
      final ref = _firestore.collection(AppConstants.notificationsCollection).doc();
      await ref.set({
        'userId': applicantId,
        'type': 'meeting_scheduled',
        'title': 'Meeting scheduled with $startupName',
        'body':
            '$startupName scheduled a meeting with you for "$opportunityTitle" on ${meetingDate.day}/${meetingDate.month}/${meetingDate.year} at $meetingTime.',
        'applicationId': applicationId,
        'read': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('[ApplicationRepository] scheduleMeeting notification failed: $e');
    }
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