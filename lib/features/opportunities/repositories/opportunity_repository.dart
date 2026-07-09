import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/opportunity_model.dart';
import '../../../core/constants/app_constants.dart';

class OpportunityRepository {
  final FirebaseFirestore _firestore;

  OpportunityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream of all open opportunities (real-time)
  // NOTE: We intentionally query on a single equality field only
  // (status == 'open') and do NOT chain .orderBy() or additional
  // .where() clauses in Firestore. Combining an equality filter with
  // orderBy on a different field -- or with multiple equality filters --
  // requires a manually-created Firestore composite index. Rather than
  // maintaining up to 8 different composite indexes for every possible
  // combination of category/type/location filters, we fetch the
  // single-field-indexed (automatic, no setup needed) result set and do
  // all filtering + sorting client-side in Dart.
  Stream<List<OpportunityModel>> watchOpenOpportunities({
    String? category,
    String? type,
    String? location,
    String? searchQuery,
  }) {
    final query = _firestore
        .collection(AppConstants.opportunitiesCollection)
        .where('status', isEqualTo: 'open');

    return (() async* {
      try {
        await for (final snapshot in query.snapshots()) {
          var opportunities = snapshot.docs
              .map((doc) => OpportunityModel.fromFirestore(doc))
              .toList();

          if (category != null && category.isNotEmpty) {
            opportunities =
                opportunities.where((o) => o.category == category).toList();
          }
          if (type != null && type.isNotEmpty) {
            opportunities =
                opportunities.where((o) => o.type == type).toList();
          }
          if (location != null && location.isNotEmpty) {
            opportunities =
                opportunities.where((o) => o.location == location).toList();
          }
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            opportunities = opportunities.where((o) {
              return o.title.toLowerCase().contains(q) ||
                  o.startupName.toLowerCase().contains(q) ||
                  o.description.toLowerCase().contains(q) ||
                  o.skills.any((s) => s.toLowerCase().contains(q));
            }).toList();
          }

          opportunities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          yield opportunities;
        }
      } catch (e) {
        debugPrint('[OpportunityRepository] watchOpenOpportunities error: $e');
        yield <OpportunityModel>[];
      }
    })();
  }

  // Stream of a startup's opportunities
  // Same reasoning as above: equality-only query (no orderBy in Firestore),
  // sorted client-side, so no composite index is needed.
  Stream<List<OpportunityModel>> watchStartupOpportunities(String startupId) {
    return (() async* {
      try {
        final stream = _firestore
            .collection(AppConstants.opportunitiesCollection)
            .where('startupId', isEqualTo: startupId)
            .snapshots();
        await for (final snap in stream) {
          final opportunities = snap.docs
              .map((doc) => OpportunityModel.fromFirestore(doc))
              .toList();
          opportunities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          yield opportunities;
        }
      } catch (e) {
        debugPrint('[OpportunityRepository] watchStartupOpportunities error: $e');
        yield <OpportunityModel>[];
      }
    })();
  }

  // Get recommended opportunities for a student (based on skills)
  // Again, single equality field only -- skills matching and sorting
  // happen client-side so no composite/array-contains index is required.
  Future<List<OpportunityModel>> getRecommended({
    required List<String> studentSkills,
    int limit = 5,
  }) async {
    try {
      final snap = await _firestore
          .collection(AppConstants.opportunitiesCollection)
          .where('status', isEqualTo: 'open')
          .get();

      var opportunities =
          snap.docs.map((doc) => OpportunityModel.fromFirestore(doc)).toList();

      if (studentSkills.isNotEmpty) {
        final skillSet = studentSkills.map((s) => s.toLowerCase()).toSet();
        opportunities = opportunities
            .where((o) => o.skills.any(
                (s) => skillSet.contains(s.toLowerCase())))
            .toList();
      }

      opportunities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return opportunities.take(limit).toList();
    } catch (e) {
      debugPrint('[OpportunityRepository] getRecommended error: $e');
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
      debugPrint('[OpportunityRepository] getOpportunityById error: $e');
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

    // Update startup counters. This is best-effort: the opportunity above
    // has already been created successfully, so a failure here should not
    // surface as an error to the user (it would look like the post failed
    // when it actually succeeded, risking an accidental duplicate repost).
    try {
      await _firestore
          .collection(AppConstants.startupsCollection)
          .doc(opportunity.startupId)
          .update({
        'totalOpportunities': FieldValue.increment(1),
        'activeOpportunities': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('[OpportunityRepository] createOpportunity counter update failed: $e');
    }

    return newOpp;
  }

  Future<void> closeOpportunity(String opportunityId, String startupId) async {
    await _firestore
        .collection(AppConstants.opportunitiesCollection)
        .doc(opportunityId)
        .update({'status': 'closed', 'updatedAt': Timestamp.now()});

    try {
      await _firestore
          .collection(AppConstants.startupsCollection)
          .doc(startupId)
          .update({'activeOpportunities': FieldValue.increment(-1)});
    } catch (e) {
      debugPrint('[OpportunityRepository] closeOpportunity counter update failed: $e');
    }
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
