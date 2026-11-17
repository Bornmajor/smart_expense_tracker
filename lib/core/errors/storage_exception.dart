/// Thrown by repositories when local storage fails unexpectedly.
/// Use cases catch it and turn it into a `StorageFailure`.
class StorageException implements Exception {
  const StorageException(this.cause);

  final Object cause;

  @override
  String toString() => 'StorageException: $cause';
}
