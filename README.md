# Crypto Market App (Flutter)

A mini CoinGecko-style research app: coin list, coin details with an interactive price chart, market statistics and a watchlist. Data comes from the companion Node backend (`crypto-market-backend`), which proxies and caches CoinGecko.

## Features
- **Markets**: infinite scroll, debounced search, filters (All / Gainers / Losers), sort by market cap / price / volume / 24h change (asc or desc), pull-to-refresh, silent 30s "live" price refresh.
- **Coin detail**: price, 24h change, touch-and-drag line chart (1D / 7D / 1M / 3M / 1Y) with tooltip, market cap, volume, circulating / total / max supply, ATH, description.
- **Market stats**: total market cap, 24h volume, BTC dominance, active coins, top gainers and losers.
- **Watchlist**: star any coin, stored per device on the backend; optimistic updates with rollback; swipe to remove.
- **Resilience**: shimmer loading, error + retry, and empty states on every screen; chart errors are isolated from the rest of the page; a banner appears when the backend is serving sample data.

## Architecture
Feature-first, layered, BLoC for state management.

```
lib/
  core/        config, network (Dio ApiClient), error (Failure), di (get_it), router (go_router), theme, widgets
  features/
    coins/         domain (Coin, query enums) · data (CoinsRepository) · presentation (CoinListBloc, page, tile)
    coin_detail/   domain · presentation (CoinDetailBloc, page, PriceChart)
    market_stats/  domain · presentation (MarketStatsBloc, page)
    watchlist/     data (WatchlistRepository) · presentation (WatchlistBloc, page)
```

Key decisions
- **One reload event path** in `CoinListBloc`: search, sort and filter only update the query and trigger `CoinListReloadRequested`, handled with `restartable()`, so stale responses can never overwrite newer ones. Search is debounced (350ms) inside that handler; load-more uses `droppable()`.
- **`WatchlistBloc` is an app-wide singleton** so the star state is consistent across the list, detail and watchlist screens. Toggles are `sequential()`, optimistic, and rolled back with a snackbar on failure.
- **Detail and chart load in parallel** and fail independently, so a chart error doesn't hide the coin's stats.
- **All errors become a `Failure`** (network / timeout / server message / bad payload) in one place (`ApiClient`, repositories), so blocs and UI never touch Dio types.
- Repositories are concrete classes injected through get_it (mocked directly in tests).

## Run
1. Start the backend (see its README): `npm install && npm run dev` (port 3000).
2. Run the app:
```bash
flutter pub get
flutter run                                   # Android emulator -> http://10.0.2.2:3000/api, iOS sim -> localhost
flutter run --dart-define=API_BASE_URL=http://<your-LAN-ip>:3000/api   # physical device
```
Cleartext HTTP is enabled for development (Android `usesCleartextTraffic`, iOS `NSAllowsLocalNetworking`). Use HTTPS in production.

## Test
```bash
flutter analyze
flutter test      # CoinListBloc: success, failure, search debounce
```

## Possible next steps
Currency selector, price alerts, offline cache (Hive/Isar), WebSocket live prices, widget/integration tests, auth-backed watchlist.
