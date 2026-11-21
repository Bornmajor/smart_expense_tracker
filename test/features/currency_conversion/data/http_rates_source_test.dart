import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_expense_tracker/features/currency_conversion/data/datasources/http_rates_source.dart';
import 'package:smart_expense_tracker/features/currency_conversion/data/datasources/rates_source.dart';

void main() {
  final now = DateTime(2026, 11, 21, 8);

  HttpRatesSource source(http.Client client) =>
      HttpRatesSource(client, now: () => now);

  Map<String, Object?> okBody() => {
    'result': 'success',
    'base_code': 'USD',
    'rates': {'USD': 1, 'KES': 129.5, 'EUR': 0.92},
  };

  test('reads the rates from a good response', () async {
    Uri? asked;
    final client = MockClient((request) async {
      asked = request.url;
      return http.Response(jsonEncode(okBody()), 200);
    });

    final rates = await source(client).fetch();

    expect(asked.toString(), 'https://open.er-api.com/v6/latest/USD');
    expect(rates.perUsd['KES'], 129.5);
    expect(rates.perUsd['EUR'], 0.92);
    expect(rates.fetchedAt, now);
  });

  test('skips a rate that is not a positive number', () async {
    final body = okBody()
      ..['rates'] = {'USD': 1, 'KES': 'lots', 'EUR': 0, 'GBP': -1, 'AED': 3.67};
    final client = MockClient(
      (_) async => http.Response(jsonEncode(body), 200),
    );

    final rates = await source(client).fetch();

    expect(rates.perUsd.keys, unorderedEquals(['USD', 'AED']));
  });

  test('fails on a server error, such as being rate limited', () async {
    final client = MockClient((_) async => http.Response('slow down', 429));

    expect(source(client).fetch(), throwsA(isA<RatesException>()));
  });

  test('fails when the service reports an error', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'result': 'error'}), 200),
    );

    expect(source(client).fetch(), throwsA(isA<RatesException>()));
  });

  test('fails on text that is not JSON', () async {
    final client = MockClient((_) async => http.Response('<html>', 200));

    expect(source(client).fetch(), throwsA(isA<RatesException>()));
  });

  test('fails when the rates are missing the dollar', () async {
    final body = okBody()..['rates'] = {'KES': 129};
    final client = MockClient(
      (_) async => http.Response(jsonEncode(body), 200),
    );

    expect(source(client).fetch(), throwsA(isA<RatesException>()));
  });

  test('fails when there is no connection', () async {
    final client = MockClient((_) async => throw http.ClientException('down'));

    expect(source(client).fetch(), throwsA(isA<RatesException>()));
  });
}
