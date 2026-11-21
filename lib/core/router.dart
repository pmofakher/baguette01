import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/budget.dart';
import '../features/categories.dart';
import '../features/home.dart';
import '../features/reports.dart';
import '../features/settings.dart';
import '../features/shell.dart';
import '../features/splash.dart';
import '../features/transactions.dart';
import '../features/wealth.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/transactions',
                builder: (_, __) => const TransactionsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/budget', builder: (_, __) => const BudgetPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/reports', builder: (_, __) => const ReportsPage()),
          ]),
        ],
      ),
      GoRoute(
        path: '/txn/new',
        builder: (_, s) => TxnFormPage(kind: s.uri.queryParameters['kind']),
      ),
      GoRoute(
        path: '/txn/edit/:id',
        builder: (_, s) => TxnFormPage(id: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/txn/:id',
        builder: (_, s) => TxnDetailPage(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/categories', builder: (_, __) => const CategoriesPage()),
      GoRoute(path: '/wealth', builder: (_, __) => const WealthPage()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    ],
  );
});
