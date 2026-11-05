import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../coins/data/coins_repository.dart';
import '../../domain/coin_detail.dart';

// ───────── Events ─────────
sealed class CoinDetailEvent extends Equatable {
  const CoinDetailEvent();
  @override
  List<Object?> get props => [];
}

class CoinDetailRequested extends CoinDetailEvent {
  const CoinDetailRequested();
}

class CoinChartRequested extends CoinDetailEvent {
  const CoinChartRequested(this.range);
  final ChartRange range;
  @override
  List<Object?> get props => [range];
}

// ───────── State ─────────
enum LoadStatus { loading, success, failure }

class CoinDetailState extends Equatable {
  const CoinDetailState({
    this.detailStatus = LoadStatus.loading,
    this.detail,
    this.detailFailure,
    this.chartStatus = LoadStatus.loading,
    this.chart = const [],
    this.chartFailure,
    this.range = ChartRange.week,
  });

  final LoadStatus detailStatus;
  final CoinDetail? detail;
  final Failure? detailFailure;
  final LoadStatus chartStatus;
  final List<ChartPoint> chart;
  final Failure? chartFailure;
  final ChartRange range;

  CoinDetailState copyWith({
    LoadStatus? detailStatus,
    CoinDetail? detail,
    Failure? detailFailure,
    LoadStatus? chartStatus,
    List<ChartPoint>? chart,
    Failure? chartFailure,
    ChartRange? range,
  }) {
    return CoinDetailState(
      detailStatus: detailStatus ?? this.detailStatus,
      detail: detail ?? this.detail,
      detailFailure: detailFailure,
      chartStatus: chartStatus ?? this.chartStatus,
      chart: chart ?? this.chart,
      chartFailure: chartFailure,
      range: range ?? this.range,
    );
  }

  @override
  List<Object?> get props => [detailStatus, detail, detailFailure, chartStatus, chart, chartFailure, range];
}

// ───────── Bloc ─────────
class CoinDetailBloc extends Bloc<CoinDetailEvent, CoinDetailState> {
  CoinDetailBloc(this._repo, this.coinId) : super(const CoinDetailState()) {
    on<CoinDetailRequested>(_onDetail, transformer: restartable());
    on<CoinChartRequested>(_onChart, transformer: restartable());
    // Detail and chart load in parallel and fail independently.
    add(const CoinDetailRequested());
    add(CoinChartRequested(state.range));
  }

  final CoinsRepository _repo;
  final String coinId;

  Future<void> _onDetail(CoinDetailRequested e, Emitter<CoinDetailState> emit) async {
    emit(state.copyWith(detailStatus: LoadStatus.loading));
    try {
      final detail = await _repo.getCoinDetail(coinId);
      emit(state.copyWith(detailStatus: LoadStatus.success, detail: detail));
    } catch (err) {
      emit(state.copyWith(detailStatus: LoadStatus.failure, detailFailure: Failure.from(err)));
    }
  }

  Future<void> _onChart(CoinChartRequested e, Emitter<CoinDetailState> emit) async {
    emit(state.copyWith(chartStatus: LoadStatus.loading, range: e.range));
    try {
      final points = await _repo.getChart(coinId, e.range.days);
      emit(state.copyWith(chartStatus: LoadStatus.success, chart: points));
    } catch (err) {
      emit(state.copyWith(chartStatus: LoadStatus.failure, chartFailure: Failure.from(err)));
    }
  }
}
