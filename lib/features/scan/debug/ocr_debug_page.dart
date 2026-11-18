// coverage:ignore-file
//
// TEMPORARY developer tool. Remove before the first public release.
//
// Shows what ML Kit returns for a photo, before any of our code changes it, so
// scanning can be tried on difficult receipts. It is only reachable in debug
// builds (see the route in app_router.dart and the Settings entry).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/utils/money.dart';
import '../data/datasources/ml_kit_recognizer.dart';
import '../data/repositories/ml_kit_receipt_text_reader.dart';
import '../domain/parsing/receipt_rows.dart';
import '../domain/usecases/parse_receipt.dart';
import '../domain/usecases/suggest_category.dart';

class OcrDebugPage extends StatefulWidget {
  const OcrDebugPage({super.key});

  @override
  State<OcrDebugPage> createState() => _OcrDebugPageState();
}

class _OcrDebugPageState extends State<OcrDebugPage> {
  final _picker = ImagePicker();

  bool _busy = false;
  bool _fullSize = false;
  String? _photoPath;
  String? _report;
  String? _error;
  RecognizedText? _recognized;
  List<String> _rows = const [];
  String _parsed = '';
  int? _milliseconds;

  @override
  void dispose() {
    _deletePhoto();
    super.dispose();
  }

  void _deletePhoto() {
    final path = _photoPath;
    if (path != null) {
      try {
        File(path).deleteSync();
      } on Exception {
        // Already gone.
      }
    }
  }

  Future<void> _run(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final file = await _picker.pickImage(
        source: source,
        // The same settings the real scan uses, or the original size to compare.
        maxWidth: _fullSize ? null : 2000,
        imageQuality: _fullSize ? null : 90,
        requestFullMetadata: false,
      );
      if (file == null) {
        setState(() => _busy = false);
        return;
      }

      final timer = Stopwatch()..start();
      final recognized = await recognizeWithMlKit(file.path);
      timer.stop();

      final lines = MlKitReceiptTextReader.linesFrom(recognized);
      final rows = ReceiptRows.build(lines);
      final draft = ParseReceipt()(rows);
      final category = const SuggestCategory()(
        vendor: draft.vendor,
        lines: rows,
        availableIds: const {
          'food',
          'transport',
          'bills',
          'shopping',
          'health',
        },
      );

      final parsed = [
        'Vendor:   ${draft.vendor ?? '(not found)'}',
        'Date:     ${draft.date == null ? '(not found)' : draft.date.toString().split(' ').first}',
        'Total:    ${draft.totalMinor == null ? '(not found)' : Money.format(draft.totalMinor!)}'
            '${draft.totalIsGuess ? '  (a guess: no total label)' : ''}',
        'Category: ${category ?? '(no suggestion)'}',
      ].join('\n');

      _deletePhoto();
      setState(() {
        _busy = false;
        _photoPath = file.path;
        _recognized = recognized;
        _rows = rows;
        _parsed = parsed;
        _milliseconds = timer.elapsedMilliseconds;
        _report = _buildReport(
          recognized,
          rows,
          parsed,
          timer.elapsedMilliseconds,
        );
      });
    } on Exception catch (e) {
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  String _buildReport(
    RecognizedText recognized,
    List<String> rows,
    String parsed,
    int milliseconds,
  ) {
    final b = StringBuffer()
      ..writeln(
        'OCR TEST REPORT (${_fullSize ? 'full size' : 'scan size'}, '
        '$milliseconds ms)',
      )
      ..writeln()
      ..writeln('--- RAW TEXT FROM ML KIT ---')
      ..writeln(recognized.text)
      ..writeln()
      ..writeln('--- LINES WITH POSITIONS (left,top - right,bottom) ---');
    var n = 0;
    for (var i = 0; i < recognized.blocks.length; i++) {
      b.writeln('Block ${i + 1}');
      for (final line in recognized.blocks[i].lines) {
        n++;
        b.writeln('  #$n ${_box(line.boundingBox)} "${line.text}"');
      }
    }
    b
      ..writeln()
      ..writeln('--- ROWS AFTER REBUILDING (what the parser sees) ---');
    for (final row in rows) {
      b.writeln(row);
    }
    b
      ..writeln()
      ..writeln('--- PARSED RESULT ---')
      ..writeln(parsed);
    return b.toString();
  }

  static String _box(Rect r) =>
      '(${r.left.round()},${r.top.round()})-(${r.right.round()},${r.bottom.round()})';

  Future<void> _copy() async {
    final report = _report;
    if (report == null) return;
    await Clipboard.setData(ClipboardData(text: report));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Report copied. Remove personal details before sharing it.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final recognized = _recognized;
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR test (temporary)'),
        actions: [
          if (_report != null)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy report',
              onPressed: _copy,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: AppSpacing.screen.copyWith(bottom: AppSpacing.xxl),
          children: [
            Text(
              'Shows what ML Kit returns, before anything is cleaned up. '
              'Debug builds only.',
              style: context.text.bodySmall,
            ),
            const Gap(AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _run(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take photo'),
                  ),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose photo'),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Original size'),
              subtitle: const Text(
                'Off: same size the real scan uses (2000 px wide)',
              ),
              value: _fullSize,
              onChanged: _busy ? null : (v) => setState(() => _fullSize = v),
            ),
            if (_busy) ...[
              const Gap(AppSpacing.md),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_error != null) ...[
              const Gap(AppSpacing.md),
              _Section(title: 'Error', text: _error!),
            ],
            if (recognized != null && !_busy) ...[
              const Gap(AppSpacing.md),
              if (_photoPath != null)
                ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: Image.file(
                    File(_photoPath!),
                    height: 260,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Text('Could not show the photo'),
                  ),
                ),
              const Gap(AppSpacing.sm),
              Text('Read in $_milliseconds ms', style: context.text.bodySmall),
              const Gap(AppSpacing.lg),
              _Section(
                title: 'Raw text from ML Kit',
                text: recognized.text.isEmpty
                    ? '(nothing was recognized)'
                    : recognized.text,
              ),
              _Section(
                title: 'Lines with positions',
                text: _linesText(recognized),
              ),
              _Section(
                title: 'Rows after rebuilding (what the parser sees)',
                text: _rows.isEmpty ? '(none)' : _rows.join('\n'),
              ),
              _Section(title: 'Parsed result', text: _parsed),
            ],
          ],
        ),
      ),
    );
  }

  String _linesText(RecognizedText recognized) {
    if (recognized.blocks.isEmpty) return '(none)';
    final b = StringBuffer();
    var n = 0;
    for (var i = 0; i < recognized.blocks.length; i++) {
      b.writeln('Block ${i + 1}');
      for (final line in recognized.blocks[i].lines) {
        n++;
        b.writeln('  #$n ${_box(line.boundingBox)} "${line.text}"');
      }
    }
    return b.toString().trimRight();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleSmall),
          const Gap(AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: AppSpacing.card,
            decoration: BoxDecoration(
              color: context.scheme.surfaceContainerHighest,
              borderRadius: AppRadius.mdAll,
            ),
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
