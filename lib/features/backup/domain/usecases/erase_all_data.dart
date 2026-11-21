import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../repositories/backup_repository.dart';
import '../repositories/local_state_reset.dart';

/// Takes the app back to how it was when it was first installed: every
/// expense, recurring expense, budget and category the user made is deleted
/// (the standard categories come back), and so is everything the app remembers:
/// the settings, the app lock, whether the introduction was seen, dismissed
/// alerts and saved exchange rates.
class EraseAllData {
  const EraseAllData(this._repository, this._reset);

  final BackupRepository _repository;
  final LocalStateReset _reset;

  /// Either all of the stored data is deleted or none of it is. What the app
  /// remembers is only cleared once the data is gone.
  Future<Result<void>> call() async {
    try {
      await _repository.eraseAll();
    } on StorageException {
      return const Failure(StorageFailure());
    }
    await _reset.clear();
    return const Success(null);
  }
}
