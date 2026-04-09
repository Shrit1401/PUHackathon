import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/motion_tokens.dart';
import '../../features/alerts/presentation/screens/alerts_feed_screen.dart';
import '../../features/assistant/presentation/screens/crisis_assistant_screen.dart';
import '../../features/assistant/presentation/screens/panic_assistant_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/community/presentation/screens/event_detail_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/health/health_ai_screen.dart';
import '../../features/map/presentation/screens/situational_map_screen.dart';
import '../../features/nfc/nfc_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/reports/presentation/screens/quick_report_screen.dart';
import '../../features/reports/presentation/screens/report_incident_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/smartwatch/smartwatch_screen.dart';
import '../../features/tracking/presentation/screens/tracking_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  CustomTransitionPage<void> buildTransitionPage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: MotionTokens.standard,
      reverseTransitionDuration: MotionTokens.fast,
      transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
        final slide = Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: MotionTokens.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: animation.drive(slide), child: pageChild),
        );
      },
    );
  }

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            buildTransitionPage(state: state, child: const OnboardingScreen()),
      ),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            buildTransitionPage(state: state, child: const DashboardScreen()),
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) =>
            buildTransitionPage(state: state, child: const SituationalMapScreen()),
      ),
      GoRoute(
        path: '/health-ai',
        builder: (context, state) =>
            HealthAIScreen(initialMode: state.uri.queryParameters['mode'] ?? 'type'),
      ),
      GoRoute(
        path: '/nfc',
        pageBuilder: (context, state) =>
            buildTransitionPage(state: state, child: const NFCScanScreen()),
      ),
      GoRoute(
        path: '/smartwatch',
        pageBuilder: (context, state) =>
            buildTransitionPage(state: state, child: const SmartwatchScreen()),
      ),
      GoRoute(
        path: '/report',
        pageBuilder: (context, state) =>
            buildTransitionPage(state: state, child: const QuickReportScreen()),
      ),
      GoRoute(path: '/report-form', builder: (context, state) => const ReportIncidentScreen()),
      GoRoute(
        path: '/alerts',
        pageBuilder: (context, state) =>
            buildTransitionPage(state: state, child: const AlertsFeedScreen()),
      ),
      GoRoute(
        path: '/tracking/:id',
        builder: (context, state) => TrackingScreen(
          reportId: state.pathParameters['id']!,
          sosType: state.uri.queryParameters['type'],
        ),
      ),
      GoRoute(
        path: '/assistant',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'type';
          return PanicAssistantScreen(mode: mode);
        },
      ),
      GoRoute(path: '/assistant-lab', builder: (context, state) => const CrisisAssistantScreen()),
      GoRoute(
        path: '/community',
        pageBuilder: (context, state) =>
            buildTransitionPage(state: state, child: const CommunityScreen()),
      ),
      GoRoute(
        path: '/community/event/:id',
        builder: (context, state) => EventDetailScreen(eventId: state.pathParameters['id']!),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

