import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import 'auth_navigation.dart';
import 'data/driver_auth_repository.dart';
import 'domain/driver_auth_models.dart';
import 'driver_forgot_password_screen.dart';
import 'driver_otp_screen.dart';
import 'widgets/driver_auth_widgets.dart';
import '../registration/driver_registration_screen.dart';

class DriverLoginScreen extends StatefulWidget {
  final AppConfig config;
  final DriverAuthRepository? repository;

  const DriverLoginScreen({
    super.key,
    required this.config,
    this.repository,
  });

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final DriverAuthRepository _repository;

  bool _phoneMode = true;
  bool _loading = false;
  bool _hidePassword = true;
  DriverAuthFailure? _failure;
  VoidCallback? _retryAction;

  String _dialCode = '+20';
  String _flag = '🇪🇬';
  String _countryName = 'Egypt';

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? DriverAuthRepositoryFactory.create(widget.config);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setMode(bool phoneMode) {
    if (_loading || _phoneMode == phoneMode) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _phoneMode = phoneMode;
      _failure = null;
      _retryAction = null;
    });
  }

  void _selectCountry() {
    if (_loading) return;
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        backgroundColor: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        inputDecoration: InputDecoration(
          labelText: 'Search country or dial code',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onSelect: (country) {
        setState(() {
          _dialCode = '+${country.phoneCode}';
          _flag = country.flagEmoji;
          _countryName = country.name;
        });
      },
    );
  }

  Future<void> _sendOtp() async {
    if (_loading) return;
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _failure = null;
      _retryAction = null;
    });

    final phone = _phoneController.text.trim();
    final result = await _repository.requestOtp(
      dialCode: _dialCode,
      phoneNumber: phone,
    );
    if (!mounted) return;

    setState(() => _loading = false);

    if (result.isSuccess) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DriverOtpScreen(
            config: widget.config,
            repository: _repository,
            challenge: result.data!,
            dialCode: _dialCode,
            phoneNumber: phone,
            signInBuilder: (_) => DriverLoginScreen(
              config: widget.config,
              repository: _repository,
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _failure = result.failure;
      _retryAction = result.failure?.retryable == true ? _sendOtp : null;
    });
  }

  Future<void> _emailSignIn() async {
    if (_loading) return;
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _failure = null;
      _retryAction = null;
    });

    final result = await _repository.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;

    setState(() => _loading = false);

    if (result.isSuccess) {
      await navigateAfterDriverAuthentication(
        context: context,
        config: widget.config,
        account: result.data!,
        signInBuilder: (_) => DriverLoginScreen(
          config: widget.config,
          repository: _repository,
        ),
      );
      return;
    }

    setState(() {
      _failure = result.failure;
      _retryAction = result.failure?.retryable == true ? _emailSignIn : null;
    });
  }

  void _showDemoHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, 4, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Task #3 local demo',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Phone login accepts any valid-looking number. On the next screen use OTP 123456 for an approved driver. Other OTP codes preview blocked and error states.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Email demo credentials',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 10),
              _CredentialRow('driver@getin.local', 'Approved driver'),
              _CredentialRow('pending@getin.local', 'Pending approval'),
              _CredentialRow('review@getin.local', 'More information needed'),
              _CredentialRow('suspended@getin.local', 'Suspended'),
              _CredentialRow('rejected@getin.local', 'Rejected'),
              _CredentialRow('disabled@getin.local', 'Disabled'),
              _CredentialRow('server@getin.local', 'Temporary failure'),
              SizedBox(height: 10),
              Text(
                'Password for demo accounts: Driver123!',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'No real credential, OTP, SMS, email, or token is sent or stored by this demo.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.4,
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

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(context).bottom + 24),
          children: [
            const DriverAuthHeader(
              eyebrow: 'Getin Driver',
              title: 'Driver Login',
              subtitle: 'Secure access for approved Getin delivery drivers.',
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 20, 20, compact ? 16 : 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DriverAuthModeBanner(
                    source: _repository.source,
                    onDemoHelp: _repository.source == DriverAuthSource.demo
                        ? _showDemoHelp
                        : null,
                  ),
                  const SizedBox(height: 18),
                  DriverAuthSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            color: AppColors.greenDark,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _phoneMode
                              ? 'Use the mobile number registered with Getin operations.'
                              : 'Use your registered driver email and password.',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _ModeButton(
                                  label: 'Mobile',
                                  icon: Icons.phone_iphone_rounded,
                                  selected: _phoneMode,
                                  onTap: () => _setMode(true),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _ModeButton(
                                  label: 'Email',
                                  icon: Icons.mail_outline_rounded,
                                  selected: !_phoneMode,
                                  onTap: () => _setMode(false),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _phoneMode
                              ? Form(
                                  key: _phoneFormKey,
                                  child: Column(
                                    key: const ValueKey('phone-form'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Mobile number',
                                        style: TextStyle(
                                          color: AppColors.greenDark,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          border: Border.all(
                                              color: AppColors.border),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: _loading
                                                  ? null
                                                  : _selectCountry,
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                left: Radius.circular(15),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 17,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(_flag,
                                                        style: const TextStyle(
                                                            fontSize: 19)),
                                                    const SizedBox(width: 7),
                                                    Text(
                                                      _dialCode,
                                                      style: const TextStyle(
                                                        color:
                                                            AppColors.greenDark,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      size: 18,
                                                      color: AppColors.muted,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 32,
                                              child: VerticalDivider(width: 1),
                                            ),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _phoneController,
                                                enabled: !_loading,
                                                keyboardType:
                                                    TextInputType.phone,
                                                textInputAction:
                                                    TextInputAction.done,
                                                onFieldSubmitted: (_) =>
                                                    _sendOtp(),
                                                validator: (value) {
                                                  final digits = (value ?? '')
                                                      .replaceAll(
                                                          RegExp(r'[^0-9]'),
                                                          '');
                                                  if (digits.length < 7 ||
                                                      digits.length > 15) {
                                                    return 'Enter a valid mobile number';
                                                  }
                                                  return null;
                                                },
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: 'Phone number',
                                                  filled: false,
                                                  border: InputBorder.none,
                                                  enabledBorder:
                                                      InputBorder.none,
                                                  focusedBorder:
                                                      InputBorder.none,
                                                  errorBorder: InputBorder.none,
                                                  focusedErrorBorder:
                                                      InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                    horizontal: 13,
                                                    vertical: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        'Selected country: $_countryName',
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton(
                                          onPressed: _loading ? null : _sendOtp,
                                          child: _loading
                                              ? const _ButtonLoader()
                                              : const Text('Continue'),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Form(
                                  key: _emailFormKey,
                                  child: Column(
                                    key: const ValueKey('email-form'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Email address',
                                        style: TextStyle(
                                          color: AppColors.greenDark,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _emailController,
                                        enabled: !_loading,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.username
                                        ],
                                        validator: (value) {
                                          final email = (value ?? '').trim();
                                          final valid = RegExp(
                                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                              .hasMatch(email);
                                          return valid
                                              ? null
                                              : 'Enter a valid email address';
                                        },
                                        decoration: const InputDecoration(
                                          hintText: 'driver@example.com',
                                          prefixIcon:
                                              Icon(Icons.mail_outline_rounded),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Password',
                                        style: TextStyle(
                                          color: AppColors.greenDark,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _passwordController,
                                        enabled: !_loading,
                                        obscureText: _hidePassword,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.password
                                        ],
                                        onFieldSubmitted: (_) => _emailSignIn(),
                                        validator: (value) {
                                          if ((value ?? '').length < 8) {
                                            return 'Password must be at least 8 characters';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Enter password',
                                          prefixIcon: const Icon(
                                              Icons.lock_outline_rounded),
                                          suffixIcon: IconButton(
                                            onPressed: _loading
                                                ? null
                                                : () => setState(
                                                      () => _hidePassword =
                                                          !_hidePassword,
                                                    ),
                                            icon: Icon(
                                              _hidePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: _loading
                                              ? null
                                              : () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute<void>(
                                                      builder: (_) =>
                                                          DriverForgotPasswordScreen(
                                                        config: widget.config,
                                                        repository: _repository,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          child: const Text('Forgot Password?'),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton(
                                          onPressed:
                                              _loading ? null : _emailSignIn,
                                          child: _loading
                                              ? const _ButtonLoader()
                                              : const Text('Sign In'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        if (_failure != null) ...[
                          const SizedBox(height: 16),
                          DriverAuthErrorCard(
                            failure: _failure!,
                            onRetry: _retryAction,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.badge_outlined,
                                color: AppColors.green, size: 21),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'New to Getin Driver? Create an application for Getin operations to review.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _loading
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            DriverRegistrationScreen(
                                          config: widget.config,
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: const Text('Apply to Drive'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.greenDark : AppColors.muted,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.greenDark : AppColors.muted,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ButtonLoader extends StatelessWidget {
  const _ButtonLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        color: AppColors.beige,
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final String email;
  final String meaning;

  const _CredentialRow(this.email, this.meaning);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              email,
              style: const TextStyle(
                color: AppColors.greenDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              meaning,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
