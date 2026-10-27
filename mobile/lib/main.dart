// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile/core/services/push_notification_service.dart';
import 'package:mobile/core/services/pending_notification_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:mobile/core/theme/theme_screen.dart';
import 'package:mobile/features/auth/presentation/screens/auth_screen.dart';
import 'package:mobile/features/auth/presentation/screens/update_password_screen.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/scanner/presentation/screens/ocr_scanner_screen.dart';
import 'package:mobile/features/scanner/presentation/screens/analysis_result_screen.dart';
import 'package:mobile/features/scanner/data/models/trust_score_report.dart';
import 'package:mobile/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mobile/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mobile/features/profile/presentation/screens/health_profile_screen.dart';
import 'package:mobile/features/profile/presentation/screens/add_allergy_screen.dart';
import 'package:mobile/features/profile/presentation/screens/allergy_success_screen.dart';
import 'package:mobile/features/scanner/presentation/screens/ingredient_details_screen.dart';
import 'package:mobile/features/user/presentation/screens/profile_screen.dart';
import 'package:mobile/features/user/presentation/screens/settings_screen.dart';
import 'package:mobile/features/user/presentation/screens/notification_settings_screen.dart';
import 'package:mobile/features/user/presentation/screens/bookmarks_screen.dart';
import 'package:mobile/features/user/presentation/screens/saved_products_screen.dart';
import 'package:mobile/features/user/presentation/screens/scan_history_screen.dart';
import 'package:mobile/features/user/presentation/screens/scientific_sources_screen.dart';
import 'package:mobile/features/user/presentation/screens/help_support_screen.dart';
import 'package:mobile/features/user/presentation/screens/privacy_policy_screen.dart';
import 'package:mobile/features/user/presentation/screens/terms_of_service_screen.dart';
import 'package:mobile/features/community/presentation/screens/community_search_screen.dart';
import 'package:mobile/features/user/presentation/screens/main_layout_screen.dart';
import 'package:mobile/features/user/presentation/screens/daily_digest_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  // Initialize non-critical services asynchronously to avoid blocking startup
  Firebase.initializeApp().then((_) {
    PushNotificationService().initialize(onNavigate: (route) {
      if (rootNavigatorKey.currentContext != null) {
        rootNavigatorKey.currentContext!.push(route);
      }
    });
  }).catchError((e) {
    debugPrint("Failed to initialize Firebase: $e");
  });

  runApp(
    const ProviderScope(
      child: PureScanApp(),
    ),
  );
}

// Basic router setup
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.value?.session != null;
      final isGoingToAuth = state.matchedLocation == '/auth';
      final isSplashOrOnboarding = state.matchedLocation == '/splash' || state.matchedLocation == '/onboarding';

      final authEvent = authState.value?.event;

      if (authEvent == AuthChangeEvent.passwordRecovery) {
        return '/update-password';
      }

      if (state.matchedLocation == '/dashboard') return '/';
      
      if (!isAuthenticated && !isGoingToAuth && !isSplashOrOnboarding && state.matchedLocation != '/update-password') return '/auth';
      if (isAuthenticated && (isGoingToAuth || state.matchedLocation == '/splash' || state.matchedLocation == '/onboarding')) {
        if (PendingNotificationManager.instance.hasPendingNotification) {
          return PendingNotificationManager.instance.consumeRoute();
        }
        return '/';
      }
      
      // If we are already authenticated and going somewhere else (or staying), 
      // we can still consume it if it wasn't intercepted above.
      if (isAuthenticated && PendingNotificationManager.instance.hasPendingNotification) {
        return PendingNotificationManager.instance.consumeRoute();
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainLayoutScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) {
          final requestId = state.uri.queryParameters['requestId'];
          return AdminDashboardScreen(initialRequestId: requestId);
        },
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const OcrScannerScreen(),
      ),
      GoRoute(
        path: '/community-search',
        builder: (context, state) => const CommunitySearchScreen(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final result = state.extra as ScanResponse;
          return AnalysisResultScreen(result: result);
        },
      ),
      GoRoute(
        path: '/health_profile',
        builder: (context, state) {
          final isSetup = state.extra as bool? ?? false;
          return HealthProfileScreen(isSetupFlow: isSetup);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/ingredient_details',
        builder: (context, state) {
          final ingredientName = state.extra as String? ?? 'Unknown Ingredient';
          return IngredientDetailsScreen(ingredientName: ingredientName);
        },
      ),
      GoRoute(
        path: '/add_allergy',
        builder: (context, state) => const AddAllergyScreen(),
      ),
      GoRoute(
        path: '/allergy_success',
        builder: (context, state) {
          final addedAllergy = state.extra as String? ?? 'Allergy';
          return AllergySuccessScreen(addedAllergy: addedAllergy);
        },
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/saved_products',
        builder: (context, state) => const SavedProductsScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const ScanHistoryScreen(),
      ),
      GoRoute(
        path: '/scientific_sources',
        builder: (context, state) => const ScientificSourcesScreen(),
      ),
      GoRoute(
        path: '/help_support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/privacy_policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms_of_service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/settings/theme',
        builder: (context, state) => const ThemeScreen(),
      ),
      GoRoute(
        path: '/daily-digest',
        builder: (context, state) => const DailyDigestScreen(),
      ),
    ],
  );
});

class PureScanApp extends ConsumerWidget {
  const PureScanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final currentTheme = ref.watch(themeProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'PureScan AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: currentTheme.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: currentTheme.primary,
          primary: currentTheme.primary,
          secondary: currentTheme.secondary,
          surface: currentTheme.surface,
          onSurface: currentTheme.textPrimary,
          onSurfaceVariant: currentTheme.textSecondary,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.manropeTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: currentTheme.textPrimary,
            displayColor: currentTheme.textPrimary,
          ),
        ),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      routerConfig: router,
    );
  }
}
