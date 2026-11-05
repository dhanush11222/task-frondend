import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../coins/domain/coin.dart';
import '../../data/watchlist_repository.dart';

sealed class WatchlistEvent {
  const WatchlistEvent();
}

class WatchlistRequested extends WatchlistEvent {
  const WatchlistRequested();
}

class WatchlistToggled extends WatchlistEvent {
  const WatchlistToggled(this.coin);
  final Coin coin;
}

enum WatchlistStatus { loading, success, failure }

class WatchlistState extends Equatable {
  const WatchlistState({
    this.status = WatchlistStatus.loading,
    this.coins = const [],
    this.failure,
    this.message,
    this.messageId = 0,
  });

  final WatchlistStatus status;
  final List<Coin> coins;
  final Failure? failure;

  /// One-shot error text (e.g. toggle failed). [messageId] makes each one unique
  /// so listeners fire even if the text repeats.
  final String? message;
  final int messageId;

  bool isWatched(String id) => coins.any((c) => c.id == id);

  WatchlistState copyWith({
    WatchlistStatus? status,
    List<Coin>? coins,
    Failure? failure,
    String? message,
    int? messageId,
  }) {
    return WatchlistState(
      status: status ?? this.status,
      coins: coins ?? this.coins,
      failure: failure,
      message: message ?? this.message,
      messageId: messageId ?? this.messageId,
    );
  }

  @override
  List<Object?> get props => [status, coins, failure, messageId];
}

/// App-wide: the list screen, detail screen and watchlist tab all share it.
class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc(this._repo) : super(const WatchlistState()) {
    on<WatchlistRequested>(_onRequested, transformer: restartable());
    // Sequential so rapid star taps are applied to the server in order.
    on<WatchlistToggled>(_onToggled, transformer: sequential());
  }

  final WatchlistRepository _repo;

  Future<void> _onRequested(WatchlistRequested e, Emitter<WatchlistState> emit) async {
    emit(state.copyWith(status: WatchlistStatus.loading));
    try {
      final coins = await _repo.getWatchlist();
      emit(state.copyWith(status: WatchlistStatus.success, coins: coins));
    } catch (err) {
      emit(state.copyWith(status: WatchlistStatus.failure, failure: Failure.from(err)));
    }
  }

  Future<void> _onToggled(WatchlistToggled e, Emitter<WatchlistState> emit) async {
    final before = state.coins;
    final wasWatched = state.isWatched(e.coin.id);
    // Optimistic update: UI reacts instantly, rolled back if the server rejects it.
    final after = wasWatched
        ? before.where((c) => c.id != e.coin.id).toList()
        : [...before, e.coin];
    emit(state.copyWith(status: WatchlistStatus.success, coins: after));
    try {
      if (wasWatched) {
        await _repo.remove(e.coin.id);
      } else {
        await _repo.add(e.coin.id);
      }
    } catch (err) {
      emit(state.copyWith(
        coins: before,
        message: Failure.from(err).message,
        messageId: state.messageId + 1,
      ));
    }
  }
}
