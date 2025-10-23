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
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      enrollmentID: json['enrollmentID'],
      classID: json['classID'],
      title: json['title'],
      description: json['description'],
      languageID: json['languageID'],
      languageName: json['languageName'],
      teacherName: json['teacherName'],
      startDateTime: DateTime.parse(json['startDateTime']),
      endDateTime: DateTime.parse(json['endDateTime']),
      amountPaid: (json['amountPaid'] as num).toInt(),
      paymentTransactionId: json['paymentTransactionId'],
      enrollmentStatus: json['enrollmentStatus'],
      classStatus: json['classStatus'],
    );
  }
}