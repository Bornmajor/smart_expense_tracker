// coverage:ignore-file
//
// TEMPORARY developer tool. Remove before the first public release.
//
// Two stages, so each can be tried on its own:
//   1. Capture: take or choose a photo and see its path, size and a preview.
//   2. Read: feed that photo to ML Kit and see what comes back, before any of
//      our code changes it.
// It is only reachable in debug builds (see the route in app_router.dart and
// the Settings entry).
import 'dart:async';
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

  // Options.
  bool _fullSize = false;
  bool _readNow = false;

  // Stage 1: the captured photo.
  bool _busy = false;
  bool _recovered = false;
  String? _photoPath;
  String? _photoInfo;
  String? _error;

  // Stage 2: what ML Kit returned.
  RecognizedText? _recognized;
  List<String> _rows = const [];
  String _parsed = '';
  String? _report;
  int? _milliseconds;

  @override
  void initState() {
    super.initState();
    // Android can kill the app while the camera is open (the Infinix phone
    // does this about two seconds after the camera opens). The photo is then
    // waiting for us when the app starts again.
    if (Platform.isAndroid) _recoverLostPhoto();
  }

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

  // ---- Stage 1: capture -------------------------------------------------

  Future<void> _recoverLostPhoto() async {
    try {
      final lost = await _picker.retrieveLostData();
      if (lost.isEmpty || !mounted) return;

      final file = lost.file ?? lost.files?.firstOrNull;
      if (file != null) {
        await _useNewPhoto(file.path, recovered: true);
      } else if (lost.exception != null) {
        setState(
          () => _error = 'The camera result was lost: ${lost.exception}',
        );
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _pick(ImageSource source) async {
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
      await _useNewPhoto(file.path, recovered: false);
    } on Exception catch (e) {
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  /// Shows the photo and clears the results of the one before it.
  Future<void> _useNewPhoto(String path, {required bool recovered}) async {
    if (path != _photoPath) _deletePhoto();
    setState(() {
      _busy = false;
      _error = null;
      _photoPath = path;
      _recovered = recovered;
      _photoInfo = null;
      _recognized = null;
      _rows = const [];
      _parsed = '';
      _report = null;
    });

    unawaited(_describe(path));
    if (_readNow) await _read();
  }

  /// The file size and the pixel size, so a blurry or tiny photo is obvious.
  Future<void> _describe(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final info =
          '${(bytes.length / 1024).round()} KB, ${image.width} x ${image.height} px';
      image.dispose();
      if (mounted && _photoPath == path) setState(() => _photoInfo = info);
    } on Exception catch (e) {
      if (mounted && _photoPath == path) {
        setState(() => _photoInfo = 'Could not read the file: $e');
      }
    }
  }

  void _zoom() {
    final path = _photoPath;
    if (path == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 8,
              child: Center(child: Image.file(File(path))),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Stage 2: read ----------------------------------------------------

  /// Reads the photo on screen and fills in every result section.
  Future<void> _read() async {
    final path = _photoPath;
    if (path == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final timer = Stopwatch()..start();
      final recognized = await recognizeWithMlKit(path);
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

      if (!mounted) return;
      setState(() {
        _busy = false;
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
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
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
      ..writeln('Photo: ${_photoInfo ?? '?'}')
      ..writeln()
      ..writeln('--- RAW TEXT FROM ML KIT ---')
      ..writeln(recognized.text)
      ..writeln()
      ..writeln('--- LINES WITH POSITIONS (left,top - right,bottom) ---')
      ..writeln(_linesText(recognized))
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

  // ---- The screen -------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final recognized = _recognized;
    final path = _photoPath;
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
              '1. Take or choose a photo and check it.  '
              '2. Read it with ML Kit.  Debug builds only.',
              style: context.text.bodySmall,
            ),
            const Gap(AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take photo'),
                  ),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Read text straight away'),
              subtitle: const Text(
                'Off: check the photo first, then press Read',
              ),
              value: _readNow,
              onChanged: _busy ? null : (v) => setState(() => _readNow = v),
            ),
            if (_busy) ...[
              const Gap(AppSpacing.md),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_error != null) ...[
              const Gap(AppSpacing.md),
              _Section(title: 'Error', text: _error!),
            ],
            if (path != null) ...[
              const Gap(AppSpacing.md),
              Text('Stage 1: the photo', style: context.text.titleMedium),
              const Gap(AppSpacing.sm),
              GestureDetector(
                onTap: _zoom,
                child: ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: Image.file(
                    File(path),
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Text('Could not show the photo'),
                  ),
                ),
              ),
              const Gap(AppSpacing.xs),
              Text('Tap the photo to zoom', style: context.text.bodySmall),
              const Gap(AppSpacing.sm),
              _Section(
                title: _recovered
                    ? 'Photo (recovered after the app was restarted)'
                    : 'Photo',
                text: 'Path: $path\n${_photoInfo ?? 'Reading the file...'}',
              ),
              FilledButton.icon(
                onPressed: _busy ? null : _read,
                icon: const Icon(Icons.text_snippet_outlined),
                label: Text(recognized == null ? 'Read text' : 'Read again'),
              ),
              const Gap(AppSpacing.lg),
            ],
            if (recognized != null && !_busy) ...[
              Text(
                'Stage 2: what ML Kit returned',
                style: context.text.titleMedium,
              ),
              const Gap(AppSpacing.xs),
              Text('Read in $_milliseconds ms', style: context.text.bodySmall),
              const Gap(AppSpacing.md),
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
