class AppException implements Exception {
  const AppException(
    this.message, {
    this.code,
    this.statusCode,
    this.originalError,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Object? originalError;

  @override
  String toString() {
    return 'AppException(message: $message, code: $code, statusCode: $statusCode)';
  }
}
