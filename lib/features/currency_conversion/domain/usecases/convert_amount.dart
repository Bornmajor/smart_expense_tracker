import '../entities/exchange_rates.dart';

/// Turns an amount in one currency into another using downloaded rates.
abstract final class ConvertAmount {
  /// [minor] in the [from] currency, converted to the [to] currency, in minor
  /// units and rounded to the nearest. Null when either currency has no rate,
  /// or [minor] is negative.
  static int? call({
    required int minor,
    required String from,
    required String to,
    required ExchangeRates rates,
  }) {
    if (minor < 0 || !rates.has(from) || !rates.has(to)) return null;
    if (from == to) return minor;
    return (minor * rates.perUsd[to]! / rates.perUsd[from]!).round();
  }
}
