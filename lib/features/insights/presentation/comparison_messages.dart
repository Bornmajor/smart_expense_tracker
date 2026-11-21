import '../../../core/utils/currency.dart';
import '../domain/entities/month_comparison.dart';

/// The words for a comparison with last month. [categoryName] is the name of
/// the category that changed most, when there is one.
({String headline, String detail, String? biggest}) comparisonText(
  MonthComparison comparison,
  String? categoryName,
  Currency currency,
) {
  final percent = comparison.percent;
  final String detail;
  if (percent == null || comparison.aboutTheSame) {
    detail = 'About the same as at this point last month';
  } else {
    detail =
        '${percent.abs()}% ${percent > 0 ? 'more' : 'less'} than at this '
        'point last month';
  }

  String? biggest;
  if (comparison.biggestChangeCategoryId != null) {
    final change = comparison.biggestChangeMinor;
    biggest =
        'Biggest change: ${categoryName ?? 'Uncategorized'}, '
        '${change > 0 ? 'up' : 'down'} ${currency.format(change.abs())}';
  }

  return (
    headline: '${currency.format(comparison.currentMinor)} so far',
    detail: detail,
    biggest: biggest,
  );
}
