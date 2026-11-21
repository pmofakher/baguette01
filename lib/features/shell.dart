import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../state/providers.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell shell;
  const AppShell({super.key, required this.shell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoSync();
    });
  }

  Future<void> _checkAutoSync() async {
    final settings = ref.read(settingsProvider);
    if (!settings.autoSmsSync) return;
    final res =
        await ref.read(smsSyncServiceProvider).sync(requestPermission: false);
    if (res.importedCount > 0 && mounted) {
      ref.bump();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${res.importedCount} تراکنش جدید از پیامک‌ها ثبت شد (نیازمند تعیین دسته)'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: widget.shell),
      floatingActionButton:
          widget.shell.currentIndex <= 1 ? const QuickAddFab() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: (i) =>
            widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'تراکنش‌ها'),
          NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'بودجه'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'گزارش'),
        ],
      ),
    );
  }
}

/// دکمه + که «دخل جدید / خرج جدید» را باز می‌کند (مثل فیگما)
class QuickAddFab extends StatefulWidget {
  const QuickAddFab({super.key});
  @override
  State<QuickAddFab> createState() => _QuickAddFabState();
}

class _QuickAddFabState extends State<QuickAddFab> {
  bool _open = false;

  void _go(String kind) {
    setState(() => _open = false);
    context.push('/txn/new?kind=$kind');
  }

  Widget _pill(String text, String kind) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: BColors.fabPanel,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _go(kind),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Text(text, style: const TextStyle(fontSize: 15)),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_open) ...[_pill('خرج جدید', 'expense'), _pill('دخل جدید', 'income')],
        FloatingActionButton(
          onPressed: () => setState(() => _open = !_open),
          child: AnimatedRotation(
            turns: _open ? .125 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(Icons.add, size: 34),
          ),
        ),
      ],
    );
  }
}
