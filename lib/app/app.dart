import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme/dark_theme.dart';

/// Main App widget
/// Configures MaterialApp with routing, theming, and localization
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      // App title
      title: 'DustCount',

      // Routing
      routerConfig: router,

      // Theming — dark only
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,

      // Debug banner
      debugShowCheckedModeBanner: false,

      // Performance optimizations
      builder: (context, child) {
        // Add error handling UI wrapper
        return MediaQuery(
          // Prevent text scaling from system settings (optional)
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
                  minScaleFactor: 0.8,
                  maxScaleFactor: 1.3,
                ),
          ),
          child: child!,
        );
      },
    );
  }
}
