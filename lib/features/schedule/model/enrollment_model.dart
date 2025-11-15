class Enrollment {
  final String enrollmentID;
  final String classID;
  final String title;
  final String description;
  final String languageID;
  final String languageName;
  final String teacherName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int amountPaid;
  final String paymentTransactionId;
  final String enrollmentStatus;
  final String classStatus;
  final DateTime enrolledAt;
  final int totalEnrollments;
  final int capacity;
  final String googleMeetLink;
  final bool canJoinClass;
  final bool isClassStarted;
  final bool isClassFinished;

  Enrollment({
    required this.enrollmentID,
    required this.classID,
    required this.title,
    required this.description,
    required this.languageID,
    required this.languageName,
    required this.teacherName,
    required this.startDateTime,
    required this.endDateTime,
    required this.amountPaid,
    required this.paymentTransactionId,
    required this.enrollmentStatus,
    required this.classStatus,
    required this.enrolledAt,
    required this.totalEnrollments,
    required this.capacity,
    required this.googleMeetLink,
    required this.canJoinClass,
    required this.isClassStarted,
    required this.isClassFinished,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      enrollmentID: json['enrollmentID'] ?? '',
      classID: json['classID'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      languageID: json['languageID'] ?? '',
      languageName: json['languageName'] ?? '',
      teacherName: json['teacherName'] ?? '',
      startDateTime: DateTime.parse(json['startDateTime']),
      endDateTime: DateTime.parse(json['endDateTime']),
      amountPaid: (json['amountPaid'] as num? ?? 0).toInt(),
      paymentTransactionId: json['paymentTransactionId'] ?? '',
      enrollmentStatus: json['enrollmentStatus'] ?? '',
      classStatus: json['classStatus'] ?? '',
      enrolledAt: DateTime.parse(json['enrolledAt']),
      totalEnrollments: json['totalEnrollments'] ?? 0,
      capacity: json['capacity'] ?? 0,
      googleMeetLink: json['googleMeetLink'] ?? '',
      canJoinClass: json['canJoinClass'] ?? false,
      isClassStarted: json['isClassStarted'] ?? false,
      isClassFinished: json['isClassFinished'] ?? false,
    );
  }
}