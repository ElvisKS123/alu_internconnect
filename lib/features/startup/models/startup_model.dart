import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class StartupModel extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String tagline;
  final String description;
  final String? logoUrl;
  final String? bannerUrl;
  final String category; // Engineering, Design, etc.
  final List<String> tags;
  final String verificationStatus; // pending | approved | rejected
  final String? verificationNote;
  final String? aluRecognitionProof; // URL to proof doc
  final String? websiteUrl;
  final String? linkedinUrl;
  final String? instagramUrl;
  final String? email;
  final int teamSize;
  final int totalOpportunities;
  final int activeOpportunities;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StartupModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.tagline,
    required this.description,
    this.logoUrl,
    this.bannerUrl,
    required this.category,
    this.tags = const [],
    required this.verificationStatus,
    this.verificationNote,
    this.aluRecognitionProof,
    this.websiteUrl,
    this.linkedinUrl,
    this.instagramUrl,
    this.email,
    this.teamSize = 1,
    this.totalOpportunities = 0,
    this.activeOpportunities = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StartupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StartupModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      tagline: data['tagline'] ?? '',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'],
      bannerUrl: data['bannerUrl'],
      category: data['category'] ?? 'Other',
      tags: List<String>.from(data['tags'] ?? []),
      verificationStatus: data['verificationStatus'] ?? 'pending',
      verificationNote: data['verificationNote'],
      aluRecognitionProof: data['aluRecognitionProof'],
      websiteUrl: data['websiteUrl'],
      linkedinUrl: data['linkedinUrl'],
      instagramUrl: data['instagramUrl'],
      email: data['email'],
      teamSize: data['teamSize'] ?? 1,
      totalOpportunities: data['totalOpportunities'] ?? 0,
      activeOpportunities: data['activeOpportunities'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ownerId': ownerId,
        'name': name,
        'tagline': tagline,
        'description': description,
        'logoUrl': logoUrl,
        'bannerUrl': bannerUrl,
        'category': category,
        'tags': tags,
        'verificationStatus': verificationStatus,
        'verificationNote': verificationNote,
        'aluRecognitionProof': aluRecognitionProof,
        'websiteUrl': websiteUrl,
        'linkedinUrl': linkedinUrl,
        'instagramUrl': instagramUrl,
        'email': email,
        'teamSize': teamSize,
        'totalOpportunities': totalOpportunities,
        'activeOpportunities': activeOpportunities,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  bool get isApproved => verificationStatus == 'approved';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';


  @override
  List<Object?> get props => [id, name, verificationStatus];
}
