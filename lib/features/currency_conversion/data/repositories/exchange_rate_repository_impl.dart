import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/exchange_rates.dart';
import '../../domain/repositories/exchange_rate_repository.dart';
import '../datasources/rates_source.dart';

/// Keeps the last downloaded rates on the phone and refreshes them at most
/// once a day. A failed download is not an error: the saved rates stay.
class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  ExchangeRateRepositoryImpl(
    this._preferences,
    this._source, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const _key = 'exchange_rates';

  /// The service updates once a day, so asking more often gains nothing.
  static const refreshAfter = Duration(hours: 24);

  final SharedPreferences _preferences;
  final RatesSource _source;
  final DateTime Function() _now;

  @override
  Future<ExchangeRates?> saved() async {
    try {
      final text = _preferences.getString(_key);
      if (text == null) return null;
      final json = jsonDecode(text) as Map<String, dynamic>;
      final rates = (json['rates'] as Map<String, dynamic>).map(
        (code, value) => MapEntry(code, (value as num).toDouble()),
      );
      return ExchangeRates(
        perUsd: rates,
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );
    } on Object {
      // Damaged text is the same as having no rates.
      return null;
    }
  }

  @override
  Future<ExchangeRates?> refresh({bool force = false}) async {
    final current = await saved();
    if (!force &&
        current != null &&
        !current.isOlderThan(refreshAfter, _now())) {
      return current;
    }

    try {
      final fresh = await _source.fetch();
      await _preferences.setString(
        _key,
        jsonEncode({
          'fetchedAt': fresh.fetchedAt.toIso8601String(),
          'rates': fresh.perUsd,
        }),
      );
      return fresh;
    } on Object {
      return current;
    }
  }
}
