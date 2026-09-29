enum DriverCommissionDataSource { demo, api }

enum DriverCommissionRuleCategory {
  baseEarning,
  distanceBonus,
  peakBonus,
  tip,
  adjustment,
}

extension DriverCommissionRuleCategoryLabel on DriverCommissionRuleCategory {
  String get label => switch (this) {
        DriverCommissionRuleCategory.baseEarning => 'Base earning',
        DriverCommissionRuleCategory.distanceBonus => 'Distance bonus',
        DriverCommissionRuleCategory.peakBonus => 'Peak bonus',
        DriverCommissionRuleCategory.tip => 'Tips',
        DriverCommissionRuleCategory.adjustment => 'Adjustments',
      };
}

class DriverCommissionRule {
  final String id;
  final DriverCommissionRuleCategory category;
  final String title;
  final String calculationLabel;
  final String description;
  final bool active;

  const DriverCommissionRule({
    required this.id,
    required this.category,
    required this.title,
    required this.calculationLabel,
    required this.description,
    this.active = true,
  });
}

class DriverCommissionPolicy {
  final String policyVersion;
  final String currencyCode;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;
  final DateTime updatedAt;
  final List<DriverCommissionRule> rules;
  final bool backendDriven;
  final bool historicalSnapshotRequired;
  final bool editableInDriverApp;

  const DriverCommissionPolicy({
    required this.policyVersion,
    required this.currencyCode,
    required this.effectiveFrom,
    required this.effectiveUntil,
    required this.updatedAt,
    required this.rules,
    this.backendDriven = true,
    this.historicalSnapshotRequired = true,
    this.editableInDriverApp = false,
  });

  List<DriverCommissionRule> get activeRules =>
      rules.where((rule) => rule.active).toList(growable: false);
}

class DriverCommissionLoadResult {
  final DriverCommissionPolicy? policy;
  final String? errorMessage;

  const DriverCommissionLoadResult._({this.policy, this.errorMessage});

  const DriverCommissionLoadResult.success(DriverCommissionPolicy value)
      : this._(policy: value);

  const DriverCommissionLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => policy != null;
}
