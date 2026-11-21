import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/exchange_rates.dart';
import 'rates_source.dart';

/// Fetches rates from ExchangeRate-API's open endpoint: free, no key, updated
/// once a day. Its terms ask for a link to the service wherever the rates are
/// used, and allow keeping the rates on the phone. The request carries no
/// expenses or personal data, only the base currency in the address.
class HttpRatesSource implements RatesSource {
  HttpRatesSource(this._client, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static final _address = Uri.parse('https://open.er-api.com/v6/latest/USD');
  static const _timeout = Duration(seconds: 10);

  final http.Client _client;
  final DateTime Function() _now;

  @override
  Future<ExchangeRates> fetch() async {
    try {
      final response = await _client.get(_address).timeout(_timeout);
      if (response.statusCode != 200) {
        throw RatesException('HTTP ${response.statusCode}');
      }
      final body = jsonDecode(response.body);
      if (body is! Map || body['result'] != 'success') {
        throw const RatesException('The service reported an error');
      }
      final raw = body['rates'];
      if (raw is! Map) throw const RatesException('No rates in the response');

      final perUsd = <String, double>{
        for (final entry in raw.entries)
          if (entry.key is String && entry.value is num && entry.value > 0)
            entry.key as String: (entry.value as num).toDouble(),
      };
      if (!perUsd.containsKey('USD')) {
        throw const RatesException('The rates were incomplete');
      }
      return ExchangeRates(perUsd: perUsd, fetchedAt: _now());
    } on RatesException {
      rethrow;
    } on Object catch (error) {
      // No connection, a timeout, or text that is not JSON.
      throw RatesException(error);
    }
  }
}
