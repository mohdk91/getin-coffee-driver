import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/storage/onboarding_preference_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/getin_logo.dart';
import '../auth/driver_login_screen.dart';
import '../onboarding/driver_onboarding_screen.dart';

class DriverSplashScreen extends StatefulWidget {
  final AppConfig config;
  final OnboardingCompletionStore completionStore;

  const DriverSplashScreen({
    super.key,
    required this.config,
    this.completionStore = const SharedPreferencesOnboardingCompletionStore(),
  });

  @override
  State<DriverSplashScreen> createState() => _DriverSplashScreenState();
}

class _DriverSplashScreenState extends State<DriverSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: .92, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    unawaited(_animationController.forward());
    unawaited(_continue());
  }

  Future<void> _continue() async {
    final completionFuture = widget.completionStore.isCompleted();
    await Future<void>.delayed(const Duration(milliseconds: 1250));
    final completed = await completionFuture;

    if (!mounted || _navigated) return;
    _navigated = true;

    final showOnboarding = OnboardingLaunchPolicy.shouldShow(
      environment: widget.config.environment,
      completed: completed,
    );

    final destination = showOnboarding
        ? DriverOnboardingScreen(
            config: widget.config,
            completionStore: widget.completionStore,
          )
        : DriverLoginScreen(config: widget.config);

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greenDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashBackdrop(),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(.08),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.beige.withOpacity(.26),
                          ),
                        ),
                        child: const GetinLogoMark(size: 82),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'GETIN DRIVER',
                        style: TextStyle(
                          color: AppColors.beige,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'DELIVERY OPERATIONS',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(.68),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Text(
              'Ready. Pick up. Deliver.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white.withOpacity(.52),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(.2, -.25),
          radius: 1.15,
          colors: [
            Color(0xFF1B4036),
            AppColors.green,
            AppColors.greenDark,
          ],
          stops: [0, .5, 1],
        ),
      ),
      child: CustomPaint(painter: _RouteLinePainter()),
    );
  }
}

class _RouteLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.beige.withOpacity(.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(-20, size.height * .72)
      ..cubicTo(
        size.width * .2,
        size.height * .56,
        size.width * .32,
        size.height * .83,
        size.width * .55,
        size.height * .64,
      )
      ..cubicTo(
        size.width * .74,
        size.height * .48,
        size.width * .83,
        size.height * .58,
        size.width + 30,
        size.height * .36,
      );
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = AppColors.gold.withOpacity(.2);
    canvas.drawCircle(Offset(size.width * .19, size.height * .6), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * .56, size.height * .64), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * .86, size.height * .49), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
