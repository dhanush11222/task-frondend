import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../coins/data/coins_repository.dart';
import '../../coins/domain/coin.dart';

/// Local-first watchlist: the device is the source of truth (survives restarts
/// and works offline); the backend is used for live prices and a best-effort sync.
class WatchlistRepository {
  WatchlistRepository(this._api, this._prefs);

  static const _key = 'watchlist_coins_v1';

  final ApiClient _api;
  final SharedPreferences _prefs;

  /// Last saved coins (in the order they were added), with their last known prices.
  List<Coin> loadLocal() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      return coinsFromJson(jsonDecode(raw));
    } catch (_) {
      return const []; // corrupted payload: start clean instead of crashing
    }
  }

  Future<void> saveLocal(List<Coin> coins) =>
      _prefs.setString(_key, jsonEncode(coins.map(coinToJson).toList()));

  /// Fresh market data for [ids]. Throws a Failure when the network is down.
  Future<Map<String, Coin>> fetchFresh(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final res = await _api.get('/coins', query: {'ids': ids.join(','), 'perPage': 100});
    return {for (final c in coinsFromJson(res.data)) c.id: c};
  }

  /// Best-effort mirror to the backend; local state never depends on it.
  void syncAdded(String coinId) =>
      unawaited(_api.post('/watchlist', body: {'coinId': coinId}).then((_) {}, onError: (_) {}));

  void syncRemoved(String coinId) =>
      unawaited(_api.delete('/watchlist/$coinId').then((_) {}, onError: (_) {}));
}
