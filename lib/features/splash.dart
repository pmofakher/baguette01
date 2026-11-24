import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../state/providers.dart';

const _splashQuotes = [
  'پول علف خرس نیست که!',
  'هر که بامش بیش، برفش بیشتر.',
  'گندم از گندم بروید آبجو ز جو.',
  'باد آورده را باد می‌برد، ولی این یکی رو خودت با زحمت درآورده بودی',
  'جیب خالی و پز عالی! ماشالله به این اعتمادبه‌نفس.',
  'سرکه نقد به از حلوای نسیه.',
  'سنگ بزرگ علامت نزدن است.',
  'همه تخم‌مرغاتو تو یه سبد نچین، یهو همه‌ش با هم می‌ره رو هوا',
  'پاتو به اندازه گلیمت دراز کن، نه بیشتر!',
  'سر دو هزار تومن چونه می‌زنی، بعد یهو دو میلیون می‌دی به باد',
  'حواست به همین خرده‌خرج‌ها باشه، درشتا خودشون ردیف می‌شن.',
  'هر چقدر پول بدی همون‌قدر آش می‌خوری، توقع معجزه نداشته باش.',
  'پول که باشه همه‌چی حله، حرف اول و آخر رو پول می‌زنه.',
  'پولی که هنوز نیومده تو حسابت رو از الان خرج نکن!',
  'جنس ارزون بخری، فرداش باید بری یکی دیگه بخری؛ دو بار پول می‌دی.',
  'خفن‌ترین چیزای زندگی اصلاً پولی نیستن، مجانی‌ان.',
  'اگه کار می‌کنی و در نمیاد، تقصیر تو نیست، من می‌فهممت.',
];

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});
  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  late final String _quote =
      _splashQuotes[Random().nextInt(_splashQuotes.length)];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      context.go(ref.read(settingsProvider).onboarded ? '/home' : '/welcome');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.splashBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Image.asset('assets/images/logo.png', width: 260),
              const SizedBox(height: 16),
              const Text('باگت',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('باگ ولخرجیت کجاس ؟',
                  style: TextStyle(color: BColors.primary)),
              const SizedBox(height: 28),
              const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5)),
              const SizedBox(height: 20),
              Text(
                _quote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: BColors.primary,
                  height: 1.6,
                ),
              ),
            ]),
          ),
        ),
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
