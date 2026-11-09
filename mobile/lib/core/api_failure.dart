/// A failed backend call.
sealed class ApiFailure implements Exception {
  const ApiFailure();
}

/// The backend couldn't be reached, or didn't answer within 5 seconds.
class ConnectionFailure extends ApiFailure {
  const ConnectionFailure();
}

/// The backend rejected the request body. [types] are the errors' codes,
/// such as `age_out_of_range`.
class ValidationFailure extends ApiFailure {
  const ValidationFailure(this.types);
  final List<String> types;
}

/// Any other unexpected status.
class ServerFailure extends ApiFailure {
  const ServerFailure(this.statusCode);
  final int statusCode;
}

/// A response did not match the backend's JSON contract.
class UnexpectedResponseFailure extends ApiFailure {
  const UnexpectedResponseFailure();
}
