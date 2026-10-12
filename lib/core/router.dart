import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/admin.dart';
import '../features/auth.dart';
import '../features/directory_tow.dart';
import '../features/garage_history_profile.dart';
import '../features/home_map.dart';
import '../features/marketplace.dart';
import '../features/mechanic.dart';
import '../features/misc.dart';
import '../features/sos.dart';
import 'store.dart';

GoRouter buildRouter(WidgetRef ref) {
  final session = ref.watch(sessionProvider);
  return GoRouter(
    initialLocation: session.loggedIn ? '/map' : '/welcome',
    redirect: (ctx, state) {
      final logged = session.loggedIn;
      final loc = state.matchedLocation;
      if (!logged && !['/welcome', '/login', '/role', '/terms'].contains(loc)) return '/welcome';
      if (logged && ['/welcome', '/login'].contains(loc)) return '/map';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/role', builder: (_, __) => const RoleScreen()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
      ShellRoute(
        builder: (ctx, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
          GoRoute(path: '/mechanics', builder: (_, __) => const DirectoryScreen()),
          GoRoute(path: '/tow', builder: (_, __) => const TowScreen()),
          GoRoute(path: '/market', builder: (_, __) => const MarketScreen()),
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/sos/new', builder: (_, __) => const SosFormScreen()),
      GoRoute(path: '/sos/track', builder: (_, __) => const SosTrackScreen()),
      GoRoute(path: '/crash', builder: (_, __) => const CrashScreen()),
      GoRoute(path: '/call/new', builder: (_, __) => const CallMechanicScreen()),
      GoRoute(path: '/call/track', builder: (_, __) => const OrderTrackScreen()),
      GoRoute(path: '/mechanic/inbox', builder: (_, __) => const MechanicInboxScreen()),
      GoRoute(path: '/mechanic/register', builder: (_, __) => const MechanicRegisterScreen()),
      GoRoute(path: '/tow/edit', builder: (_, __) => const TowEditScreen()),
      GoRoute(path: '/garage', builder: (_, __) => const GarageScreen()),
      GoRoute(path: '/notifs', builder: (_, __) => const NotifsScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
      GoRoute(path: '/garage-page/:id', builder: (ctx, st) => GaragePageScreen(id: st.pathParameters['id']!)),
      GoRoute(path: '/listing/:id', builder: (ctx, st) => ListingDetailScreen(id: st.pathParameters['id']!)),
    ],
  );
}

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(l10nProvider);
    final loc = GoRouterState.of(context).matchedLocation;
    final tabs = [
      ('/map', Icons.map_outlined, l.t('map')),
      ('/mechanics', Icons.build_outlined, l.t('mechanics')),
      ('/tow', Icons.local_shipping_outlined, l.t('tow')),
      ('/market', Icons.storefront_outlined, l.t('market')),
      ('/profile', Icons.person_outline, l.t('profile')),
    ];
    final idx = tabs.indexWhere((t) => loc.startsWith(t.$1));
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx < 0 ? 0 : idx,
        onDestinationSelected: (i) => context.go(tabs[i].$1),
        destinations: [for (final t in tabs) NavigationDestination(icon: Icon(t.$2), label: t.$3)],
      ),
    );
  }
}
