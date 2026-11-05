import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/watchlist/presentation/bloc/watchlist_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const CryptoApp());
}

class CryptoApp extends StatelessWidget {
  const CryptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      // App-wide singleton so every screen shares the same watchlist state.
      value: sl<WatchlistBloc>()..add(const WatchlistRequested()),
      child: MaterialApp.router(
        title: 'Crypto Market',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark, // black-and-gold design
        routerConfig: appRouter,
      ),
    );
  }
}
