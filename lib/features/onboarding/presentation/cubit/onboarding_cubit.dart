import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/repositories/onboarding_repository.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._repository, this._profile)
    : super(const OnboardingState());

  final OnboardingRepository _repository;
  final ProfileRepository _profile;

  void pageChanged(int page) => emit(state.copyWith(page: page));

  /// Marks onboarding as done (used by both "Get started" and "Skip").
  /// [name] is the first name typed on the last screen, if any.
  Future<void> complete({String name = ''}) async {
    if (name.trim().isNotEmpty) await _profile.setName(name);
    await _repository.complete();
    emit(state.copyWith(completed: true));
  }
}
