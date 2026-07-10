class ErrorBody {
  const ErrorBody({required this.code, required this.message});

  final String code;
  final String message;

  factory ErrorBody.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? error =
        json['error'] as Map<String, dynamic>?;
    if (error == null) {
      throw FormatException('Error response missing error object.');
    }
    final String? code = error['code'] as String?;
    final String? message = error['message'] as String?;
    if (code == null || message == null) {
      throw FormatException('Error response missing code or message.');
    }
    return ErrorBody(code: code, message: message);
  }
}
