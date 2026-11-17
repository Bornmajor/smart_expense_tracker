import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/onboarding_repository.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._repository) : super(const OnboardingState());

  final OnboardingRepository _repository;

  void pageChanged(int page) => emit(state.copyWith(page: page));

  /// Marks onboarding as done (used by both "Get started" and "Skip").
  Future<void> complete() async {
    await _repository.complete();
    emit(state.copyWith(completed: true));
  }
}
