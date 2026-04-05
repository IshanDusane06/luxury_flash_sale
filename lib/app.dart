import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/pages/flash_drop_pdp_page.dart';
import 'presentation/pages/luxury_products_list_page.dart';

class LuxFlashDropApp extends StatelessWidget {
  const LuxFlashDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'Flash Drop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0A0A0C),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFC9A962),
            surface: Color(0xFF111114),
          ),
        ),
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  const LuxuryProductsListPage(),
            ),
            GoRoute(
              path: '/products/:productId',
              builder: (context, state) {
                final productId = state.pathParameters['productId'];
                if (productId == null || productId.isEmpty) {
                  return const _RouteErrorPane(message: 'Missing productId');
                }
                return FlashDropPdpPage(productId: productId);
              },
            ),
          ],
          errorBuilder: (context, state) => _RouteErrorPane(
            message: state.error?.toString() ?? 'Route error',
          ),
        ),
      ),
    );
  }
}

class _RouteErrorPane extends StatelessWidget {
  const _RouteErrorPane({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
