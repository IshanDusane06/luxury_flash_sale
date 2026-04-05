import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/chart_point.dart';
import '../providers/flash_drop_providers.dart';
import '../providers/luxury_products_providers.dart';
import '../widgets/animated_price_display.dart';
import '../widgets/flash_drop_line_chart.dart';
import '../widgets/hold_to_secure_button.dart';

/// Flash Drop product detail: isolate-parsed history, live stream, hold-to-buy.
class FlashDropPdpPage extends ConsumerWidget {
  const FlashDropPdpPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(luxuryProductByIdProvider(productId));
    if (product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0C),
        body: const SafeArea(
          child: Center(
            child: _ErrorPane(message: 'Unknown product'),
          ),
        ),
      );
    }

    final historicalAsync = ref.watch(historicalChartPointsProvider);
    final pdpAsync = ref.watch(flashDropPdpStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: SafeArea(
        child: historicalAsync.when(
          loading: () => const _LoadingPane(
            message: 'Indexing bid history…',
          ),
          error: (e, _) => _ErrorPane(message: '$e'),
          data: (_) => pdpAsync.when(
            loading: () => const _LoadingPane(
              message: 'Connecting live feed…',
            ),
            error: (e, _) => _ErrorPane(message: '$e'),
            data: (state) {
              return _PdpContent(
                productTitle: product.title,
                productSubtitle: product.subtitle,
                chartPoints: state.chartPoints,
                livePrice: state.snapshot.currentPrice,
                inventory: state.snapshot.remainingInventory,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PdpContent extends StatelessWidget {
  const _PdpContent({
    required this.productTitle,
    required this.productSubtitle,
    required this.chartPoints,
    required this.livePrice,
    required this.inventory,
  });

  final String productTitle;
  final String productSubtitle;
  final List<ChartPoint> chartPoints;
  final double? livePrice;
  final int? inventory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price =
        livePrice ?? (chartPoints.isEmpty ? 0.0 : chartPoints.last.price);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              const Color(0xFFC9A962).withValues(alpha: 0.45),
                        ),
                        color: const Color(0xFFC9A962).withValues(alpha: 0.08),
                      ),
                      child: Text(
                        'FLASH DROP',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 2,
                          color: const Color(0xFFC9A962),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.share_outlined,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  productTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  productSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedPriceDisplay(
                      price: price,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'live',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF2EE59D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  inventory != null
                      ? '$inventory left in this drop'
                      : 'Securing inventory…',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 220,
                color: const Color(0xFF111114),
                child: FlashDropLineChart(points: chartPoints),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Text(
              'Demand-weighted clearing price updates every 800ms. Historical curve is reconstructed from the full bid tape.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white30,
                height: 1.45,
              ),
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                HoldToSecureButton(
                  onVerified: () async {
                    await Future<void>.delayed(
                        const Duration(milliseconds: 400));
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingPane extends StatelessWidget {
  const _LoadingPane({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RepaintBoundary(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9A962)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
