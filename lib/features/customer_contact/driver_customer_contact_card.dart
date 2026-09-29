import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../home/domain/driver_home_models.dart';
import 'data/driver_customer_chat_repository.dart';
import 'data/driver_customer_contact_repository.dart';
import 'driver_customer_chat_screen.dart';

class DriverCustomerContactCard extends StatefulWidget {
  final AppConfig config;
  final DriverActiveDeliverySummary delivery;
  final DriverCustomerContactRepository? contactRepository;
  final DriverCustomerChatRepository? chatRepository;

  const DriverCustomerContactCard({
    super.key,
    required this.config,
    required this.delivery,
    this.contactRepository,
    this.chatRepository,
  });

  @override
  State<DriverCustomerContactCard> createState() =>
      _DriverCustomerContactCardState();
}

class _DriverCustomerContactCardState extends State<DriverCustomerContactCard> {
  late final DriverCustomerContactRepository _contactRepository =
      widget.contactRepository ??
          DriverCustomerContactRepositoryFactory.create(widget.config);
  bool _calling = false;

  Future<void> _call() async {
    if (_calling) return;
    setState(() => _calling = true);
    final result = await _contactRepository.callCustomer(
      orderNumber: widget.delivery.orderNumber,
    );
    if (!mounted) return;
    setState(() => _calling = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  void _chat() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriverCustomerChatScreen(
          config: widget.config,
          delivery: widget.delivery,
          repository: widget.chatRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.contact_phone_rounded, color: AppColors.green),
              SizedBox(width: 8),
              Text(
                'Customer contact',
                style: TextStyle(
                  color: AppColors.greenDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Contact is tied to this order. Getin should use a protected call bridge in production rather than exposing the customer’s private phone number.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 330 || Responsive.isCompact(context);
              final call = OutlinedButton.icon(
                onPressed: _calling ? null : _call,
                icon: _calling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.call_rounded),
                label: const Text('CALL'),
              );
              final chat = FilledButton.icon(
                onPressed: _chat,
                icon: const Icon(Icons.chat_bubble_rounded),
                label: const Text('CHAT'),
              );

              if (compact) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: call),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: chat),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: call),
                  const SizedBox(width: 10),
                  Expanded(child: chat),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
