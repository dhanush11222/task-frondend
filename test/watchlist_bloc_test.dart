import 'package:bloc_test/bloc_test.dart';
import 'package:crypto_market_app/core/error/failure.dart';
import 'package:crypto_market_app/features/coins/domain/coin.dart';
import 'package:crypto_market_app/features/watchlist/data/watchlist_repository.dart';
import 'package:crypto_market_app/features/watchlist/presentation/bloc/watchlist_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements WatchlistRepository {}

const _btc = Coin(id: 'bitcoin', symbol: 'btc', name: 'Bitcoin', currentPrice: 1);
const _btcFresh = Coin(id: 'bitcoin', symbol: 'btc', name: 'Bitcoin', currentPrice: 2);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.saveLocal(any())).thenAnswer((_) async {});
  });

  setUpAll(() => registerFallbackValue(<Coin>[]));

  blocTest<WatchlistBloc, WatchlistState>(
    'shows the saved list immediately, then refreshes prices',
    setUp: () {
      when(() => repo.loadLocal()).thenReturn([_btc]);
      when(() => repo.fetchFresh(['bitcoin'])).thenAnswer((_) async => {'bitcoin': _btcFresh});
    },
    build: () => WatchlistBloc(repo),
    act: (b) => b.add(const WatchlistRequested()),
    expect: () => [
      const WatchlistState(status: WatchlistStatus.success, coins: [_btc]),
      const WatchlistState(status: WatchlistStatus.success, coins: [_btcFresh]),
    ],
  );

  blocTest<WatchlistBloc, WatchlistState>(
    'keeps saved prices and marks them stale when offline',
    setUp: () {
      when(() => repo.loadLocal()).thenReturn([_btc]);
      when(() => repo.fetchFresh(any())).thenThrow(const Failure('offline', isNetwork: true));
    },
    build: () => WatchlistBloc(repo),
    act: (b) => b.add(const WatchlistRequested()),
    expect: () => [
      const WatchlistState(status: WatchlistStatus.success, coins: [_btc]),
      const WatchlistState(status: WatchlistStatus.success, coins: [_btc], stale: true),
    ],
  );

  blocTest<WatchlistBloc, WatchlistState>(
    'toggling adds, persists locally and syncs; toggling again removes',
    setUp: () {
      when(() => repo.syncAdded(any())).thenReturn(null);
      when(() => repo.syncRemoved(any())).thenReturn(null);
    },
    build: () => WatchlistBloc(repo),
    act: (b) => b
      ..add(const WatchlistToggled(_btc))
      ..add(const WatchlistToggled(_btc)),
    expect: () => [
      const WatchlistState(status: WatchlistStatus.success, coins: [_btc]),
      const WatchlistState(status: WatchlistStatus.success, coins: []),
    ],
    verify: (_) {
      verify(() => repo.saveLocal(any())).called(2);
      verify(() => repo.syncAdded('bitcoin')).called(1);
      verify(() => repo.syncRemoved('bitcoin')).called(1);
    },
  );
}
