import 'package:equatable/equatable.dart';

/// Exchange rates downloaded from a public service, with the day they were
/// fetched. Every rate is "how many of this currency one US dollar buys", so
/// any two currencies can be compared through the dollar.
class ExchangeRates extends Equatable {
  const ExchangeRates({required this.perUsd, required this.fetchedAt});

  /// Units of each currency (by ISO code) that one US dollar buys.
  final Map<String, double> perUsd;
  final DateTime fetchedAt;

  bool has(String code) => (perUsd[code] ?? 0) > 0;

  /// True when these rates are more than [age] old at [now].
  bool isOlderThan(Duration age, DateTime now) =>
      now.difference(fetchedAt) > age;

  @override
  List<Object?> get props => [perUsd, fetchedAt];
}
