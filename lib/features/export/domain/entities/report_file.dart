import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A finished report, ready to be shared.
class ReportFile extends Equatable {
  const ReportFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  /// Including the extension, such as "spendwise-iq-2026-11.pdf".
  final String name;
  final String mimeType;
  final Uint8List bytes;

  @override
  List<Object?> get props => [name, mimeType, bytes];
}
