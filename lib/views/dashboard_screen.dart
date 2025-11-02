import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';
import '../widgets/attendance_history_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final attendanceController = Provider.of<AttendanceController>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 32,
              width: 32,
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.business_center_rounded,
                    size: 20,
                    color: Colors.blue,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Indigi Attendance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () {
              _showLogoutDialog(context, authController);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await authController.refreshAttendanceHistory();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card with User Info
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.blue[50],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${authController.currentUser?.name ?? 'Employee'}!',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'EMP Code: ${authController.currentUser?.employeeCode ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Today's Activity Status Card
              FutureBuilder<Map<String, dynamic>>(
                future: attendanceController.getTodayStatus(authController.currentUser!.employeeCode),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Loading today\'s activity...'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasData) {
                    final status = snapshot.data!;
                    final checkinCount = status['checkinCount'] ?? 0;
                    final checkoutCount = status['checkoutCount'] ?? 0;
                    final todayEntries = status['todayEntries'] ?? [];
                    
                    String statusText = 'Check-ins: $checkinCount • Check-outs: $checkoutCount';
                    Color statusColor = Colors.blue;
                    IconData statusIcon = Icons.history;

                    if (checkinCount == 0 && checkoutCount == 0) {
                      statusText = 'No activity today';
                      statusColor = Colors.grey;
                      statusIcon = Icons.info_outline;
                    } else if (checkinCount > checkoutCount) {
                      statusColor = Colors.orange;
                      statusIcon = Icons.access_time;
                    } else if (checkinCount == checkoutCount) {
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today\'s Activity',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                  ),
                                ),
                                if (status['lastCheckin'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Last check-in: ${_formatTime(status['lastCheckin'])}',
                                      style: TextStyle(
                                        color: statusColor.withOpacity(0.8),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                if (status['lastCheckout'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: Text(
                                      'Last check-out: ${_formatTime(status['lastCheckout'])}',
                                      style: TextStyle(
                                        color: statusColor.withOpacity(0.8),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (todayEntries.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${todayEntries.length}',
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox();
                },
              ),

              const SizedBox(height: 8),

              // Current Processing Data
              if (attendanceController.currentProcessingData != null)
                _buildProcessingCard(attendanceController.currentProcessingData!),

              // Error Message Display
              if (attendanceController.errorMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getErrorColor(attendanceController.errorMessage),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getErrorBorderColor(attendanceController.errorMessage),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getErrorIcon(attendanceController.errorMessage),
                        color: _getErrorIconColor(attendanceController.errorMessage),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          attendanceController.errorMessage,
                          style: TextStyle(
                            color: _getErrorTextColor(attendanceController.errorMessage),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          attendanceController.clearError();
                        },
                      ),
                    ],
                  ),
                ),

              // Mark Attendance Section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mark Attendance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Record your check-in and check-out anytime',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.login_rounded,
                            text: 'Check In',
                            color: Colors.green,
                            isLoading: attendanceController.isLoading,
                            onPressed: () async {
                              final success = await attendanceController.checkIn(
                                employeeCode: authController.currentUser!.employeeCode,
                              );

                              if (success && context.mounted) {
                                _showSuccessDialog(context, 'Check-in Successful!');
                                // Refresh attendance history after successful check-in
                                await authController.refreshAttendanceHistory();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.logout_rounded,
                            text: 'Check Out',
                            color: Colors.orange,
                            isLoading: attendanceController.isLoading,
                            onPressed: () async {
                              final success = await attendanceController.checkOut(
                                employeeCode: authController.currentUser!.employeeCode,
                              );

                              if (success && context.mounted) {
                                _showSuccessDialog(context, 'Check-out Successful!');
                                attendanceController.clearCurrentAttendance();
                                // Refresh attendance history after successful check-out
                                await authController.refreshAttendanceHistory();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    
                  ],
                ),
              ),

              // Divider
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: const Divider(thickness: 1),
              ),

              // Attendance History
              AttendanceHistoryWidget(
                attendanceList: authController.attendanceHistory,
                onRefresh: () async {
                  await authController.refreshAttendanceHistory();
                },
                isRefreshing: authController.isRefreshingHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingCard(Map<String, dynamic> processingData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: Colors.blue[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Processing ${processingData['type'] == 'checkin' ? 'Check-in' : 'Check-out'}...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Location: ${processingData['location']}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Coordinates: ${processingData['coordinates']}',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      final hour = date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour < 12 ? 'AM' : 'PM';
      return '${hour == 0 ? 12 : hour}:$minute $period';
    } catch (e) {
      return dateTime;
    }
  }

  // Error display helper methods
  Color _getErrorColor(String errorMessage) {
    if (errorMessage.toLowerCase().contains('successful')) {
      return Colors.green[50]!;
    } else {
      return Colors.red[50]!;
    }
  }

  Color _getErrorBorderColor(String errorMessage) {
    if (errorMessage.toLowerCase().contains('successful')) {
      return Colors.green[100]!;
    } else {
      return Colors.red[100]!;
    }
  }

  Color _getErrorTextColor(String errorMessage) {
    if (errorMessage.toLowerCase().contains('successful')) {
      return Colors.green[800]!;
    } else {
      return Colors.red[800]!;
    }
  }

  Color _getErrorIconColor(String errorMessage) {
    if (errorMessage.toLowerCase().contains('successful')) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  IconData _getErrorIcon(String errorMessage) {
    if (errorMessage.toLowerCase().contains('successful')) {
      return Icons.check_circle;
    } else {
      return Icons.error_outline;
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close dialog first
              Navigator.pop(context);
              // Then logout - this will trigger the main.dart to show login screen
              await authController.logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}