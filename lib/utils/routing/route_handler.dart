import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:runshaw/pages/about/about.dart';
import 'package:runshaw/pages/login/welcome/welcome.dart';
import 'package:runshaw/pages/main/main_view.dart';
import 'package:runshaw/pages/onboarding/onboarding.dart';
import 'package:runshaw/pages/nonetwork/no_network.dart';
import 'package:runshaw/pages/scan/scan.dart';
import 'package:runshaw/pages/splash/splash.dart';
import 'package:runshaw/pages/error/server_issues.dart';
import 'package:runshaw/pages/terms/terms_of_use.dart';
import 'package:runshaw/pages/privacy/privacy_policy.dart';
import 'package:runshaw/utils/notifications/notification_service.dart';

GoRouter createAppRouter({
  required GlobalKey<NavigatorState> navigatorKey,
  NotificationDestination? initialNotification,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    initialExtra: initialNotification,
    observers: [PosthogObserver()],
    errorBuilder: (context, state) => const SplashPage(),
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/splash',
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashPage(
          notificationDestination: state.extra is NotificationDestination
              ? state.extra as NotificationDestination
              : null,
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final args = extra is Map ? extra : const {};
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: MainPage(
              nextRoute: args['nextRoute'] as String?,
              notificationDestination: args['notificationDestination']
                      is NotificationDestination
                  ? args['notificationDestination'] as NotificationDestination
                  : null,
            ),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnBoardingPage(),
      ),
      GoRoute(
        path: '/friends/add',
        builder: (context, state) => const PopupBadgeScan(
          prompt: 'Scan a Student ID Badge!',
          title: 'Add Friend',
          enableManualInput: true,
        ),
      ),
      GoRoute(
        path: '/privacy_policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsOfUsePage(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/refresh-balance',
        builder: (context, state) => const SplashPage(nextRoute: '/pay'),
      ),
      GoRoute(
        path: '/no-network',
        builder: (context, state) => const NoNetworkPage(),
      ),
      GoRoute(
        path: '/server-issues',
        builder: (context, state) => const NoServersPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const WelcomeLoginPage(),
      ),
    ],
  );
}
