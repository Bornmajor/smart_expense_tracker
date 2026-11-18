import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({required this.id, required this.name});

  /// The category that takes over the expenses of a deleted category.
  /// It is created with the database and can be renamed but never deleted.
  static const fallbackId = 'other';

  final String id;
  final String name;

  bool get isFallback => id == fallbackId;

  @override
  List<Object?> get props => [id, name];
}
