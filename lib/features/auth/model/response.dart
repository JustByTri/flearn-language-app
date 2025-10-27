class ResponseModel<T> {
  final int? statusCode;
  final String? message;
  final bool? isSuccess;
  final T? result;

  ResponseModel({
    required this.statusCode,
    required this.message,
    required this.isSuccess,
    required this.result,
  });

  factory ResponseModel.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    // Hỗ trợ nhiều dạng response từ backend:
    // - { success: true, code: 200, message: ..., data: {...} }
    // - { isSuccess: true, statusCode: 200, message: ..., result: {...} }
    final int? statusCode = json['code'] ?? json['statusCode'];
    final bool? isSuccess = json['success'] ?? json['isSuccess'];
    final String? message = json['message']?.toString();

    // Lấy object data/result
    dynamic payload = json['data'] ?? json['result'];

    T? result;
    if (payload != null) {
      // Nếu payload đã là map -> chuyển sang T
      if (payload is Map<String, dynamic>) {
        result = fromJsonT(payload);
      } else {
        // Nếu payload là nested object dưới key 'data' (ví dụ khi data chứa meta)
        // cố gắng lấy data.data hoặc data['data']
        try {
          if (payload is Map) {
            result = fromJsonT(Map<String, dynamic>.from(payload));
          }
        } catch (e) {
          result = null;
        }
      }
    }

    return ResponseModel<T>(
      statusCode: statusCode,
      message: message,
      isSuccess: isSuccess,
      result: result,
    );
  }
}