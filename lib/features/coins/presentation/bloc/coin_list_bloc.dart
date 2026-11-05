import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../data/coins_repository.dart';
import '../../domain/coin.dart';
import '../../domain/coin_query.dart';

// ───────── Events ─────────
sealed class CoinListEvent extends Equatable {
  const CoinListEvent();
  @override
  List<Object?> get props => [];
}

/// Reloads page 1 for the current query. [silent] = background refresh that
/// never shows a spinner or error; [debounce] = wait for typing to settle.
class CoinListReloadRequested extends CoinListEvent {
  const CoinListReloadRequested({this.silent = false, this.debounce = false});
  final bool silent;
  final bool debounce;
  @override
  List<Object?> get props => [silent, debounce];
}

class CoinListLoadMore extends CoinListEvent {
  const CoinListLoadMore();
}

class CoinListSearchChanged extends CoinListEvent {
  const CoinListSearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class CoinListSortChanged extends CoinListEvent {
  const CoinListSortChanged(this.sort, {this.ascending});
  final CoinSort sort;

  /// null = keep current direction, unless the sort field changed (then desc).
  final bool? ascending;
  @override
  List<Object?> get props => [sort, ascending];
}

class CoinListFilterChanged extends CoinListEvent {
  const CoinListFilterChanged(this.filter);
  final CoinFilter filter;
  @override
  List<Object?> get props => [filter];
}

// ───────── State ─────────
enum CoinListStatus { initial, loading, success, failure }

class CoinListState extends Equatable {
  const CoinListState({
    this.status = CoinListStatus.initial,
    this.coins = const [],
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.query = '',
    this.sort = CoinSort.marketCap,
    this.ascending = false,
    this.filter = CoinFilter.all,
    this.failure,
    this.source,
  });

  final CoinListStatus status;
  final List<Coin> coins;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final bool loadMoreFailed;
  final String query;
  final CoinSort sort;
  final bool ascending;
  final CoinFilter filter;
  final Failure? failure;
  final String? source;

  bool get isSearchingOrFiltering => query.trim().isNotEmpty || filter != CoinFilter.all;

  CoinListState copyWith({
    CoinListStatus? status,
    List<Coin>? coins,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    bool? loadMoreFailed,
    String? query,
    CoinSort? sort,
    bool? ascending,
    CoinFilter? filter,
    Failure? failure,
    bool clearFailure = false,
    String? source,
  }) {
    return CoinListState(
      status: status ?? this.status,
      coins: coins ?? this.coins,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      ascending: ascending ?? this.ascending,
      filter: filter ?? this.filter,
      failure: clearFailure ? null : (failure ?? this.failure),
      source: source ?? this.source,
    );
  }

  @override
  List<Object?> get props => [
        status, coins, page, hasMore, loadingMore, loadMoreFailed,
        query, sort, ascending, filter, failure, source,
      ];
}

// ───────── Bloc ─────────
class CoinListBloc extends Bloc<CoinListEvent, CoinListState> {
  CoinListBloc(this._repo) : super(const CoinListState()) {
    // Newest reload wins; stale responses are discarded automatically.
    on<CoinListReloadRequested>(_onReload, transformer: restartable());
    on<CoinListLoadMore>(_onLoadMore, transformer: droppable());
    on<CoinListSearchChanged>((e, emit) {
      if (e.query == state.query) return;
      emit(state.copyWith(query: e.query));
      add(const CoinListReloadRequested(debounce: true));
    });
    on<CoinListSortChanged>((e, emit) {
      final asc = e.ascending ?? (e.sort == state.sort ? state.ascending : false);
      emit(state.copyWith(sort: e.sort, ascending: asc));
      add(const CoinListReloadRequested());
    });
    on<CoinListFilterChanged>((e, emit) {
      if (e.filter == state.filter) return;
      emit(state.copyWith(filter: e.filter));
      add(const CoinListReloadRequested());
    });
  }

  final CoinsRepository _repo;

  Future<void> _onReload(CoinListReloadRequested e, Emitter<CoinListState> emit) async {
    if (e.debounce) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (emit.isDone) return; // superseded by a newer keystroke
    }
    // Background refresh only makes sense while the user is still on page 1.
    if (e.silent && (state.page > 1 || state.loadingMore || state.status == CoinListStatus.loading)) return;

    if (!e.silent) {
      emit(state.copyWith(status: CoinListStatus.loading, clearFailure: true, loadMoreFailed: false));
    }
    try {
      final page = await _fetch(1);
      emit(state.copyWith(
        status: CoinListStatus.success,
        coins: page.coins,
        page: 1,
        hasMore: page.hasMore,
        loadingMore: false,
        source: page.source,
        clearFailure: true,
      ));
    } catch (err) {
      if (e.silent) return; // keep showing last good data
      emit(state.copyWith(status: CoinListStatus.failure, failure: Failure.from(err)));
    }
  }

  Future<void> _onLoadMore(CoinListLoadMore e, Emitter<CoinListState> emit) async {
    if (!state.hasMore || state.loadingMore || state.status != CoinListStatus.success) return;
    emit(state.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      final next = state.page + 1;
      final page = await _fetch(next);
      emit(state.copyWith(
        coins: [...state.coins, ...page.coins],
        page: next,
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  Future<CoinPage> _fetch(int page) => _repo.getCoins(
        page: page,
        search: state.query,
        sort: state.sort,
        ascending: state.ascending,
        filter: state.filter,
      );
}
