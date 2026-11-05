import 'package:bloc_test/bloc_test.dart';
import 'package:crypto_market_app/core/error/failure.dart';
import 'package:crypto_market_app/features/coins/data/coins_repository.dart';
import 'package:crypto_market_app/features/coins/domain/coin.dart';
import 'package:crypto_market_app/features/coins/domain/coin_query.dart';
import 'package:crypto_market_app/features/coins/presentation/bloc/coin_list_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockRepo extends Mock implements CoinsRepository {}

const _btc = Coin(id: 'bitcoin', symbol: 'btc', name: 'Bitcoin', currentPrice: 1);
const _eth = Coin(id: 'ethereum', symbol: 'eth', name: 'Ethereum', currentPrice: 2);

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(CoinSort.marketCap);
    registerFallbackValue(CoinFilter.all);
  });

  setUp(() => repo = _MockRepo());

  void stubGetCoins(Future<CoinPage> Function() answer) {
    when(() => repo.getCoins(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
          search: any(named: 'search'),
          sort: any(named: 'sort'),
          ascending: any(named: 'ascending'),
          filter: any(named: 'filter'),
        )).thenAnswer((_) => answer());
  }

  blocTest<CoinListBloc, CoinListState>(
    'emits loading then success with coins',
    setUp: () => stubGetCoins(
      () async => const CoinPage(coins: [_btc, _eth], hasMore: true, total: 50, source: 'live'),
    ),
    build: () => CoinListBloc(repo),
    act: (b) => b.add(const CoinListReloadRequested()),
    expect: () => [
      const CoinListState(status: CoinListStatus.loading),
      const CoinListState(status: CoinListStatus.success, coins: [_btc, _eth], hasMore: true, source: 'live'),
    ],
  );

  blocTest<CoinListBloc, CoinListState>(
    'emits failure when the repository throws',
    setUp: () => stubGetCoins(() async => throw const Failure('boom', isNetwork: true)),
    build: () => CoinListBloc(repo),
    act: (b) => b.add(const CoinListReloadRequested()),
    expect: () => [
      const CoinListState(status: CoinListStatus.loading),
      const CoinListState(status: CoinListStatus.failure, failure: Failure('boom', isNetwork: true)),
    ],
  );

  blocTest<CoinListBloc, CoinListState>(
    'debounces rapid search input into a single request',
    setUp: () => stubGetCoins(
      () async => const CoinPage(coins: [_btc], hasMore: false, total: 1, source: 'live'),
    ),
    build: () => CoinListBloc(repo),
    act: (b) {
      b
        ..add(const CoinListSearchChanged('b'))
        ..add(const CoinListSearchChanged('bi'))
        ..add(const CoinListSearchChanged('bit'));
    },
    wait: const Duration(milliseconds: 600),
    verify: (_) => verify(() => repo.getCoins(
          page: 1,
          perPage: any(named: 'perPage'),
          search: 'bit',
          sort: CoinSort.marketCap,
          ascending: false,
          filter: CoinFilter.all,
        )).called(1),
  );
}
