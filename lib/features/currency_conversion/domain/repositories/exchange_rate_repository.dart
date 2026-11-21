import '../entities/exchange_rates.dart';

abstract interface class ExchangeRateRepository {
  /// The rates kept on the phone, or null when none were ever downloaded.
  /// Never throws.
  Future<ExchangeRates?> saved();

  /// Downloads new rates when the saved ones are more than a day old (or
  /// always, with [force]), and returns the rates to use: the new ones, or the
  /// saved ones when there is no connection or the service fails. Null only
  /// when nothing was ever downloaded. Never throws.
  Future<ExchangeRates?> refresh({bool force = false});
}
