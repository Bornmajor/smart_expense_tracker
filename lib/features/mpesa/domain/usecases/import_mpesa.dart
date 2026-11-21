import '../../../../core/errors/storage_exception.dart';
import '../../../../core/utils/currency.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../expenses/domain/usecases/vendor_category_memory.dart';
import '../../../quick_add/domain/entities/quick_add_draft.dart';
import '../../../quick_add/domain/entities/quick_add_result.dart';
import '../../../scan/domain/usecases/suggest_category.dart';
import '../entities/mpesa_transaction.dart';
import 'parse_mpesa.dart';

enum MpesaStatus {
  /// No amount in Ksh was found, so this is not a message the app can use.
  notRecognised,

  /// Money that came in. This app records spending only.
  income,

  /// An expense with this transaction code is already saved. [MpesaImport.result]
  /// is there if the user still wants to add it.
  alreadyAdded,

  /// Ready to fill in the expense form.
  ready,
}

class MpesaImport {
  const MpesaImport(this.status, {this.result, this.transaction});

  final MpesaStatus status;

  /// What to fill the form with. Set for [MpesaStatus.ready] and
  /// [MpesaStatus.alreadyAdded].
  final QuickAddResult? result;

  /// What was read from the message, when anything was.
  final MpesaTransaction? transaction;
}

/// Turns a pasted M-Pesa message into a filled-in expense form, and says when
/// the same message was already added. It only suggests; nothing is saved until
/// the user checks the form and presses Save.
class ImportMpesa {
  ImportMpesa({
    required this._expenses,
    required this._categories,
    required this._memory,
    this._parse = const ParseMpesa(),
    this._suggest = const SuggestCategory(),
  });

  final ExpenseRepository _expenses;
  final CategoryRepository _categories;
  final VendorCategoryMemory _memory;
  final ParseMpesa _parse;
  final SuggestCategory _suggest;

  Future<MpesaImport> call(String message) async {
    final transaction = _parse(message);
    if (transaction == null) {
      return const MpesaImport(MpesaStatus.notRecognised);
    }
    if (transaction.isIncome) {
      return MpesaImport(MpesaStatus.income, transaction: transaction);
    }

    final result = await _result(transaction);
    final code = transaction.code;
    final duplicate = code != null && await _alreadyAdded(code);
    return MpesaImport(
      duplicate ? MpesaStatus.alreadyAdded : MpesaStatus.ready,
      result: result,
      transaction: transaction,
    );
  }

  Future<QuickAddResult> _result(MpesaTransaction t) async {
    final cost = t.costMinor ?? 0;
    final draft = QuickAddDraft(
      // What actually left the account: the amount and the charge on top.
      amountMinor: t.amountMinor + cost,
      date: t.date,
      vendor: t.counterparty,
      title: _title(t),
    );

    final ids = await _categoryIds();
    final remembered = await _memory.categoryFor(
      draft.vendor,
      availableIds: ids,
    );

    final parts = [
      ?t.code,
      if (cost > 0) 'includes ${Currency.kes.format(cost)} transaction cost',
    ];
    return QuickAddResult(
      heading: 'Filled in from your M-Pesa message',
      text: parts.isEmpty ? 'M-Pesa' : parts.join(' · '),
      draft: draft,
      transactionCode: t.code,
      suggestedCategoryId:
          remembered ??
          _suggest(
            vendor: draft.vendor,
            lines: [if (draft.title.isNotEmpty) draft.title],
            availableIds: ids,
          ),
      categoryFromHistory: remembered != null,
    );
  }

  String _title(MpesaTransaction t) => switch (t.kind) {
    MpesaKind.sentToPerson => 'M-Pesa transfer',
    MpesaKind.paybill => 'Account ${t.account}',
    MpesaKind.till => '',
    MpesaKind.airtime => 'Airtime',
    MpesaKind.withdrawal => 'Cash withdrawal',
    MpesaKind.received || MpesaKind.other => 'M-Pesa',
  };

  Future<bool> _alreadyAdded(String code) async {
    try {
      final all = await _expenses.watchAll().first;
      return all.any((e) => e.transactionCode == code);
    } on StorageException {
      return false;
    }
  }

  Future<Set<String>> _categoryIds() async {
    try {
      return {for (final c in await _categories.getAll()) c.id};
    } on StorageException {
      return {};
    }
  }
}
