import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import 'auth_navigation.dart';
import 'data/driver_auth_repository.dart';
import 'domain/driver_auth_models.dart';
import 'widgets/driver_auth_widgets.dart';

class DriverOtpScreen extends StatefulWidget {
  final AppConfig config;
  final DriverAuthRepository repository;
  final DriverOtpChallenge challenge;
  final String dialCode;
  final String phoneNumber;
  final WidgetBuilder signInBuilder;

  const DriverOtpScreen({
    super.key,
    required this.config,
    required this.repository,
    required this.challenge,
    required this.dialCode,
    required this.phoneNumber,
    required this.signInBuilder,
  });

  @override
  State<DriverOtpScreen> createState() => _DriverOtpScreenState();
}

class _DriverOtpScreenState extends State<DriverOtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  DriverAuthFailure? _failure;
  bool _verifying = false;
  bool _resending = false;
  int _resendSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    _resendSeconds = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  String get _code => _controllers.map((controller) => controller.text).join();

  Future<void> _verify() async {
    if (_verifying || _resending) return;
    if (_code.length != 6) {
      setState(() {
        _failure = const DriverAuthFailure(
          type: DriverAuthFailureType.invalidInput,
          message: 'Enter the complete 6-digit verification code.',
        );
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _failure = null;
    });

    final result = await widget.repository.verifyOtp(
      challenge: widget.challenge,
      code: _code,
    );
    if (!mounted) return;

    setState(() {
      _verifying = false;
      _failure = result.failure;
    });

    if (result.isSuccess) {
      await navigateAfterDriverAuthentication(
        context: context,
        config: widget.config,
        account: result.data!,
        signInBuilder: widget.signInBuilder,
      );
    }
  }

  Future<void> _resend() async {
    if (_resending || _verifying || _resendSeconds > 0) return;

    setState(() {
      _resending = true;
      _failure = null;
    });

    final result = await widget.repository.requestOtp(
      dialCode: widget.dialCode,
      phoneNumber: widget.phoneNumber,
    );
    if (!mounted) return;

    setState(() {
      _resending = false;
      _failure = result.failure;
      if (result.isSuccess) {
        for (final controller in _controllers) {
          controller.clear();
        }
        _nodes.first.requestFocus();
        _startResendTimer();
      }
    });
  }

  void _showDemoCodes() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task #3 demo OTP codes',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 14),
              _DemoCodeRow('123456', 'Approved driver — can enter Driver app'),
              _DemoCodeRow('111111', 'Invalid code'),
              _DemoCodeRow('222222', 'Expired code'),
              _DemoCodeRow('333333', 'Pending approval'),
              _DemoCodeRow('444444', 'Additional information required'),
              _DemoCodeRow('555555', 'Suspended account'),
              _DemoCodeRow('666666', 'Disabled account'),
              _DemoCodeRow('777777', 'Temporary server failure / retry'),
              _DemoCodeRow('888888', 'Rejected driver'),
              _DemoCodeRow('999999', 'Too many attempts'),
              SizedBox(height: 12),
              Text(
                'These codes exist only in the local demo repository. They are not real authentication codes.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    final gap = compact ? 5.0 : 8.0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: IconButton(
          onPressed:
              _verifying || _resending ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Verify Mobile'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding:
              EdgeInsets.fromLTRB(compact ? 18 : 22, 10, compact ? 18 : 22, 30),
          children: [
            Text(
              'Enter your code',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: compact ? 27 : 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verification code for ${widget.challenge.destinationLabel}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            DriverAuthModeBanner(
              source: widget.repository.source,
              onDemoHelp: widget.repository.source == DriverAuthSource.demo
                  ? _showDemoCodes
                  : null,
            ),
            const SizedBox(height: 22),
            Row(
              children: List.generate(6, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 5 ? 0 : gap),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _nodes[index],
                      enabled: !_verifying && !_resending,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textInputAction: index == 5
                          ? TextInputAction.done
                          : TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 1,
                      onChanged: (value) {
                        if (_failure != null) {
                          setState(() => _failure = null);
                        }
                        if (value.isNotEmpty && index < 5) {
                          _nodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _nodes[index - 1].requestFocus();
                        } else if (value.isNotEmpty && index == 5) {
                          FocusScope.of(context).unfocus();
                        }
                      },
                      onSubmitted: index == 5 ? (_) => _verify() : null,
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: compact ? 14 : 17,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_failure != null) ...[
              const SizedBox(height: 16),
              DriverAuthErrorCard(
                failure: _failure!,
                onRetry: _failure!.retryable ? _verify : null,
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _resendSeconds > 0
                        ? 'Resend available in ${_resendSeconds}s'
                        : 'Didn’t receive a code?',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _resendSeconds == 0 && !_resending && !_verifying
                      ? _resend
                      : null,
                  child: _resending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resend Code'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _verifying || _resending ? null : _verify,
                child: _verifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.beige,
                        ),
                      )
                    : const Text('Verify & Continue'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _verifying || _resending
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('Change mobile number'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoCodeRow extends StatelessWidget {
  final String code;
  final String description;

  const _DemoCodeRow(this.code, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.greenDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code,
              style: const TextStyle(
                color: AppColors.beige,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                description,
                style: const TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
