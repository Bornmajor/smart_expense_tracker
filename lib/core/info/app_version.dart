import 'package:equatable/equatable.dart';

/// The version of the app that is installed, so a user (or a tester) can say
/// which one they have.
class AppVersion extends Equatable {
  const AppVersion({required this.name, required this.build});

  /// Shown until the real version has been read.
  static const unknown = AppVersion(name: '', build: '');

  /// The version name, such as "1.0.0" or "1.0.0-dev".
  final String name;

  /// The build number, which goes up with every release.
  final String build;

  /// "1.0.0 (build 12)", or just the name when there is no build number, or
  /// null when the version is not known.
  String? get label {
    if (name.isEmpty) return null;
    return build.isEmpty ? name : '$name (build $build)';
  }

  @override
  List<Object?> get props => [name, build];
}
