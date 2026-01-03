import 'package:flutter/material.dart';
import '../models/attendance_model.dart';

class AttendanceHistoryWidget extends StatelessWidget {
  final List<Attendance> attendanceList;
  final Future<void> Function()? onRefresh;
  final bool isRefreshing;

  const AttendanceHistoryWidget({
    super.key,
    required this.attendanceList,
    this.onRefresh,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (attendanceList.isEmpty) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No attendance records found',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      content = ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: attendanceList.length,
        itemBuilder: (context, index) {
          final attendance = attendanceList[index];
          return _buildAttendanceCard(attendance, context);
        },
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (isRefreshing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          onRefresh != null
              ? RefreshIndicator(
                  onRefresh: onRefresh!,
                  child: content,
                )
              : content,
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Attendance attendance, BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getFormattedDate(attendance.checkinTime ?? ''),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: attendance.checkoutTime != null ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    attendance.checkoutTime != null ? 'Completed' : 'Checked In',
                    style: TextStyle(
                      color: attendance.checkoutTime != null ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Check-in Section
            _buildTimeSection(
              title: 'CHECK-IN',
              time: attendance.checkinTime,
              location: attendance.checkinLocation,
              icon: Icons.login,
              color: Colors.green,
            ),

            const SizedBox(height: 12),

            // Check-out Section (if available)
            if (attendance.checkoutTime != null)
              _buildTimeSection(
                title: 'CHECK-OUT',
                time: attendance.checkoutTime,
                location: attendance.checkoutLocation,
                icon: Icons.logout,
                color: Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection({
    required String title,
    required String? time,
    required String? location,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatTime(time ?? ''),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (location != null && location.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return 'Today';
      } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
        return 'Yesterday';
      } else {
        final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
      }
    } catch (e) {
      return dateTime;
    }
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
}