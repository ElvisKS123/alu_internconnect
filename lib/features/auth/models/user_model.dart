import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'student' | 'startup' | 'admin'
  final String? photoUrl;
  final String? bio;
  final String? location;
  final List<String> skills;
  final String? program; // ALU program
  final int? graduationYear;
  final String? linkedinUrl;
  final String? portfolioUrl;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.photoUrl,
    this.bio,
    this.location,
    this.skills = const [],
    this.program,
    this.graduationYear,
    this.linkedinUrl,
    this.portfolioUrl,
    this.isEmailVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: data['role'] ?? 'student',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      location: data['location'],
      skills: List<String>.from(data['skills'] ?? []),
      program: data['program'],
      graduationYear: data['graduationYear'],
      linkedinUrl: data['linkedinUrl'],
      portfolioUrl: data['portfolioUrl'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'fullName': fullName,
        'role': role,
        'photoUrl': photoUrl,
        'bio': bio,
        'location': location,
        'skills': skills,
        'program': program,
        'graduationYear': graduationYear,
        'linkedinUrl': linkedinUrl,
        'portfolioUrl': portfolioUrl,
        'isEmailVerified': isEmailVerified,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  UserModel copyWith({
    String? fullName,
    String? photoUrl,
    String? bio,
    String? location,
    List<String>? skills,
    String? program,
    int? graduationYear,
    String? linkedinUrl,
    String? portfolioUrl,
    bool? isEmailVerified,
  }) {
    return UserModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      skills: skills ?? this.skills,
      program: program ?? this.program,
      graduationYear: graduationYear ?? this.graduationYear,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get firstName => fullName.split(' ').first;

  bool get isStudent => role == 'student';
  bool get isStartup => role == 'startup';
  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [id, email, fullName, role, skills];
}
