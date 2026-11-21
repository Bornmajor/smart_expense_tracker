import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/profile_repository.dart';

/// The user's first name, kept up to date for the greeting and Settings. The
/// state is the name, empty when none was given.
class ProfileCubit extends Cubit<String> {
  ProfileCubit(this._repository) : super(_repository.name);

  final ProfileRepository _repository;

  Future<void> setName(String name) async {
    await _repository.setName(name);
    emit(_repository.name);
  }
}
