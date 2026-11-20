import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/recurring_repository.dart';
import 'recurring_state.dart';

/// The list of recurring rules.
class RecurringCubit extends Cubit<RecurringState> {
  RecurringCubit(RecurringRepository repository)
    : super(const RecurringLoading()) {
    _subscription = repository.watchAll().listen(
      (rules) => emit(RecurringLoaded(rules)),
      onError: (Object _) => emit(const RecurringLoadFailed()),
    );
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
