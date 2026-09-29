import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/storage/onboarding_preference_store.dart';
import '../../core/theme/app_colors.dart';
import '../auth/driver_login_screen.dart';

class DriverOnboardingScreen extends StatefulWidget {
  final AppConfig config;
  final OnboardingCompletionStore completionStore;

  const DriverOnboardingScreen({
    super.key,
    required this.config,
    this.completionStore = const SharedPreferencesOnboardingCompletionStore(),
  });

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  final PageController _pageController = PageController();

  int _index = 0;
  bool _finishing = false;

  static const List<_OnboardingStep> _steps = [
    _OnboardingStep(
      image: 'assets/images/onboarding/onboarding_1.jpg',
      title: 'Drive with Getin',
      body: 'Go online, accept deliveries, and keep every shift moving.',
    ),
    _OnboardingStep(
      image: 'assets/images/onboarding/onboarding_2.jpg',
      title: 'Follow the Flow',
      body: 'Accept, pick up, deliver, and complete every order step by step.',
    ),
    _OnboardingStep(
      image: 'assets/images/onboarding/onboarding_3.jpg',
      title: 'Stay on Route',
      body: 'Use GPS guidance to reach every branch and customer smoothly.',
    ),
    _OnboardingStep(
      image: 'assets/images/onboarding/onboarding_4.jpg',
      title: 'Never Miss an Update',
      body:
          'See new orders, customer messages, and delivery updates instantly.',
    ),
    _OnboardingStep(
      image: 'assets/images/onboarding/onboarding_5.jpg',
      title: 'Verify Every Delivery',
      body: 'Use a QR scan or delivery code to confirm each handoff securely.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.black,
      ),
    );
  }

  Future<void> _finish() async {
    if (_finishing) return;

    setState(() => _finishing = true);

    try {
      await widget.completionStore.markCompleted();
      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DriverLoginScreen(config: widget.config),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _finishing = false);
      }
    }
  }

  void _next() {
    if (_index == _steps.length - 1) {
      unawaited(_finish());
      return;
    }

    unawaited(
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];
    final media = MediaQuery.of(context);
    final compactHeight = media.size.height < 700;
    final narrowWidth = media.size.width < 370;

    final horizontalPadding = narrowWidth ? 20.0 : 24.0;
    final titleSize = narrowWidth
        ? 28.0
        : compactHeight
            ? 29.0
            : 34.0;
    final copyHeight = compactHeight ? 128.0 : 146.0;
    final buttonHeight = compactHeight ? 54.0 : 58.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: AppColors.greenDark,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _steps.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      _steps[index].image,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x08000000),
                            Color(0x160D211C),
                            Color(0xB80D211C),
                            Color(0xF50D211C),
                          ],
                          stops: [0.0, 0.47, 0.72, 1.0],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  compactHeight ? 12 : 18,
                  horizontalPadding,
                  compactHeight ? 18 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed:
                            _finishing ? null : () => unawaited(_finish()),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.beige,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          minimumSize: const Size(52, 44),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: Color(0xA6000000),
                                blurRadius: 8,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: copyHeight,
                      width: double.infinity,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.topLeft,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: Column(
                          key: ValueKey<int>(_index),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              step.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.beige,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                letterSpacing: -0.6,
                              ),
                            ),
                            SizedBox(height: compactHeight ? 8 : 12),
                            Text(
                              step.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(.94),
                                fontSize: compactHeight ? 14 : 15.5,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: compactHeight ? 14 : 18),
                    Row(
                      children: List.generate(
                        _steps.length,
                        (dotIndex) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.only(right: 8),
                          width: dotIndex == _index ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotIndex == _index
                                ? AppColors.gold
                                : Colors.white.withOpacity(.50),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compactHeight ? 18 : 22),
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: FilledButton(
                        onPressed: _finishing ? null : _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.beige,
                          foregroundColor: AppColors.greenDark,
                          disabledBackgroundColor:
                              AppColors.beige.withOpacity(.55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _finishing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Text(
                                _index == _steps.length - 1
                                    ? 'Get Started'
                                    : 'Continue',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final String image;
  final String title;
  final String body;

  const _OnboardingStep({
    required this.image,
    required this.title,
    required this.body,
  });
}
