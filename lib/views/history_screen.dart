import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../widgets/enhanced_attendance_history.dart';

class HistoryScreen extends StatelessWidget {
  final DateTime? initialFocusDate;

  const HistoryScreen({super.key, this.initialFocusDate});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Attendance History',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await authController.refreshAttendanceHistory();
        },
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