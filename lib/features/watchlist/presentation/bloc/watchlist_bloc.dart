import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../coins/domain/coin.dart';
import '../../data/watchlist_repository.dart';

sealed class WatchlistEvent {
  const WatchlistEvent();
}

/// Loads the saved list instantly, then refreshes prices from the network.
/// [silent] = background refresh (timer / pull-to-refresh), no loading state.
class WatchlistRequested extends WatchlistEvent {
  const WatchlistRequested({this.silent = false});
  final bool silent;
}

class WatchlistToggled extends WatchlistEvent {
  const WatchlistToggled(this.coin);
  final Coin coin;
}

enum WatchlistStatus { loading, success }

class WatchlistState extends Equatable {
  const WatchlistState({
    this.status = WatchlistStatus.loading,
    this.coins = const [],
    this.stale = false,
  });

  final WatchlistStatus status;
  final List<Coin> coins;

  /// True when the last price refresh failed and saved prices are being shown.
  final bool stale;

  bool isWatched(String id) => coins.any((c) => c.id == id);

  WatchlistState copyWith({WatchlistStatus? status, List<Coin>? coins, bool? stale}) => WatchlistState(
        status: status ?? this.status,
        coins: coins ?? this.coins,
        stale: stale ?? this.stale,
      );

  @override
  List<Object?> get props => [status, coins, stale];
}

/// App-wide: the list, detail and watchlist screens all share it.
class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc(this._repo) : super(const WatchlistState()) {
    on<WatchlistRequested>(_onRequested, transformer: restartable());
    // Sequential so rapid star taps are persisted in order.
    on<WatchlistToggled>(_onToggled, transformer: sequential());
  }

  final WatchlistRepository _repo;

  Future<void> _onRequested(WatchlistRequested e, Emitter<WatchlistState> emit) async {
    // 1) Saved list shows immediately (also works offline).
    if (state.status == WatchlistStatus.loading) {
      emit(state.copyWith(status: WatchlistStatus.success, coins: _repo.loadLocal()));
    }
    if (state.coins.isEmpty) return;

    // 2) Live prices. Merge into the *current* list so toggles made meanwhile aren't lost.
    try {
      final fresh = await _repo.fetchFresh(state.coins.map((c) => c.id).toList());
      final merged = [for (final c in state.coins) fresh[c.id] ?? c];
      emit(state.copyWith(coins: merged, stale: false));
      await _repo.saveLocal(merged);
    } catch (_) {
      emit(state.copyWith(stale: true));
    }
  }

  Future<void> _onToggled(WatchlistToggled e, Emitter<WatchlistState> emit) async {
    final watched = state.isWatched(e.coin.id);
    final next = watched ? state.coins.where((c) => c.id != e.coin.id).toList() : [...state.coins, e.coin];
    emit(state.copyWith(status: WatchlistStatus.success, coins: next));
    await _repo.saveLocal(next);
    watched ? _repo.syncRemoved(e.coin.id) : _repo.syncAdded(e.coin.id);
  }
}
