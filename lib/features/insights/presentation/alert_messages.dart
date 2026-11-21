import '../../../core/utils/currency.dart';
import '../domain/entities/insight_alert.dart';

/// The words for an alert. [categoryName] is the name of the alert's category.
({String title, String message}) alertText(
  InsightAlert alert,
  String categoryName,
  Currency currency,
) {
  final amount = currency.format(alert.amountMinor);
  final usual = alert.usualMinor == null
      ? ''
      : currency.format(alert.usualMinor!);
  return switch (alert.kind) {
    AlertKind.possibleDuplicate => (
      title: 'Possible duplicate',
      message:
          '$amount at ${alert.vendor} twice within a day. '
          'Is one of them a mistake?',
    ),
    AlertKind.unusuallyLarge => (
      title: 'Unusually large expense',
      message:
          '$amount at ${alert.vendor} is much more than the usual $usual '
          'for $categoryName.',
    ),
    AlertKind.priceChanged => (
      title: 'Price change at ${alert.vendor}',
      message:
          '${alert.vendor} went ${alert.amountMinor > (alert.usualMinor ?? 0) ? 'up' : 'down'} '
          'from $usual to $amount a month.',
    ),
    AlertKind.noBudget => (
      title: '$categoryName has no budget',
      message:
          '$categoryName is ${_sharePercent(alert)}% of your spending this '
          'month. A budget keeps it in check.',
    ),
    AlertKind.categoryAboveNormal => (
      title: '$categoryName is running high',
      message:
          '$amount so far this month. A whole month usually comes to '
          '$usual.',
    ),
  };
}

/// The category's share of the month's spending, as a whole percent.
int _sharePercent(InsightAlert alert) {
  final month = alert.usualMinor ?? 0;
  return month == 0 ? 0 : (alert.amountMinor * 100 / month).round();
}
