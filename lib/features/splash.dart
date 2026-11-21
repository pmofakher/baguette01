import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../state/providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});
  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      context.go(ref.read(settingsProvider).onboarded ? '/home' : '/welcome');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.splashBg,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/logo.png', width: 260),
          const SizedBox(height: 16),
          const Text('باگت',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('باگ ولخرجیت کجاس ؟',
              style: TextStyle(color: BColors.primary)),
          const SizedBox(height: 32),
          const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5)),
        ]),
      ),
    );
  }
}

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});
  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final s = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .update(s.copyWith(name: _name.text.trim(), onboarded: true));
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.splashBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            const Spacer(),
            Image.asset('assets/images/logo.png', width: 200),
            const SizedBox(height: 8),
            const Text('باگت',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'مدیریت هزینه‌ات رو شروع کن،\nباگ ولخرجیت رو پیدا کن.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.8),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                  hintText: 'اسمت چیه؟ (اختیاری)', fillColor: Colors.white),
            ),
            const Spacer(),
            FilledButton(onPressed: _start, child: const Text('بزن بریم')),
          ]),
        ),
      ),
    );
  }
}
