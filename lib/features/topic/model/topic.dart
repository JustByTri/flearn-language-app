class TopicResponse {
  final Meta meta;
  final String status;
  final int code;
  final String message;
  final List<TopicModel> data;
  final dynamic errors;

  TopicResponse({
    required this.meta,
    required this.status,
    required this.code,
    required this.message,
    required this.data,
    this.errors,
  });

  factory TopicResponse.fromJson(Map<String, dynamic> json) {
    return TopicResponse(
      meta: Meta.fromJson(json['meta']),
      status: json['status'],
      code: json['code'],
      message: json['message'],
      data: (json['data'] as List)
          .map((e) => TopicModel.fromJson(e))
          .toList(),
      errors: json['errors'],
    );
  }
}

class Meta {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  Meta({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      page: json['page'],
      pageSize: json['pageSize'],
      totalItems: json['totalItems'],
      totalPages: json['totalPages'],
    );
  }
}

class TopicModel {
  final String topicId;
  final String topicName;
  final String topicDescription;
  final String imageUrl;

  TopicModel({
    required this.topicId,
    required this.topicName,
    required this.topicDescription,
    required this.imageUrl,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      topicId: json['topicId']?.toString() ?? '',
      topicName: json['topicName']?.toString() ?? '',
      topicDescription: json['topicDescription']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }
}