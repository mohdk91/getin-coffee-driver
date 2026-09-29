import 'package:flutter/material.dart';

enum DriverTab {
  home('Home', Icons.home_rounded),
  orders('Orders', Icons.receipt_long_rounded),
  earnings('Earnings', Icons.account_balance_wallet_rounded),
  profile('Profile', Icons.person_rounded);

  final String label;
  final IconData icon;

  const DriverTab(this.label, this.icon);
}
