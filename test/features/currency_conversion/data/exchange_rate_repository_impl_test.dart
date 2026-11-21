import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expense_tracker/features/currency_conversion/data/datasources/rates_source.dart';
import 'package:smart_expense_tracker/features/currency_conversion/data/repositories/exchange_rate_repository_impl.dart';
import 'package:smart_expense_tracker/features/currency_conversion/domain/entities/exchange_rates.dart';

class FakeRatesSource implements RatesSource {
  FakeRatesSource(this.rates);

  ExchangeRates rates;
  bool failing = false;
  int fetches = 0;

  @override
  Future<ExchangeRates> fetch() async {
    fetches++;
    if (failing) throw const RatesException('offline');
    return rates;
  }
}

void main() {
  late SharedPreferences preferences;
  late FakeRatesSource source;
  var clock = DateTime(2026, 11, 21, 8);

  ExchangeRates ratesOn(DateTime day, {double kes = 129}) =>
      ExchangeRates(perUsd: {'USD': 1, 'KES': kes}, fetchedAt: day);

  ExchangeRateRepositoryImpl repository() =>
      ExchangeRateRepositoryImpl(preferences, source, now: () => clock);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    clock = DateTime(2026, 11, 21, 8);
    source = FakeRatesSource(ratesOn(clock));
  });

  test('has no rates until some are downloaded', () async {
    expect(await repository().saved(), isNull);
  });

  test('downloads and saves rates the first time', () async {
    final rates = await repository().refresh();

    expect(rates, ratesOn(clock));
    expect(await repository().saved(), ratesOn(clock));
  });

  test('does not download again within a day', () async {
    await repository().refresh();
    clock = clock.add(const Duration(hours: 23));

    await repository().refresh();

    expect(source.fetches, 1);
  });

  test('downloads again after a day', () async {
    await repository().refresh();
    clock = clock.add(const Duration(hours: 25));
    source.rates = ratesOn(clock, kes: 131);

    final rates = await repository().refresh();

    expect(source.fetches, 2);
    expect(rates!.perUsd['KES'], 131);
  });

  test('force downloads even when the rates are fresh', () async {
    await repository().refresh();

    await repository().refresh(force: true);

    expect(source.fetches, 2);
  });

  test('keeps the saved rates when a download fails', () async {
    await repository().refresh();
    clock = clock.add(const Duration(days: 3));
    source.failing = true;

    final rates = await repository().refresh();

    expect(rates!.perUsd['KES'], 129);
    expect(await repository().saved(), ratesOn(DateTime(2026, 11, 21, 8)));
  });

  test('is null when nothing was saved and the download fails', () async {
    source.failing = true;

    expect(await repository().refresh(), isNull);
  });

  test('treats damaged saved text as no rates', () async {
    await preferences.setString('exchange_rates', 'not json');

    expect(await repository().saved(), isNull);
  });
}
