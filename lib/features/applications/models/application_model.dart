import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ApplicationModel extends Equatable {
  final String id;
  final String opportunityId;
  final String opportunityTitle;
  final String startupId;
  final String startupName;
  final String? startupLogoUrl;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String? applicantPhotoUrl;
  final String coverLetter;
  final String? portfolioUrl;
  final String? resumeUrl;
  final List<String> relevantSkills;
  final String status; // pending | under_review | shortlisted | accepted | rejected | closed
  final String? startupNote; // feedback from startup
  final DateTime? interviewDate;
  final DateTime appliedAt;
  final DateTime updatedAt;

  const ApplicationModel({
    required this.id,
    required this.opportunityId,
    required this.opportunityTitle,
    required this.startupId,
    required this.startupName,
    this.startupLogoUrl,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    this.applicantPhotoUrl,
    required this.coverLetter,
    this.portfolioUrl,
    this.resumeUrl,
    this.relevantSkills = const [],
    this.status = 'pending',
    this.startupNote,
    this.interviewDate,
    required this.appliedAt,
    required this.updatedAt,
  });

  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ApplicationModel(
      id: doc.id,
      opportunityId: data['opportunityId'] ?? '',
      opportunityTitle: data['opportunityTitle'] ?? '',
      startupId: data['startupId'] ?? '',
      startupName: data['startupName'] ?? '',
      startupLogoUrl: data['startupLogoUrl'],
      applicantId: data['applicantId'] ?? '',
      applicantName: data['applicantName'] ?? '',
      applicantEmail: data['applicantEmail'] ?? '',
      applicantPhotoUrl: data['applicantPhotoUrl'],
      coverLetter: data['coverLetter'] ?? '',
      portfolioUrl: data['portfolioUrl'],
      resumeUrl: data['resumeUrl'],
      relevantSkills: List<String>.from(data['relevantSkills'] ?? []),
      status: data['status'] ?? 'pending',
      startupNote: data['startupNote'],
      interviewDate: (data['interviewDate'] as Timestamp?)?.toDate(),
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'opportunityId': opportunityId,
        'opportunityTitle': opportunityTitle,
        'startupId': startupId,
        'startupName': startupName,
        'startupLogoUrl': startupLogoUrl,
        'applicantId': applicantId,
        'applicantName': applicantName,
        'applicantEmail': applicantEmail,
        'applicantPhotoUrl': applicantPhotoUrl,
        'coverLetter': coverLetter,
        'portfolioUrl': portfolioUrl,
        'resumeUrl': resumeUrl,
        'relevantSkills': relevantSkills,
        'status': status,
        'startupNote': startupNote,
        'interviewDate': interviewDate != null ? Timestamp.fromDate(interviewDate!) : null,
        'appliedAt': Timestamp.fromDate(appliedAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  String get statusDisplay {
    switch (status) {
      case 'pending': return 'Pending';
      case 'under_review': return 'Under Review';
      case 'shortlisted': return 'Shortlisted';
      case 'accepted': return 'Accepted';
      case 'rejected': return 'Rejected';
      case 'closed': return 'Closed';
      default: return status;
    }
  }

  String get timeAgo {
    final difference = DateTime.now().difference(appliedAt);
    if (difference.inDays > 7) return '${(difference.inDays / 7).floor()} week${difference.inDays > 13 ? 's' : ''} ago';
    if (difference.inDays > 0) return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    return 'Just now';
  }

  @override
  List<Object?> get props => [id, opportunityId, applicantId, status];
}
