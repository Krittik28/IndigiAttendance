import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/enhanced_attendance_history.dart';

class HistoryScreen extends StatelessWidget {
  final DateTime? initialFocusDate;

  const HistoryScreen({super.key, this.initialFocusDate});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: AppTheme.surface,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await authController.refreshAttendanceHistory();
        },
        color: AppTheme.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: EnhancedAttendanceHistory(
            attendanceList: authController.attendanceHistory,
            onRefresh: () async {
              await authController.refreshAttendanceHistory();
            },
            isRefreshing: authController.isRefreshingHistory,
            initialFocusDate: initialFocusDate,
          ),
        ),
      ),
    );
  }
}