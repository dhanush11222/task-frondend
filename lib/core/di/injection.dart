import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../features/coin_detail/presentation/bloc/coin_detail_bloc.dart';
import '../../features/coins/data/coins_repository.dart';
import '../../features/coins/presentation/bloc/coin_list_bloc.dart';
import '../../features/market_stats/presentation/bloc/market_stats_bloc.dart';
import '../../features/watchlist/data/watchlist_repository.dart';
import '../../features/watchlist/presentation/bloc/watchlist_bloc.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  var deviceId = prefs.getString('device_id');
  if (deviceId == null) {
    deviceId = const Uuid().v4();
    await prefs.setString('device_id', deviceId);
  }

  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<Dio>(
      () => Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'x-device-id': deviceId},
        ),
      ),
    )
    ..registerLazySingleton(() => ApiClient(sl()))
    ..registerLazySingleton(() => CoinsRepository(sl()))
    ..registerLazySingleton(() => WatchlistRepository(sl(), sl()))
    ..registerLazySingleton(() => WatchlistBloc(sl()))
    ..registerFactory(() => CoinListBloc(sl()))
    ..registerFactory(() => MarketStatsBloc(sl()))
    ..registerFactoryParam<CoinDetailBloc, String, void>((id, _) => CoinDetailBloc(sl(), id));
}
