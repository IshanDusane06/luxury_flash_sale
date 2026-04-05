# Architecture

This project is a small Flutter app built around a "flash drop" product flow: a list page, a product detail page, a live price feed, and a historical chart.

## State Management

I used `flutter_riverpod` because the app has a clear split between data sources, derived state, and UI consumers.

- Simple repositories are exposed through `Provider`s.
- The product catalog is exposed as synchronous read-only state.
- Historical chart data is exposed through a `FutureProvider` because it is loaded once with background work.
- The PDP screen state is exposed through a `StreamProvider` because it combines one-time historical data with an ongoing live stream.

This keeps widget code fairly small:

- pages read state from providers
- providers compose data from repositories
- repositories own data generation/fetching details

For this size of app, Riverpod gives enough structure without introducing heavy boilerplate like manual BLoC event/state wiring.

## Isolate Communication

Historical bid parsing is intentionally treated as expensive work.

In `lib/data/historical_bid_parser.dart`, the app:

1. generates a large synthetic JSON payload
2. parses and downsamples it
3. returns chart-ready `ChartPoint` models

That work runs inside `Isolate.run(...)` so the main UI isolate stays responsive while the loading indicator animates.

The communication pattern is simple:

- main isolate calls `parseHistoricalBidPayloadInIsolate()`
- background isolate returns `List<ChartPoint>`
- `historicalChartPointsProvider` awaits that result
- `flashDropPdpStateProvider` uses the parsed history as the base series and appends live ticks

I kept the isolate entry work in a top-level function so it does not capture UI state, which is required for safe isolate execution.

## Folder Structure

The code is organized by responsibility:

- `lib/domain`
  Contains small, framework-light models such as `LuxuryProduct`, `FlashDropSnapshot`, and `ChartPoint`.

- `lib/data`
  Contains data-producing code:
  mock repositories for catalog and live price updates, plus the historical parser/isolate logic.

- `lib/presentation/providers`
  Contains Riverpod providers and composed screen state.

- `lib/presentation/pages`
  Contains page-level widgets and screen composition.

- `lib/presentation/widgets`
  Contains reusable UI pieces like the animated price display, custom chart, and hold-to-secure button.

- `test`
  Contains widget tests.

This layout is intentionally lightweight. It is not a strict clean-architecture implementation, but it follows the same idea of separating:

- models
- data generation/fetching
- state composition
- rendering

That makes it easier to replace mocks with real APIs later without rewriting the UI layer.
