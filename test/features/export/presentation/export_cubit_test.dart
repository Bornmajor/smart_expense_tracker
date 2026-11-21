import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/features/export/domain/entities/export_format.dart';
import 'package:smart_expense_tracker/features/export/domain/export_exception.dart';
import 'package:smart_expense_tracker/features/export/domain/usecases/export_month.dart';
import 'package:smart_expense_tracker/features/export/presentation/cubit/export_cubit.dart';
import 'package:smart_expense_tracker/features/export/presentation/cubit/export_state.dart';

import '../../../support/builders.dart';
import '../../../support/fakes.dart';

void main() {
  late FakeReportSharer sharer;
  late ExportCubit cubit;
  final november = DateTime(2026, 11);

  ExportCubit makeCubit() {
    return ExportCubit(
      ExportMonth(
        expenses: FakeExpenseRepository(initial: [buildExpense()]),
        categories: FakeCategoryRepository(),
        pdf: FakeReportWriter('pdf'),
        csv: FakeReportWriter('csv'),
        sharer: sharer,
        currency: () => Currency.none,
      ),
    );
  }

  setUp(() {
    sharer = FakeReportSharer();
    cubit = makeCubit();
  });

  tearDown(() => cubit.close());

  blocTest<ExportCubit, ExportState>(
    'works, then goes back to idle',
    build: makeCubit,
    act: (c) => c.export(november, ExportFormat.pdf),
    expect: () => [const ExportWorking(ExportFormat.pdf), const ExportIdle()],
    verify: (_) => expect(sharer.shared, hasLength(1)),
  );

  blocTest<ExportCubit, ExportState>(
    'reports an empty month with the month it was for',
    build: makeCubit,
    act: (c) => c.export(DateTime(2020, 1), ExportFormat.csv),
    expect: () => [
      const ExportWorking(ExportFormat.csv),
      ExportFailed(
        const ExportFailure(ExportProblem.nothingToExport),
        DateTime(2020, 1),
      ),
    ],
  );

  blocTest<ExportCubit, ExportState>(
    'reports a share sheet that would not open',
    build: () {
      sharer.error = const ExportException(ExportProblem.couldNotShare);
      return makeCubit();
    },
    act: (c) => c.export(november, ExportFormat.pdf),
    expect: () => [
      const ExportWorking(ExportFormat.pdf),
      ExportFailed(const ExportFailure(ExportProblem.couldNotShare), november),
    ],
  );

  blocTest<ExportCubit, ExportState>(
    'a bug is reported and the screen is freed',
    build: () {
      sharer.error = StateError('bug');
      return makeCubit();
    },
    act: (c) => c.export(november, ExportFormat.pdf),
    expect: () => [
      const ExportWorking(ExportFormat.pdf),
      ExportFailed(const ExportFailure(ExportProblem.couldNotCreate), november),
    ],
    errors: () => [isA<StateError>()],
  );

  test('ignores a second export while one is running', () async {
    final release = Completer<void>();
    sharer.gate = release.future;

    final first = cubit.export(november, ExportFormat.pdf);
    await cubit.export(november, ExportFormat.csv); // ignored
    release.complete();
    await first;

    expect(sharer.shared, hasLength(1));
    expect(sharer.shared.single.name, endsWith('.pdf'));
  });

  test('does nothing more when the screen was left meanwhile', () async {
    final release = Completer<void>();
    sharer.gate = release.future;

    final running = cubit.export(november, ExportFormat.pdf);
    await cubit.close();
    release.complete();

    await expectLater(running, completes);
  });

  test('a bug after the screen was left does not emit either', () async {
    final release = Completer<void>();
    sharer.gate = release.future;
    sharer.error = StateError('bug');

    final running = cubit.export(november, ExportFormat.pdf);
    await runZonedGuarded(() async {
      await cubit.close();
      release.complete();
      await running;
    }, (_, _) {});

    expect(cubit.isClosed, isTrue);
  });
}
