import 'package:drift/drift.dart' show Value;

import '../../../../core/database/app_database.dart';
import '../../domain/entities/recurrence_frequency.dart';
import '../../domain/entities/recurring_rule.dart';

extension RecurringRuleRowMapper on RecurringRuleRow {
  RecurringRule toEntity() => RecurringRule(
    id: id,
    title: title,
    vendor: vendor,
    amountMinor: amountMinor,
    categoryId: categoryId,
    // An unknown saved name (from a newer version of the app) is read as
    // monthly, the most common, rather than failing to open the list.
    frequency:
        RecurrenceFrequency.values.asNameMap()[frequency] ??
        RecurrenceFrequency.monthly,
    anchor: anchor,
    nextDue: nextDue,
    isActive: isActive,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension RecurringRuleEntityMapper on RecurringRule {
  RecurringRulesCompanion toCompanion() => RecurringRulesCompanion.insert(
    id: id,
    title: Value(title),
    vendor: vendor,
    amountMinor: amountMinor,
    categoryId: categoryId,
    frequency: frequency.name,
    anchor: anchor,
    nextDue: nextDue,
    isActive: Value(isActive),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
