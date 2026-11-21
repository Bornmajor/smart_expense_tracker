import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/repositories/backup_history.dart';
import '../../domain/usecases/erase_all_data.dart';

enum EraseStatus { idle, working, done, failed }

class EraseDataState extends Equatable {
  const EraseDataState({this.status = EraseStatus.idle, this.lastBackupAt});

  final EraseStatus status;

  /// When a backup file was last made, or null if never. Shown as a reminder.
  final DateTime? lastBackupAt;

  EraseDataState copyWith(EraseStatus status) =>
      EraseDataState(status: status, lastBackupAt: lastBackupAt);

  @override
  List<Object?> get props => [status, lastBackupAt];
}

/// Deletes all the user's data once they have confirmed on the screen.
class EraseDataCubit extends Cubit<EraseDataState> {
  EraseDataCubit(this._erase, BackupHistory history)
    : super(EraseDataState(lastBackupAt: history.lastBackupAt()));

  final EraseAllData _erase;

  Future<void> erase() async {
    if (state.status == EraseStatus.working) return;
    emit(state.copyWith(EraseStatus.working));
    switch (await _erase()) {
      case Success():
        emit(state.copyWith(EraseStatus.done));
      case Failure():
        emit(state.copyWith(EraseStatus.failed));
    }
  }

  /// Lets the screen try again after a failure.
  void acknowledgeFailure() => emit(state.copyWith(EraseStatus.idle));
}
