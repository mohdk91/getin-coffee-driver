import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import 'data/driver_auth_repository.dart';
import 'domain/driver_auth_models.dart';
import 'widgets/driver_auth_widgets.dart';

class DriverForgotPasswordScreen extends StatefulWidget {
  final AppConfig config;
  final DriverAuthRepository repository;

  const DriverForgotPasswordScreen({
    super.key,
    required this.config,
    required this.repository,
  });

  @override
  State<DriverForgotPasswordScreen> createState() =>
      _DriverForgotPasswordScreenState();
}

class _DriverForgotPasswordScreenState
    extends State<DriverForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  DriverAuthFailure? _failure;
  bool _loading = false;
  String? _successMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _failure = null;
      _successMessage = null;
    });

    final result = await widget.repository.requestPasswordReset(
      identifier: _identifierController.text.trim(),
    );
    if (!mounted) return;

    setState(() {
      _loading = false;
      _failure = result.failure;
      if (result.isSuccess) {
        _successMessage = widget.repository.source == DriverAuthSource.demo
            ? 'Demo reset request created for ${result.data!.destinationLabel}. No email or SMS was sent.'
            : 'Reset instructions requested.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            const SizedBox(height: 8),
            const Text(
              'Recover driver access',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the email address or mobile number registered with your driver account.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            DriverAuthModeBanner(source: widget.repository.source),
            const SizedBox(height: 18),
            DriverAuthSectionCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email or mobile number',
                      style: TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _identifierController,
                      enabled: !_loading,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.emailAddress,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Enter your registered email or mobile number.';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'driver@example.com or +20…',
                        prefixIcon: Icon(Icons.person_search_outlined),
                      ),
                    ),
                    if (_failure != null) ...[
                      const SizedBox(height: 14),
                      DriverAuthErrorCard(
                        failure: _failure!,
                        onRetry: _failure!.retryable ? _submit : null,
                      ),
                    ],
                    if (_successMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(.10),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppColors.success.withOpacity(.22),
                          ),
                        ),
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.beige,
                                ),
                              )
                            : const Text('Request Reset'),
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
