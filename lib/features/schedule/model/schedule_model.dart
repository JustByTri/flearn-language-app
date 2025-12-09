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

class ClassSearchResult {
  final String classID;
  final String title;
  final String description;
  final String languageID;
  final String languageName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int capacity;
  final double pricePerStudent;
  final String googleMeetLink;
  final String status;
  final int currentEnrollments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? teacherName;
  final String? teacherAvatar;
  final String? programName;

  // NEW: fields present in API response
  final int minStudents;
  final int availableSlots;
  final bool isEnrollmentOpen;

  ClassSearchResult({
    required this.classID,
    required this.title,
    required this.description,
    required this.languageID,
    required this.languageName,
    required this.startDateTime,
    required this.endDateTime,
    required this.capacity,
    required this.pricePerStudent,
    required this.googleMeetLink,
    required this.status,
    required this.currentEnrollments,
    required this.createdAt,
    required this.updatedAt,
    this.teacherName,
    this.teacherAvatar,
    this.programName,
    required this.minStudents,
    required this.availableSlots,
    required this.isEnrollmentOpen,
  });

  factory ClassSearchResult.fromJson(Map<String, dynamic> json) {
    final capacity = (json['capacity'] as num?)?.toInt() ?? 0;
    final current = (json['currentEnrollments'] as num?)?.toInt() ?? 0;
    final rawSlots = json['availableSlots'];

    return ClassSearchResult(
      classID: json['classID']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      languageID: json['languageID']?.toString() ?? '',
      languageName: json['languageName']?.toString() ?? '',
      startDateTime: DateTime.parse(json['startDateTime']),
      endDateTime: DateTime.parse(json['endDateTime']),
      capacity: capacity,
      pricePerStudent: (json['pricePerStudent'] as num?)?.toDouble() ?? 0,
      googleMeetLink: json['googleMeetLink']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      currentEnrollments: current,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      teacherName: json['teacherName']?.toString(),
      teacherAvatar: json['teacherAvatar']?.toString(),
      programName: json['programName']?.toString(),
      minStudents: (json['minStudents'] as num?)?.toInt() ?? 0,
      availableSlots: rawSlots is num ? rawSlots.toInt() : (capacity - current).clamp(0, capacity),
      isEnrollmentOpen: json['isEnrollmentOpen'] as bool? ?? true,
    );
  }

  // Helpers to move logic from the View
  bool get isFull => availableSlots <= 0;
  bool get isAlmostFull => !isFull && capacity > 0 && (currentEnrollments / capacity) >= 0.8;
  int get durationInMinutes => endDateTime.difference(startDateTime).inMinutes;
}

class Teacher {
  final String teacherId;
  final String language;
  final String fullName;
  final String dateOfBirth;
  final String bio;
  final String avatar;
  final String email;
  final String phoneNumber;
  final String proficiencyCode;
  final double averageRating;
  final int reviewCount;
  final String meetingUrl;

  Teacher({
    required this.teacherId,
    required this.language,
    required this.fullName,
    required this.dateOfBirth,
    required this.bio,
    required this.avatar,
    required this.email,
    required this.phoneNumber,
    required this.proficiencyCode,
    required this.averageRating,
    required this.reviewCount,
    required this.meetingUrl,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      teacherId: json['teacherId'] ?? '',
      language: json['language'] ?? '',
      fullName: json['fullName'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      bio: json['bio'] ?? '',
      avatar: json['avatar'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      proficiencyCode: json['proficiencyCode'] ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      meetingUrl: json['meetingUrl'] ?? '',
    );
  }
}

class Program {
  final String programId;
  final String name;
  final String description;

  Program({
    required this.programId,
    required this.name,
    required this.description,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      programId: json['programId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
