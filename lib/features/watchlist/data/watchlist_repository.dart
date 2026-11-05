import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../../coins/data/coins_repository.dart';
import '../../coins/domain/coin.dart';

class WatchlistRepository {
  WatchlistRepository(this._api);

  final ApiClient _api;

  Future<List<Coin>> getWatchlist() async {
    final res = await _api.get('/watchlist');
    try {
      return coinsFromJson(res.data);
    } catch (_) {
      throw const Failure('Received unexpected data from the server.');
    }
  }

  Future<void> add(String coinId) => _api.post('/watchlist', body: {'coinId': coinId});

  Future<void> remove(String coinId) => _api.delete('/watchlist/$coinId');
}
