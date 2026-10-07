import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/storage/onboarding_preference_store.dart';
import '../auth/auth_navigation.dart';
import '../auth/data/driver_session_bootstrap_repository.dart';
import '../auth/driver_login_screen.dart';
import '../onboarding/driver_onboarding_screen.dart';

class DriverSplashScreen extends StatefulWidget {
  final AppConfig config;
  final OnboardingCompletionStore completionStore;
  final DriverSessionBootstrapRepository? sessionBootstrapRepository;

  const DriverSplashScreen({
    super.key,
    required this.config,
    this.completionStore = const SharedPreferencesOnboardingCompletionStore(),
    this.sessionBootstrapRepository,
  });

  @override
  State<DriverSplashScreen> createState() => _DriverSplashScreenState();
}

class _DriverSplashScreenState extends State<DriverSplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    unawaited(_continue());
  }

  Future<void> _continue() async {
    final completed = await widget.completionStore.isCompleted();
    if (!mounted || _navigated) return;

    final showOnboarding = OnboardingLaunchPolicy.shouldShow(
      environment: widget.config.environment,
      completed: completed,
    );

    Widget destination;
    if (showOnboarding) {
      destination = DriverOnboardingScreen(
        config: widget.config,
        completionStore: widget.completionStore,
      );
    } else {
      final signInBuilder = (_) => DriverLoginScreen(config: widget.config);
      final bootstrap = widget.sessionBootstrapRepository ??
          DriverSessionBootstrapRepositoryFactory.create(widget.config);
      final restored = await bootstrap.restore();
      if (!mounted || _navigated) return;
      destination = restored.isAuthenticated
          ? driverDestinationAfterAuthentication(
              config: widget.config,
              account: restored.account!,
              signInBuilder: signInBuilder,
            )
          : DriverLoginScreen(config: widget.config);
    }

    if (!mounted || _navigated) return;
    _navigated = true;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The startup gate has just finished the video. Holding its exact final
    // poster avoids a black/white flash while session restoration resolves.
    return Scaffold(
      backgroundColor: const Color(0xFF152A23),
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash/driver_splash_end.jpg',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
