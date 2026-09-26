import 'package:flutter/material.dart';
import '../tabs/leave_tab.dart';

/// Leave Dashboard Screen - unified with LeaveTab to ensure a single,
/// consistent Apple-luxury UI across both direct navigation and tab access.
class LeaveDashboardScreen extends StatelessWidget {
  const LeaveDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LeaveTab(showBackButton: true);
  }
}
