class AppConstants {
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String startupsCollection = 'startups';
  static const String opportunitiesCollection = 'opportunities';
  static const String applicationsCollection = 'applications';
  static const String bookmarksCollection = 'bookmarks';
  static const String notificationsCollection = 'notifications';
  static const String verificationsCollection = 'startup_verifications';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';

  // User Roles
  static const String roleStudent = 'student';
  static const String roleStartup = 'startup';
  static const String roleAdmin = 'admin';

  // Opportunity Types
  static const String typePartTime = 'Part-time';
  static const String typeFullTime = 'Full-time';
  static const String typeVolunteer = 'Volunteer';
  static const String typeProject = 'Project-based';

  // Application Status
  static const String statusPending = 'pending';
  static const String statusUnderReview = 'under_review';
  static const String statusShortlisted = 'shortlisted';
  static const String statusAccepted = 'accepted';
  static const String statusRejected = 'rejected';
  static const String statusClosed = 'closed';

  // Startup Verification Status
  static const String verificationPending = 'pending';
  static const String verificationApproved = 'approved';
  static const String verificationRejected = 'rejected';

  // Opportunity Categories
  static const List<String> categories = [
    'Engineering',
    'Design',
    'Marketing',
    'Data',
    'Operations',
    'Research',
    'Business',
    'Content',
    'Community',
    'Other',
  ];

  // Skills list
  static const List<String> popularSkills = [
    'Flutter', 'React', 'Python', 'UI/UX Design', 'Figma',
    'Firebase', 'Node.js', 'Marketing', 'Content Writing',
    'Data Analysis', 'Project Management', 'Social Media',
    'Business Development', 'Research', 'Graphic Design',
    'Video Editing', 'Community Management', 'Sales',
  ];

  // ALU domains allowed for student verification
  static const List<String> aluEmailDomains = [
    'alustudent.com',
    'alueducation.com',
  ];

  // Pagination
  static const int pageSize = 10;
}
