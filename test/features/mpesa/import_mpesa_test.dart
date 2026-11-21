import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/expenses/domain/usecases/vendor_category_memory.dart';
import 'package:smart_expense_tracker/features/mpesa/domain/usecases/import_mpesa.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';

void main() {
  const sent =
      'SGH4A1B2C3 Confirmed. Ksh500.00 sent to JOHN DOE 0712345678 on '
      '17/7/26 at 2:15 PM. New M-PESA balance is Ksh1,234.56. Transaction '
      'cost, Ksh7.00.';
  const till =
      'SGH4A1B2C5 Confirmed. Ksh350.00 paid to JAVA HOUSE. on 20/11/26 at '
      '1:30 PM.New M-PESA balance is Ksh2,000.00. Transaction cost, Ksh0.00.';
  const received =
      'SGH4A1B2C8 Confirmed.You have received Ksh2,500.00 from JANE ROE '
      '0722000000 on 18/11/26 at 10:10 AM.';

  late FakeExpenseRepository expenses;
  late FakeCategoryRepository categories;

  ImportMpesa build() => ImportMpesa(
    expenses: expenses,
    categories: categories,
    memory: VendorCategoryMemory(expenses),
  );

  setUp(() {
    expenses = FakeExpenseRepository();
    categories = FakeCategoryRepository(const [
      Category(id: 'food', name: 'Food'),
      Category(id: 'transport', name: 'Transport'),
      Category(id: 'other', name: 'Other'),
    ]);
  });

  test('a payment fills in the form, with the charge included', () async {
    final result = await build()(sent);

    expect(result.status, MpesaStatus.ready);
    final quick = result.result!;
    // 500.00 sent and 7.00 charged: what actually left the account.
    expect(quick.draft.amountMinor, 50700);
    expect(quick.draft.vendor, 'John Doe');
    expect(quick.draft.title, 'M-Pesa transfer');
    expect(quick.draft.date, DateTime(2026, 7, 17));
    expect(quick.transactionCode, 'SGH4A1B2C3');
    expect(quick.text, contains('transaction cost'));
    expect(quick.heading, contains('M-Pesa'));
  });

  test('a till payment has no cost to add', () async {
    final result = (await build()(till)).result!;

    expect(result.draft.amountMinor, 35000);
    expect(result.draft.vendor, 'Java House');
    expect(result.text, isNot(contains('transaction cost')));
  });

  test('a paybill payment names the account', () async {
    final result = (await build()(
      'SGH4A1B2C4 Confirmed. Ksh1,200.00 sent to KPLC PREPAID for account '
      '12345678 on 3/11/26 at 9:05 AM. Transaction cost, Ksh0.00.',
    )).result!;

    expect(result.draft.title, 'Account 12345678');
    expect(result.draft.vendor, 'Kplc Prepaid');
  });

  test('money received is not an expense', () async {
    final result = await build()(received);

    expect(result.status, MpesaStatus.income);
    expect(result.result, isNull);
  });

  test('a message with no amount is not recognised', () async {
    final result = await build()('Hello there');

    expect(result.status, MpesaStatus.notRecognised);
  });

  test('the same message twice is noticed, but can still be added', () async {
    expenses = FakeExpenseRepository(
      initial: [buildExpense(id: '1', transactionCode: 'SGH4A1B2C3')],
    );

    final result = await build()(sent);

    expect(result.status, MpesaStatus.alreadyAdded);
    expect(result.result, isNotNull);
  });

  test('a different code is not a duplicate', () async {
    expenses = FakeExpenseRepository(
      initial: [buildExpense(id: '1', transactionCode: 'OTHER00000')],
    );

    expect((await build()(sent)).status, MpesaStatus.ready);
  });

  test('suggests the category used for that vendor before', () async {
    expenses = FakeExpenseRepository(
      initial: [
        buildExpense(id: '1', vendor: 'Java House', categoryId: 'food'),
      ],
    );

    final result = (await build()(till)).result!;

    expect(result.suggestedCategoryId, 'food');
    expect(result.categoryFromHistory, isTrue);
  });

  test('suggests nothing when it has nothing to go on', () async {
    final result = (await build()(sent)).result!;

    expect(result.suggestedCategoryId, isNull);
  });
}
