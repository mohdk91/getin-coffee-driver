import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import 'data/driver_registration_repository.dart';
import 'domain/driver_registration_models.dart';
import 'driver_registration_submitted_screen.dart';
import 'widgets/driver_registration_widgets.dart';

class DriverRegistrationScreen extends StatefulWidget {
  final AppConfig config;
  final DriverRegistrationRepository? repository;

  const DriverRegistrationScreen({
    super.key,
    required this.config,
    this.repository,
  });

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  static const _stepTitles = [
    'Personal details',
    'Contact',
    'ID & licence',
    'Vehicle',
    'Documents',
    'Service area',
    'Review',
  ];

  final _formKeys = List<GlobalKey<FormState>>.generate(
    7,
    (_) => GlobalKey<FormState>(),
  );

  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _licenceController = TextEditingController();
  final _licenceExpiryController = TextEditingController();
  final _makeModelController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();

  late final DriverRegistrationRepository _repository;

  int _step = 0;
  bool _submitting = false;
  bool _acceptedDeclaration = false;
  DriverRegistrationFailure? _failure;

  String _dialCode = '+20';
  DriverVehicleType _vehicleType = DriverVehicleType.motorbike;
  final Set<DriverRegistrationDocumentType> _documents = {};

  String _country = 'Egypt';
  String _city = 'Alexandria';
  String _region = 'Stanley / San Stefano';
  String _preferredBranch = 'Stanley Branch';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        DriverRegistrationRepositoryFactory.create(widget.config);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _nationalIdController.dispose();
    _licenceController.dispose();
    _licenceExpiryController.dispose();
    _makeModelController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  String? _emailValidator(String? value) {
    final email = (value ?? '').trim();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : 'Enter a valid email address';
  }

  String? _phoneValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid mobile number';
    }
    return null;
  }

  Future<void> _pickDate(TextEditingController controller,
      {bool future = false}) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = future
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: future ? now : DateTime(1940),
      lastDate: future
          ? DateTime(now.year + 15)
          : DateTime(now.year - 18, now.month, now.day),
    );
    if (picked == null) return;
    controller.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    if (mounted) setState(() {});
  }

  bool _validateCurrentStep() {
    if (_step == 4) {
      if (_documents.length != DriverRegistrationDocumentType.values.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Add all required demo documents to continue.')),
        );
        return false;
      }
      return true;
    }
    if (_step == 6) {
      if (!_acceptedDeclaration) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Confirm the declaration before submitting.')),
        );
        return false;
      }
      return true;
    }
    return _formKeys[_step].currentState?.validate() ?? true;
  }

  void _next() {
    if (_submitting || !_validateCurrentStep()) return;
    if (_step == _stepTitles.length - 1) {
      _submit();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _failure = null;
      _step += 1;
    });
  }

  void _back() {
    if (_submitting) return;
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _failure = null;
      _step -= 1;
    });
  }

  DriverRegistrationDraft _buildDraft() {
    return DriverRegistrationDraft(
      fullName: _fullNameController.text.trim(),
      dateOfBirth: _dateOfBirthController.text.trim(),
      dialCode: _dialCode,
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _passwordConfirmationController.text,
      nationalId: _nationalIdController.text.trim(),
      drivingLicenseNumber: _licenceController.text.trim(),
      drivingLicenseExpiry: _licenceExpiryController.text.trim(),
      vehicleType: _vehicleType,
      vehicleMakeModel: _makeModelController.text.trim(),
      plateNumber: _plateController.text.trim(),
      vehicleColor: _colorController.text.trim(),
      documents: Set.unmodifiable(_documents),
      country: _country,
      city: _city,
      region: _region,
      preferredBranch: _preferredBranch,
      acceptedDeclaration: _acceptedDeclaration,
    );
  }

  Future<void> _submit() async {
    if (_submitting || !_validateCurrentStep()) return;
    setState(() {
      _submitting = true;
      _failure = null;
    });

    final result = await _repository.submit(_buildDraft());
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() => _submitting = false);
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DriverRegistrationSubmittedScreen(
            receipt: result.data!,
            source: _repository.source,
          ),
        ),
      );
      return;
    }

    setState(() {
      _submitting = false;
      _failure = result.failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    final horizontal = compact ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.greenDark,
        foregroundColor: AppColors.beige,
        elevation: 0,
        leading: IconButton(
          onPressed: _submitting ? null : _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Driver Registration',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              color: AppColors.greenDark,
              padding: EdgeInsets.fromLTRB(horizontal, 2, horizontal, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Step ${_step + 1} of ${_stepTitles.length}',
                        style: TextStyle(
                          color: AppColors.beige.withOpacity(.72),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _stepTitles[_step],
                        style: const TextStyle(
                          color: AppColors.beige,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DriverRegistrationProgress(
                    currentStep: _step,
                    totalSteps: _stepTitles.length,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 24),
                children: [
                  DriverRegistrationModeBanner(source: _repository.source),
                  const SizedBox(height: 16),
                  DriverRegistrationSectionCard(child: _buildStep()),
                  if (_failure != null) ...[
                    const SizedBox(height: 14),
                    DriverRegistrationFailureCard(
                      failure: _failure!,
                      onRetry: _failure!.retryable ? _submit : null,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal,
                  12 + MediaQuery.viewPaddingOf(context).bottom),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : _back,
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: _step > 0 ? 2 : 1,
                    child: FilledButton(
                      onPressed: _submitting ? null : _next,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.beige,
                              ),
                            )
                          : Text(_step == _stepTitles.length - 1
                              ? 'Submit Application'
                              : 'Continue'),
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

  Widget _buildStep() {
    return switch (_step) {
      0 => _personalStep(),
      1 => _contactStep(),
      2 => _identityStep(),
      3 => _vehicleStep(),
      4 => _documentsStep(),
      5 => _serviceAreaStep(),
      _ => _reviewStep(),
    };
  }

  Widget _stepIntro(String title, String text, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.beige.withOpacity(.35),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.greenDark),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.greenDark,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -.3,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _personalStep() {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIntro(
              'Tell us about you',
              'Enter your legal details exactly as they appear on your documents.',
              Icons.person_outline_rounded),
          TextFormField(
            controller: _fullNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (value) => _required(value, 'Full name'),
            decoration: const InputDecoration(
              labelText: 'Full legal name',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dateOfBirthController,
            readOnly: true,
            validator: (value) => _required(value, 'Date of birth'),
            onTap: () => _pickDate(_dateOfBirthController),
            decoration: const InputDecoration(
              labelText: 'Date of birth',
              hintText: 'YYYY-MM-DD',
              prefixIcon: Icon(Icons.cake_outlined),
              suffixIcon: Icon(Icons.calendar_month_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactStep() {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIntro(
              'How can Getin reach you?',
              'Use contact details you can access during registration and delivery work.',
              Icons.contact_phone_outlined),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _dialCode,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Code'),
                  items: const [
                    DropdownMenuItem(
                        value: '+20',
                        child:
                            Text('🇪🇬 +20', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: '+971',
                        child:
                            Text('🇦🇪 +971', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: '+966',
                        child:
                            Text('🇸🇦 +966', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (value) =>
                      setState(() => _dialCode = value ?? '+20'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: _emailValidator,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final password = value ?? '';
              if (password.length < 8) return 'Use at least 8 characters';
              if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
                  !RegExp(r'[0-9]').hasMatch(password)) {
                return 'Include at least one letter and one number';
              }
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordConfirmationController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) => value == _passwordController.text
                ? null
                : 'Passwords do not match',
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: Icon(Icons.lock_reset_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _identityStep() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIntro(
              'Identity & licence',
              'These details will later be verified by Getin operations.',
              Icons.verified_user_outlined),
          TextFormField(
            controller: _nationalIdController,
            validator: (value) => _required(value, 'National ID'),
            decoration: const InputDecoration(
              labelText: 'National ID / identity number',
              prefixIcon: Icon(Icons.credit_card_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _licenceController,
            validator: (value) => _required(value, 'Driving licence number'),
            decoration: const InputDecoration(
              labelText: 'Driving licence number',
              prefixIcon: Icon(Icons.assignment_ind_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _licenceExpiryController,
            readOnly: true,
            validator: (value) => _required(value, 'Licence expiry'),
            onTap: () => _pickDate(_licenceExpiryController, future: true),
            decoration: const InputDecoration(
              labelText: 'Licence expiry',
              hintText: 'YYYY-MM-DD',
              prefixIcon: Icon(Icons.event_available_outlined),
              suffixIcon: Icon(Icons.calendar_month_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleStep() {
    return Form(
      key: _formKeys[3],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIntro(
              'Your delivery vehicle',
              'Vehicle eligibility and assignment rules will ultimately come from the backend.',
              Icons.delivery_dining_outlined),
          DropdownButtonFormField<DriverVehicleType>(
            value: _vehicleType,
            decoration: const InputDecoration(
              labelText: 'Vehicle type',
              prefixIcon: Icon(Icons.two_wheeler_rounded),
            ),
            items: DriverVehicleType.values
                .map((value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)))
                .toList(),
            onChanged: (value) => setState(
                () => _vehicleType = value ?? DriverVehicleType.motorbike),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _makeModelController,
            validator: (value) => _required(value, 'Make/model'),
            decoration: const InputDecoration(
              labelText: 'Make / model',
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _plateController,
            textCapitalization: TextCapitalization.characters,
            validator: (value) => _required(value, 'Plate number'),
            decoration: const InputDecoration(
              labelText: 'Plate number',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _colorController,
            textCapitalization: TextCapitalization.words,
            validator: (value) => _required(value, 'Vehicle color'),
            decoration: const InputDecoration(
              labelText: 'Vehicle color',
              prefixIcon: Icon(Icons.palette_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentsStep() {
    return Form(
      key: _formKeys[4],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIntro(
              'Required documents',
              'Task #4 uses demo document selections only. Native upload and replacement handling belongs to the later document workflow.',
              Icons.folder_copy_outlined),
          ...DriverRegistrationDocumentType.values.map(
            (type) => DriverDocumentCard(
              type: type,
              attached: _documents.contains(type),
              onPressed: () {
                setState(() {
                  if (_documents.contains(type)) {
                    _documents.remove(type);
                  } else {
                    _documents.add(type);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceAreaStep() {
    return Form(
      key: _formKeys[5],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIntro(
              'Preferred service area',
              'This demo catalog previews region and branch preference. Final assignment is controlled by Getin operations.',
              Icons.location_on_outlined),
          DropdownButtonFormField<String>(
            value: _country,
            decoration: const InputDecoration(labelText: 'Country'),
            items: const [
              DropdownMenuItem(value: 'Egypt', child: Text('Egypt'))
            ],
            onChanged: (value) => setState(() => _country = value ?? 'Egypt'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _city,
            decoration: const InputDecoration(labelText: 'City'),
            items: const [
              DropdownMenuItem(value: 'Alexandria', child: Text('Alexandria'))
            ],
            onChanged: (value) => setState(() => _city = value ?? 'Alexandria'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _region,
            decoration:
                const InputDecoration(labelText: 'Preferred region / zone'),
            items: const [
              DropdownMenuItem(
                  value: 'Stanley / San Stefano',
                  child: Text('Stanley / San Stefano')),
              DropdownMenuItem(value: 'Gleem', child: Text('Gleem')),
              DropdownMenuItem(value: 'Smouha', child: Text('Smouha')),
            ],
            onChanged: (value) =>
                setState(() => _region = value ?? 'Stanley / San Stefano'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _preferredBranch,
            decoration: const InputDecoration(labelText: 'Preferred branch'),
            items: const [
              DropdownMenuItem(
                  value: 'Stanley Branch', child: Text('Stanley Branch')),
              DropdownMenuItem(
                  value: 'Gleem Branch', child: Text('Gleem Branch')),
            ],
            onChanged: (value) =>
                setState(() => _preferredBranch = value ?? 'Stanley Branch'),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 19, color: AppColors.info),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Preferred branch is a request only. Assigned regions, allowed branches, and delivery radius will be backend-controlled.',
                    style: TextStyle(
                        color: AppColors.muted, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewStep() {
    return Form(
      key: _formKeys[6],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIntro(
              'Review your application',
              'Check the information below before submitting it for review.',
              Icons.fact_check_outlined),
          DriverReviewRow(
              label: 'Name', value: _fullNameController.text.trim()),
          DriverReviewRow(
              label: 'Contact',
              value:
                  '$_dialCode ${_phoneController.text.trim()}\n${_emailController.text.trim()}'),
          DriverReviewRow(
              label: 'ID', value: _nationalIdController.text.trim()),
          DriverReviewRow(
              label: 'Licence',
              value:
                  '${_licenceController.text.trim()} · expires ${_licenceExpiryController.text.trim()}'),
          DriverReviewRow(
              label: 'Vehicle',
              value:
                  '${_vehicleType.label} · ${_makeModelController.text.trim()} · ${_plateController.text.trim()}'),
          DriverReviewRow(
              label: 'Documents',
              value:
                  '${_documents.length}/${DriverRegistrationDocumentType.values.length} selected'),
          DriverReviewRow(
              label: 'Service area',
              value: '$_country · $_city\n$_region · $_preferredBranch'),
          const DriverReviewRow(
            label: 'Assigned branch',
            value: 'Set by Getin operations after approval',
          ),
          const Divider(height: 28),
          CheckboxListTile(
            value: _acceptedDeclaration,
            onChanged: (value) =>
                setState(() => _acceptedDeclaration = value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'I confirm the information is accurate and may be reviewed by Getin operations.',
              style: TextStyle(
                color: AppColors.greenDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
