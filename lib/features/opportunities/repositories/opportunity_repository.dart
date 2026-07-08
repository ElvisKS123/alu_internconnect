import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/opportunity_model.dart';
import '../../../core/constants/app_constants.dart';

class OpportunityRepository {
  final FirebaseFirestore _firestore;

  OpportunityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream of all open opportunities (real-time)
  Stream<List<OpportunityModel>> watchOpenOpportunities({
    String? category,
    String? type,
    String? location,
    String? searchQuery,
  }) {
    Query query = _firestore
        .collection(AppConstants.opportunitiesCollection)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }
    if (location != null && location.isNotEmpty) {
      query = query.where('location', isEqualTo: location);
    }

    // Use an async* stream to catch Firestore errors (eg. permission-denied)
    // and yield an empty list instead of letting the stream error out.
    return (() async* {
      try {
        await for (final snapshot in query.snapshots()) {
          var opportunities = snapshot.docs
              .map((doc) => OpportunityModel.fromFirestore(doc))
              .toList();

          if (searchQuery != null && searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            opportunities = opportunities.where((o) {
              return o.title.toLowerCase().contains(q) ||
                  o.startupName.toLowerCase().contains(q) ||
                  o.description.toLowerCase().contains(q) ||
                  o.skills.any((s) => s.toLowerCase().contains(q));
            }).toList();
          }
          yield opportunities;
        }
      } catch (e) {
        // Log and yield empty list so UI can render.
        try {
          // StartupDebug may not be imported here; use print as fallback.
          // But keep minimal dependency: print the error.
          print('[OpportunityRepository] watchOpenOpportunities error: $e');
        } catch (_) {}
        yield <OpportunityModel>[];
      }
    })();
  }

  // Stream of a startup's opportunities
  Stream<List<OpportunityModel>> watchStartupOpportunities(String startupId) {
    return (() async* {
      try {
        final stream = _firestore
            .collection(AppConstants.opportunitiesCollection)
            .where('startupId', isEqualTo: startupId)
            .orderBy('createdAt', descending: true)
            .snapshots();
        await for (final snap in stream) {
          yield snap.docs.map((doc) => OpportunityModel.fromFirestore(doc)).toList();
        }
      } catch (e) {
        print('[OpportunityRepository] watchStartupOpportunities error: $e');
        yield <OpportunityModel>[];
      }
    })();
  }

  // Get recommended opportunities for a student (based on skills)
  Future<List<OpportunityModel>> getRecommended({
    required List<String> studentSkills,
    int limit = 5,
  }) async {
    try {
    if (studentSkills.isEmpty) {
      // Return latest if no skills
      final snap = await _firestore
          .collection(AppConstants.opportunitiesCollection)
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((doc) => OpportunityModel.fromFirestore(doc)).toList();
    }

    // Firestore array-contains-any allows up to 10 values
    final skills = studentSkills.take(10).toList();
    final snap = await _firestore
        .collection(AppConstants.opportunitiesCollection)
        .where('status', isEqualTo: 'open')
        .where('skills', arrayContainsAny: skills)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((doc) => OpportunityModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('[OpportunityRepository] getRecommended error: $e');
      return <OpportunityModel>[];
    }
  }

  Future<OpportunityModel?> getOpportunityById(String id) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.opportunitiesCollection)
          .doc(id)
          .get();
      if (!doc.exists) return null;
      return OpportunityModel.fromFirestore(doc);
    } catch (e) {
      print('[OpportunityRepository] getOpportunityById error: $e');
      return null;
    }
  }

  Future<OpportunityModel> createOpportunity(OpportunityModel opportunity) async {
    final ref = _firestore
        .collection(AppConstants.opportunitiesCollection)
        .doc();

    final newOpp = OpportunityModel(
      id: ref.id,
      startupId: opportunity.startupId,
      startupName: opportunity.startupName,
      startupLogoUrl: opportunity.startupLogoUrl,
      title: opportunity.title,
      description: opportunity.description,
      category: opportunity.category,
      skills: opportunity.skills,
      tags: opportunity.tags,
      type: opportunity.type,
      location: opportunity.location,
      hoursPerWeek: opportunity.hoursPerWeek,
      duration: opportunity.duration,
      isPaid: opportunity.isPaid,
      compensation: opportunity.compensation,
      status: 'open',
      deadline: opportunity.deadline,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.set(newOpp.toFirestore());

    // Update startup counters
    await _firestore
        .collection(AppConstants.startupsCollection)
        .doc(opportunity.startupId)
        .update({
      'totalOpportunities': FieldValue.increment(1),
      'activeOpportunities': FieldValue.increment(1),
    });

    return newOpp;
  }

  Future<void> closeOpportunity(String opportunityId, String startupId) async {
    await _firestore
        .collection(AppConstants.opportunitiesCollection)
        .doc(opportunityId)
        .update({'status': 'closed', 'updatedAt': Timestamp.now()});

    await _firestore
        .collection(AppConstants.startupsCollection)
        .doc(startupId)
        .update({'activeOpportunities': FieldValue.increment(-1)});
  }

  // Bookmark / unbookmark
  Future<void> toggleBookmark({
    required String userId,
    required String opportunityId,
    required bool isBookmarked,
  }) async {
    final ref = _firestore
        .collection(AppConstants.bookmarksCollection)
        .doc('${userId}_$opportunityId');

    if (isBookmarked) {
      await ref.delete();
    } else {
      await ref.set({
        'userId': userId,
        'opportunityId': opportunityId,
        'createdAt': Timestamp.now(),
      });
    }
  }

  Stream<List<String>> watchBookmarks(String userId) {
    return _firestore
        .collection(AppConstants.bookmarksCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => doc['opportunityId'] as String).toList());
  }
}
