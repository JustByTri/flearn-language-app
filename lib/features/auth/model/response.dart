class ResponseModel<T> {
  final int statusCode;
  final String message;
  final bool isSuccess;
  final T result;

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
    return ResponseModel<T>(
      statusCode: json['statusCode'],
      message: json['message'],
      isSuccess: json['isSuccess'],
      result: fromJsonT(json['result']),
    );
  }
}