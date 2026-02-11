import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dust_count/app/app.dart';

import 'firebase_options.dart';

/// Application entry point
/// Initializes Firebase, sets up system UI, and runs the app
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue anyway for development - Firebase will be set up later
  }

  // Set preferred orientations (portrait only for mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF1A1A2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Enable edge-to-edge display
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // Run the app wrapped in ProviderScope for Riverpod
  runApp(
    const ProviderScope(
      child: DustCountApp(),
    ),
  );
}

/// Root app widget that handles deep links and initialization
class DustCountApp extends ConsumerStatefulWidget {
  const DustCountApp({super.key});

  @override
  ConsumerState<DustCountApp> createState() => _DustCountAppState();
}

class _DustCountAppState extends ConsumerState<DustCountApp> {
  // TODO: Add app_links package for deep link handling
  // late AppLinks _appLinks;
  // StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    // TODO: Cancel deep link subscription
    // _linkSubscription?.cancel();
    super.dispose();
  }

  /// Initialize deep link handling
  Future<void> _initDeepLinks() async {
    // TODO: Implement deep link handling with app_links package
    // This will handle invite codes shared via deep links

    // Example implementation:
    // _appLinks = AppLinks();

    // Handle initial link if app was opened via deep link
    // final initialUri = await _appLinks.getInitialAppLink();
    // if (initialUri != null) {
    //   _handleDeepLink(initialUri);
    // }

    // Handle links while app is running
    // _linkSubscription = _appLinks.uriLinkStream.listen(
    //   (uri) {
    //     _handleDeepLink(uri);
    //   },
    //   onError: (err) {
    //     debugPrint('Deep link error: $err');
    //   },
    // );
  }

  /// Handle deep link navigation
  void _handleDeepLink(Uri uri) {
    // TODO: Implement deep link routing
    // Example: dustcount://join/INVITE_CODE
    // Should navigate to /households/join/INVITE_CODE

    // final router = ref.read(routerProvider);
    //
    // if (uri.pathSegments.isNotEmpty) {
    //   final path = uri.pathSegments.first;
    //
    //   if (path == 'join' && uri.pathSegments.length > 1) {
    //     final inviteCode = uri.pathSegments[1];
    //     router.go('/households/join/$inviteCode');
    //   }
    // }

    debugPrint('Deep link received: $uri');
  }

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}

/// Error widget for uncaught errors
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.error,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF0EDE8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please restart the app. If the problem persists, contact support.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFCAC4D0),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (kDebugMode) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB71C1C).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Debug Information:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFB4AB),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFF0EDE8),
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (stackTrace != null) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Stack Trace:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFB4AB),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                stackTrace.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFF0EDE8),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
