import '../../domain/entities/exchange_rates.dart';

/// Where fresh exchange rates come from.
abstract interface class RatesSource {
  /// Throws [RatesException] if the rates could not be fetched or understood.
  Future<ExchangeRates> fetch();
}

class RatesException implements Exception {
  const RatesException(this.cause);

  final Object cause;

  @override
  String toString() => 'RatesException: $cause';
}
