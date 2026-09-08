class RawanaAuthException implements Exception {
  final String messageKey;
  final String? message;

  RawanaAuthException(this.messageKey, [this.message]);

  @override
  String toString() => message ?? messageKey;
}
