import 'package:flutter/material.dart';
import 'package:runshaw/pages/main/subpages/friends/list/widgets/popup_add_page.dart';
import 'package:runshaw/pages/password/password_reset.dart';
import 'package:runshaw/pages/privacy/privacy_policy.dart';
import 'package:runshaw/pages/splash/splash.dart';
import 'package:runshaw/pages/terms/terms_of_use.dart';
import 'package:runshaw/pages/about/about.dart';
import 'package:runshaw/utils/logging.dart';

class AppRouteHandler {
  static const String _widgetRefreshPath = '/refresh-balance';

  /// Extract path from deep link URIs
  static String _extractPathFromUri(String routeName) {
    if (routeName.contains('://')) {
      try {
        final Uri uri = Uri.parse(routeName);
        return uri.path.isEmpty ? '/' : uri.path;
      } catch (e) {
        debugLog('Error parsing deep link: $e', level: 2);
      }
    }
    return routeName;
  }

  /// Handle initial routes when app starts from deep link (cold start)
  static List<Route<dynamic>> onGenerateInitialRoutes(String? initialRoute) {
    debugLog('onGenerateInitialRoutes called with: $initialRoute', level: 1);

    String routePath = '/splash';
    if (initialRoute != null && initialRoute.isNotEmpty) {
      routePath = _extractPathFromUri(initialRoute);
      debugLog('Extracted initial route path: $routePath', level: 1);
    }

    return [_buildRouteForPath(routePath)];
  }

  /// Handle routes after app is already running
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final String? routeName = settings.name;
    debugLog('onGenerateRoute called with: $routeName', level: 1);

    if (routeName != null) {
      final String path = _extractPathFromUri(routeName);
      return _buildRouteForPath(path);
    }

    // Fallback to splash
    return _buildRouteForPath('/splash');
  }

  /// Build the appropriate MaterialPageRoute for a given path
  static MaterialPageRoute _buildRouteForPath(String path) {
    switch (path) {
      case _widgetRefreshPath:
        return MaterialPageRoute(
          builder: (context) => const SplashPage(nextRoute: '/pay'),
          settings: const RouteSettings(name: _widgetRefreshPath),
        );
      case '/friends/add':
        return MaterialPageRoute(
          builder: (context) => const PopupFriendAddPage(),
          settings: const RouteSettings(name: '/friends/add'),
        );
      case '/privacy_policy':
        return MaterialPageRoute(
          builder: (context) => const PrivacyPolicyPage(),
          settings: const RouteSettings(name: '/privacy_policy'),
        );
      case '/change_password':
        return MaterialPageRoute(
          builder: (context) => const PasswordResetPage(),
          settings: const RouteSettings(name: '/change_password'),
        );
      case '/terms':
        return MaterialPageRoute(
          builder: (context) => const TermsOfUsePage(),
          settings: const RouteSettings(name: '/terms'),
        );
      case '/about':
        return MaterialPageRoute(
          builder: (context) => const AboutPage(),
          settings: const RouteSettings(name: '/about'),
        );
      case '/splash':
      case '/':
      default:
        return MaterialPageRoute(
          builder: (context) => const SplashPage(),
          settings: const RouteSettings(name: '/splash'),
        );
    }
  }

  /// Standard named routes for use in MaterialApp.routes
  static Map<String, WidgetBuilder> getNamedRoutes() {
    return {
      '/splash': (BuildContext context) => const SplashPage(),
      '/friends/add': (BuildContext context) => const PopupFriendAddPage(),
      '/privacy_policy': (BuildContext context) => const PrivacyPolicyPage(),
      '/change_password': (BuildContext context) => const PasswordResetPage(),
      '/terms': (BuildContext context) => const TermsOfUsePage(),
      '/about': (BuildContext context) => const AboutPage(),
      '/refresh-balance': (BuildContext context) =>
          const SplashPage(nextRoute: '/pay'),
    };
  }
}
