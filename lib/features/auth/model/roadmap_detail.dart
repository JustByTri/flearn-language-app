class RoadmapDetail {
  final String roadmapDetailId;
  final String courseId;
  final String courseName;
  final String courseDescription;
  final DateTime createdAt;

  RoadmapDetail({
    required this.roadmapDetailId,
    required this.courseId,
    required this.courseName,
    required this.courseDescription,
    required this.createdAt,
  });

  factory RoadmapDetail.fromJson(Map<String, dynamic> json) {
    return RoadmapDetail(
      roadmapDetailId: json['roadmapDetailId'],
      courseId: json['courseId'],
      courseName: json['courseName'],
      courseDescription: json['courseDescription'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class RoadmapDetailsResponse {
  final String learnerLanguageId;
  final String roadmapId;
  final List<RoadmapDetail> details;

  RoadmapDetailsResponse({
    required this.learnerLanguageId,
    required this.roadmapId,
    required this.details,
  });

  factory RoadmapDetailsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return RoadmapDetailsResponse(
      learnerLanguageId: data['learnerLanguageId'],
      roadmapId: data['roadmapId'],
      details: (data['details'] as List)
          .map((e) => RoadmapDetail.fromJson(e))
          .toList(),
    );
  }
}