import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/expenses/domain/usecases/vendor_category_memory.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_expense_tracker/app/app_routes.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/ocr_line.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/receipt_source.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/scan_result.dart';
import 'package:smart_expense_tracker/features/scan/domain/scan_exception.dart';
import 'package:smart_expense_tracker/features/scan/domain/usecases/scan_receipt.dart';
import 'package:smart_expense_tracker/features/scan/presentation/cubit/scan_cubit.dart';
import 'package:smart_expense_tracker/features/scan/presentation/pages/scan_page.dart';

import '../../../../support/fakes.dart';

/// The scan screen on its own, so every state can be reached, including the
/// camera preview that the app does not offer yet.
void main() {
  late FakeReceiptPhotoSource photos;
  late FakeReceiptTextReader reader;
  late ScanCubit cubit;

  /// Opens the scan screen from a "Home" screen, as the app does.
  Future<void> openScan(WidgetTester tester, ReceiptSource source) async {
    cubit = ScanCubit(
      ScanReceipt(
        photos: photos,
        reader: reader,
        categories: FakeCategoryRepository(),
        memory: VendorCategoryMemory(FakeExpenseRepository()),
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/scan'),
                child: const Text('Home'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/scan',
          builder: (context, state) => BlocProvider(
            // Like the app: the cubit closes when the route is left.
            create: (_) => cubit,
            child: ScanPage(source: source),
          ),
        ),
        GoRoute(
          path: AppRoutes.addExpense,
          builder: (context, state) {
            final scan = state.extra;
            return Scaffold(
              appBar: AppBar(title: const Text('Form')),
              body: Text(
                scan is ScanResult
                    ? 'FORM with ${scan.photoPath}'
                    : 'FORM empty',
              ),
            );
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.tap(find.text('Home'));
    await tester.pump();
  }

  setUp(() {
    photos = FakeReceiptPhotoSource(path: '/tmp/a.jpg');
    reader = FakeReceiptTextReader([
      const OcrLine(
        text: 'Corner Cafe',
        left: 0,
        top: 0,
        right: 100,
        bottom: 20,
      ),
    ]);
  });

  group('while it works', () {
    testWidgets('says the gallery is opening', (tester) async {
      final slow = _SlowPhotoSource();
      photos = slow;

      await openScan(tester, ReceiptSource.file);

      expect(find.text('Opening your photos...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      slow.opened.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('says the camera is opening', (tester) async {
      final slow = _SlowPhotoSource();
      photos = slow;

      await openScan(tester, ReceiptSource.camera);

      expect(find.text('Opening the camera...'), findsOneWidget);
      slow.opened.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('says it is reading, and that nothing leaves the phone', (
      tester,
    ) async {
      final slow = _SlowReader(reader.lines);
      reader = slow;

      await openScan(tester, ReceiptSource.file);
      await tester.pump();

      expect(find.text('Reading your receipt...'), findsOneWidget);
      expect(find.text('Everything stays on your phone.'), findsOneWidget);
      slow.finished.complete();
      await tester.pumpAndSettle();
    });
  });

  group('a camera photo', () {
    testWidgets('is previewed with Use this photo and Retake', (tester) async {
      await openScan(tester, ReceiptSource.camera);
      await tester.pumpAndSettle();

      expect(find.text('Use this photo'), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(reader.readPaths, isEmpty, reason: 'not read until confirmed');
    });

    testWidgets('is read when the user taps Use this photo', (tester) async {
      await openScan(tester, ReceiptSource.camera);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use this photo'));
      await tester.pumpAndSettle();

      expect(reader.readPaths, ['/tmp/a.jpg']);
      expect(find.text('FORM with /tmp/a.jpg'), findsOneWidget);
    });

    testWidgets('is deleted and the camera reopens when the user taps Retake', (
      tester,
    ) async {
      photos.pathQueue.addAll(['/tmp/1.jpg', '/tmp/2.jpg']);
      await openScan(tester, ReceiptSource.camera);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retake'));
      await tester.pumpAndSettle();

      expect(photos.discarded, ['/tmp/1.jpg']);
      expect(photos.picked, [ReceiptSource.camera, ReceiptSource.camera]);
      expect(find.text('Use this photo'), findsOneWidget);
    });

    testWidgets('that was recovered after a restart says so', (tester) async {
      await openScan(tester, ReceiptSource.camera);
      await tester.pumpAndSettle();

      cubit.resume('/cache/lost.jpg');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('low on memory and restarted the app'),
        findsOneWidget,
      );
      expect(find.text('Use this photo'), findsOneWidget);
    });

    testWidgets('is deleted when the user leaves instead of choosing', (
      tester,
    ) async {
      await openScan(tester, ReceiptSource.camera);
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(photos.discarded, contains('/tmp/a.jpg'));
    });
  });

  group('a gallery photo', () {
    testWidgets('goes straight to the form with the scan', (tester) async {
      await openScan(tester, ReceiptSource.file);
      await tester.pumpAndSettle();

      expect(find.text('FORM with /tmp/a.jpg'), findsOneWidget);
      expect(find.text('Use this photo'), findsNothing);
    });

    testWidgets('the scan screen is replaced, so Back does not return to it', (
      tester,
    ) async {
      await openScan(tester, ReceiptSource.file);
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Scan receipt'), findsNothing);
    });
  });

  group('when the user backs out', () {
    testWidgets('the screen closes and shows where it began', (tester) async {
      photos.path = null;

      await openScan(tester, ReceiptSource.file);
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Scan receipt'), findsNothing);
    });
  });

  group('when it fails', () {
    testWidgets('shows the problem with Try again and Enter manually', (
      tester,
    ) async {
      photos.pickError = const ScanException(ScanProblem.permissionDenied);

      await openScan(tester, ReceiptSource.file);
      await tester.pumpAndSettle();

      expect(find.textContaining('can\'t open your photos'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Enter manually'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('Try again starts over', (tester) async {
      photos.pickError = const ScanException(ScanProblem.cameraUnavailable);
      await openScan(tester, ReceiptSource.file);
      await tester.pumpAndSettle();

      photos.pickError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('FORM with /tmp/a.jpg'), findsOneWidget);
    });

    testWidgets('Enter manually opens the form with nothing filled in', (
      tester,
    ) async {
      reader.error = const ScanException(ScanProblem.unreadable);
      await openScan(tester, ReceiptSource.file);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enter manually'));
      await tester.pumpAndSettle();

      expect(find.text('FORM empty'), findsOneWidget);
    });

    testWidgets('an unexpected bug still ends in the failure screen', (
      tester,
    ) async {
      reader.error = StateError('a bug');

      await openScan(tester, ReceiptSource.file);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('couldn\'t read this receipt'),
        findsOneWidget,
      );
    });
  });
}

/// A photo source that waits until the test lets the "camera" finish.
class _SlowPhotoSource extends FakeReceiptPhotoSource {
  final opened = Completer<void>();

  @override
  Future<String?> pick(ReceiptSource source) async {
    final photo = await super.pick(source);
    await opened.future;
    return photo;
  }
}

/// A text reader that waits until the test lets it finish.
class _SlowReader extends FakeReceiptTextReader {
  _SlowReader(super.lines);

  final finished = Completer<void>();

  @override
  Future<List<OcrLine>> read(String photoPath) async {
    final lines = await super.read(photoPath);
    await finished.future;
    return lines;
  }
}
