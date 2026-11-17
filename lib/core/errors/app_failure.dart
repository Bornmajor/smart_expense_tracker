import 'package:equatable/equatable.dart';

/// Expected failure outcomes returned by use cases.
sealed class AppFailure extends Equatable {
  const AppFailure();
}

/// One or more business rules were broken.
/// Maps a field name to an error code (the UI turns codes into text).
final class ValidationFailure extends AppFailure {
  const ValidationFailure(this.fieldErrors);

  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [fieldErrors];
}

/// Reading from or writing to local storage failed.
final class StorageFailure extends AppFailure {
  const StorageFailure();

  @override
  List<Object?> get props => [];
}
