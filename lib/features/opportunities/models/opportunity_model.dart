import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class OpportunityModel extends Equatable {
  final String id;
  final String startupId;
  final String startupName;
  final String? startupLogoUrl;
  final String title;
  final String description;
  final String category;
  final List<String> skills;
  final List<String> tags;
  final String type; // Part-time | Full-time | Volunteer | Project-based
  final String location; // On-campus | Remote | Hybrid
  final String? hoursPerWeek;
  final String? duration;
  final bool isPaid;
  final String? compensation;
  final int applicationCount;
  final String status; // open | closed | draft
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OpportunityModel({
    required this.id,
    required this.startupId,
    required this.startupName,
    this.startupLogoUrl,
    required this.title,
    required this.description,
    required this.category,
    this.skills = const [],
    this.tags = const [],
    required this.type,
    required this.location,
    this.hoursPerWeek,
    this.duration,
    this.isPaid = false,
    this.compensation,
    this.applicationCount = 0,
    this.status = 'open',
    this.deadline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OpportunityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OpportunityModel(
      id: doc.id,
      startupId: data['startupId'] ?? '',
      startupName: data['startupName'] ?? '',
      startupLogoUrl: data['startupLogoUrl'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      skills: List<String>.from(data['skills'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      type: data['type'] ?? 'Part-time',
      location: data['location'] ?? 'On-campus',
      hoursPerWeek: data['hoursPerWeek'],
      duration: data['duration'],
      isPaid: data['isPaid'] ?? false,
      compensation: data['compensation'],
      applicationCount: data['applicationCount'] ?? 0,
      status: data['status'] ?? 'open',
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'startupId': startupId,
        'startupName': startupName,
        'startupLogoUrl': startupLogoUrl,
        'title': title,
        'description': description,
        'category': category,
        'skills': skills,
        'tags': tags,
        'type': type,
        'location': location,
        'hoursPerWeek': hoursPerWeek,
        'duration': duration,
        'isPaid': isPaid,
        'compensation': compensation,
        'applicationCount': applicationCount,
        'status': status,
        'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 7) return '${(difference.inDays / 7).floor()}w ago';
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    return 'Just now';
  }

  @override
  List<Object?> get props => [id, startupId, title, status];
}
