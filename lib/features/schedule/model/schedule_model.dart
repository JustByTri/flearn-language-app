class TeacherClassResponse {
  final bool success;
  final String message;
  final List<TeacherClass> data;
  final Pagination pagination;

  TeacherClassResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory TeacherClassResponse.fromJson(Map<String, dynamic> json) {
    return TeacherClassResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => TeacherClass.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class TeacherClass {
  final String classID;
  final String title;
  final String description;
  final String languageID;
  final String languageName;
  final String teacherName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int minStudents;
  final int capacity;
  final double pricePerStudent;
  final String status;
  final int currentEnrollments;
  final int availableSlots;
  final DateTime createdAt;
  final bool isEnrollmentOpen;

  TeacherClass({
    required this.classID,
    required this.title,
    required this.description,
    required this.languageID,
    required this.languageName,
    required this.teacherName,
    required this.startDateTime,
    required this.endDateTime,
    required this.minStudents,
    required this.capacity,
    required this.pricePerStudent,
    required this.status,
    required this.currentEnrollments,
    required this.availableSlots,
    required this.createdAt,
    required this.isEnrollmentOpen,
  });

  factory TeacherClass.fromJson(Map<String, dynamic> json) {
    return TeacherClass(
      classID: json['classID'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      languageID: json['languageID'] ?? '',
      languageName: json['languageName'] ?? '',
      teacherName: json['teacherName'] ?? '',
      startDateTime: DateTime.parse(json['startDateTime']),
      endDateTime: DateTime.parse(json['endDateTime']),
      minStudents: json['minStudents'] ?? 0,
      capacity: json['capacity'] ?? 0,
      pricePerStudent: (json['pricePerStudent'] as num).toDouble(),
      status: json['status'] ?? '',
      currentEnrollments: json['currentEnrollments'] ?? 0,
      availableSlots: json['availableSlots'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      isEnrollmentOpen: json['isEnrollmentOpen'] ?? false,
    );
  }
  
  // Helpers to move logic from the View
  bool get isFull => availableSlots <= 0;
  bool get isAlmostFull => !isFull && capacity > 0 && (currentEnrollments / capacity) >= 0.8;
  int get durationInMinutes => endDateTime.difference(startDateTime).inMinutes;
}

class Pagination {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  Pagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      totalItems: json['totalItems'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
