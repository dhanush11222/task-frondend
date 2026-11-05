import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../coins/data/coins_repository.dart';
import '../../domain/market_stats.dart';

sealed class MarketStatsEvent {
  const MarketStatsEvent();
}

class MarketStatsRequested extends MarketStatsEvent {
  const MarketStatsRequested({this.silent = false});
  final bool silent;
}

enum MarketStatsStatus { loading, success, failure }

class MarketStatsState extends Equatable {
  const MarketStatsState({this.status = MarketStatsStatus.loading, this.stats, this.failure});

  final MarketStatsStatus status;
  final MarketStats? stats;
  final Failure? failure;

  @override
  List<Object?> get props => [status, stats, failure];
}

class MarketStatsBloc extends Bloc<MarketStatsEvent, MarketStatsState> {
  MarketStatsBloc(this._repo) : super(const MarketStatsState()) {
    on<MarketStatsRequested>(_onRequested, transformer: restartable());
  }

  final CoinsRepository _repo;

  Future<void> _onRequested(MarketStatsRequested e, Emitter<MarketStatsState> emit) async {
    if (!e.silent || state.stats == null) emit(MarketStatsState(status: MarketStatsStatus.loading, stats: state.stats));
    try {
      final stats = await _repo.getMarketStats();
      emit(MarketStatsState(status: MarketStatsStatus.success, stats: stats));
    } catch (err) {
      if (e.silent && state.stats != null) {
        emit(MarketStatsState(status: MarketStatsStatus.success, stats: state.stats));
        return;
      }
      emit(MarketStatsState(status: MarketStatsStatus.failure, failure: Failure.from(err)));
    }
  }
}
