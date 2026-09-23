import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/client_visit_controller.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../models/holiday_model.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'leave/leave_approval_list_screen.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final attendanceController = Provider.of<AttendanceController>(context);
    Provider.of<ClientVisitController>(context);
    final user = authController.currentUser;
    final todayHoliday = _getTodayHoliday();
    final upcomingHolidays = _getUpcomingHolidays();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await authController.refreshAttendanceHistory();
          await attendanceController.fetchInitialLocation();
          if (user != null) {
            await attendanceController.fetchTodayStatus(user.employeeCode);
            await authController.fetchPendingLeaves();
          }
        },
        color: AppTheme.accent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Header(user: user, greeting: _getGreeting()),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Today's holiday banner
                  if (todayHoliday != null) ...[
                    _HolidayBanner(holiday: todayHoliday),
                    const SizedBox(height: 20),
                  ],

                  // Manager pending approvals
                  if (user != null && user.canApproveLeave) ...[
                    _PendingApprovalsCard(user: user),
                    const SizedBox(height: 20),
                  ],

                  // Today's attendance status
                  _SectionLabel(title: 'Today\'s Status'),
                  _TodayStatusCard(controller: attendanceController),
                  const SizedBox(height: 28),

                  // Monthly performance chart
                  _SectionLabel(title: 'Monthly Performance'),
                  _ChartCard(history: authController.attendanceHistory),
                  const SizedBox(height: 28),

                  // Upcoming holidays
                  if (upcomingHolidays.isNotEmpty) ...[
                    _SectionLabel(title: 'Upcoming Holidays'),
                    _UpcomingHolidaysCard(holidays: upcomingHolidays),
                    const SizedBox(height: 28),
                  ],

                  // Recent activity
                  _SectionLabel(
                    title: 'Recent Activity',
                    trailing: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ),
                  _RecentActivityCard(context: context, history: authController.attendanceHistory),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Holiday? _getTodayHoliday() {
    final now = DateTime.now();
    try {
      return holidayList2026.firstWhere(
        (h) => h.date.year == now.year && h.date.month == now.month && h.date.day == now.day,
      );
    } catch (e) {
      return null;
    }
  }

  List<Holiday> _getUpcomingHolidays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return holidayList2026
        .where((h) => h.date.isAfter(today) || DateUtils.isSameDay(h.date, today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}

// ─── Header Widget ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final User? user;
  final String greeting;

  const _Header({required this.user, required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 24),
      color: AppTheme.surface,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border, width: 1.5),
            ),
            child: ClipOval(
              child: user?.empAttachmentUrl != null && user!.empAttachmentUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: user!.empAttachmentUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _DefaultAvatar(name: user?.name),
                      placeholder: (context, url) => Container(color: AppTheme.surfaceVariant),
                    )
                  : _DefaultAvatar(name: user?.name),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.name ?? 'Employee',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Employee ID badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: AppTheme.radiusSM,
            ),
            child: Text(
              user?.employeeCode != null ? 'Emp Code: ${user!.employeeCode}' : '',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.accent,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  final String? name;
  const _DefaultAvatar({this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name != null && name!.isNotEmpty
        ? name!.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : 'E';
    return Container(
      color: AppTheme.accentLight,
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.accent,
          ),
        ),
      ),
    );
  }
}

// ─── Section Label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionLabel({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textTertiary,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Holiday Banner ─────────────────────────────────────────────────────────────

class _HolidayBanner extends StatelessWidget {
  final Holiday holiday;
  const _HolidayBanner({required this.holiday});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D5AFE), Color(0xFF1A237E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.radiusLG,
        boxShadow: AppTheme.accentShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: AppTheme.radiusSM,
            ),
            child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Holiday Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  holiday.name,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pending Approvals Card ──────────────────────────────────────────────────────

class _PendingApprovalsCard extends StatelessWidget {
  final User user;
  const _PendingApprovalsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LeaveApprovalListScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warningLight,
          borderRadius: AppTheme.radiusLG,
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                borderRadius: AppTheme.radiusSM,
              ),
              child: Icon(Icons.approval_rounded, color: AppTheme.warning, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Leave Approvals',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'You have requests awaiting your review',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Today Status Card ──────────────────────────────────────────────────────────

class _TodayStatusCard extends StatelessWidget {
  final AttendanceController controller;
  const _TodayStatusCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final status = controller.todayStatus;
    if (status == null) {
      return _card(child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
          ),
        ),
      ));
    }

    final isCheckedIn = status['checkin'] != null;
    final isCheckedOut = status['checkout'] != null;
    final checkinTime = isCheckedIn ? status['checkin'] as String : null;
    final checkoutTime = isCheckedOut ? status['checkout'] as String : null;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (!isCheckedIn) {
      statusColor = AppTheme.error;
      statusLabel = 'Not Punched In';
      statusIcon = Icons.radio_button_unchecked;
    } else if (isCheckedOut) {
      statusColor = AppTheme.textSecondary;
      statusLabel = 'Session Completed';
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = AppTheme.success;
      statusLabel = 'Active';
      statusIcon = Icons.circle;
    }

    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: AppTheme.radiusSM,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCheckedIn
                          ? (isCheckedOut ? 'Work day recorded' : 'Tap Attendance to punch out')
                          : 'Tap Attendance tab to punch in',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isCheckedIn) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.border),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeSlot(
                    label: 'PUNCH IN',
                    time: checkinTime != null ? _formatTime(checkinTime) : '--:--',
                    color: AppTheme.success,
                    icon: Icons.login_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.border,
                ),
                Expanded(
                  child: _TimeSlot(
                    label: 'PUNCH OUT',
                    time: checkoutTime != null ? _formatTime(checkoutTime) : '--:--',
                    color: AppTheme.warning,
                    icon: Icons.logout_rounded,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime).toLocal();
      final hour = date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour < 12 ? 'AM' : 'PM';
      return '${hour == 0 ? 12 : hour}:$minute $period';
    } catch (e) {
      return dateTime;
    }
  }
}

class _TimeSlot extends StatelessWidget {
  final String label;
  final String time;
  final Color color;
  final IconData icon;

  const _TimeSlot({
    required this.label,
    required this.time,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              time,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Chart Card ─────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final List<Attendance> history;
  const _ChartCard({required this.history});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: SizedBox(
        height: 150,
        child: _AttendancePieChart(attendanceHistory: history),
      ),
    );
  }
}

// ─── Upcoming Holidays Card ─────────────────────────────────────────────────────

class _UpcomingHolidaysCard extends StatelessWidget {
  final List<Holiday> holidays;
  const _UpcomingHolidaysCard({required this.holidays});

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  String _getDaysLeft(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    return 'in $difference days';
  }

  @override
  Widget build(BuildContext context) {
    final displayHolidays = holidays.take(2).toList();
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < displayHolidays.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppTheme.border, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight,
                      borderRadius: AppTheme.radiusSM,
                    ),
                    child: Icon(Icons.event_rounded, color: AppTheme.error, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayHolidays[i].name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(displayHolidays[i].date),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: AppTheme.radiusXS,
                    ),
                    child: Text(
                      _getDaysLeft(displayHolidays[i].date),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Recent Activity Card ────────────────────────────────────────────────────────

class _RecentActivityCard extends StatelessWidget {
  final BuildContext context;
  final List<Attendance> history;

  const _RecentActivityCard({required this.context, required this.history});

  static String _formatTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime).toLocal();
      final hour = date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour < 12 ? 'AM' : 'PM';
      return '${hour == 0 ? 12 : hour}:$minute $period';
    } catch (e) {
      return dateTime;
    }
  }

  static String _formatLogDate(String? checkinTime) {
    if (checkinTime == null) return '';
    try {
      final date = DateTime.parse(checkinTime).toLocal();
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) return 'Today';
      final yesterday = now.subtract(const Duration(days: 1));
      if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
        return 'Yesterday';
      }
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return checkinTime;
    }
  }

  @override
  Widget build(BuildContext ctx) {
    if (history.isEmpty) {
      return _card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history_rounded, size: 36, color: AppTheme.border),
                const SizedBox(height: 8),
                const Text(
                  'No recent attendance logs',
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final recentLogs = history.take(3).toList();

    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int index = 0; index < recentLogs.length; index++) ...[
            if (index > 0) const Divider(height: 1, color: AppTheme.border, indent: 20, endIndent: 20),
            Builder(builder: (context) {
              final log = recentLogs[index];
              final dateStr = _formatLogDate(log.checkinTime);
              final inTime = log.checkinTime != null ? _formatTime(log.checkinTime!) : '--:--';
              final outTime = log.checkoutTime != null ? _formatTime(log.checkoutTime!) : '--:--';
              final isCompleted = log.checkoutTime != null;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: AppTheme.radiusSM,
                      ),
                      child: const Icon(Icons.fingerprint_rounded, color: AppTheme.accent, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _PunchTimeChip(time: inTime, isIn: true),
                              const SizedBox(width: 8),
                              _PunchTimeChip(time: outTime, isIn: false),
                            ],
                          ),
                          if (log.checkinLocation != null && log.checkinLocation!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 11, color: AppTheme.textTertiary),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    log.checkinLocation!,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? AppTheme.successLight : AppTheme.warningLight,
                        borderRadius: AppTheme.radiusXS,
                      ),
                      child: Text(
                        isCompleted ? 'Done' : 'Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCompleted ? AppTheme.success : AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _PunchTimeChip extends StatelessWidget {
  final String time;
  final bool isIn;

  const _PunchTimeChip({required this.time, required this.isIn});

  @override
  Widget build(BuildContext context) {
    final color = isIn ? AppTheme.success : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppTheme.radiusXS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isIn ? Icons.login_rounded : Icons.logout_rounded, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Card Container ───────────────────────────────────────────────────────

Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
  return Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: AppTheme.radiusXL,
      boxShadow: AppTheme.cardShadow,
    ),
    child: child,
  );
}

// ─── Pie Chart ───────────────────────────────────────────────────────────────────

class _AttendancePieChart extends StatefulWidget {
  final List<Attendance> attendanceHistory;

  const _AttendancePieChart({required this.attendanceHistory});

  @override
  State<_AttendancePieChart> createState() => _AttendancePieChartState();
}

class _AttendancePieChartState extends State<_AttendancePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final data = _calculateChartData();
    if (data['total'] == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 36, color: AppTheme.border),
            const SizedBox(height: 8),
            const Text(
              'No data for this month',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    String topText;
    String midText;
    String bottomText;
    Color topColor;

    if (touchedIndex == -1) {
      topText = '${data['total']}';
      midText = 'Working\nDays';
      bottomText = _getCurrentMonthName();
      topColor = AppTheme.textPrimary;
    } else {
      final total = data['total'] ?? 1;
      double value = 0;
      String label = '';
      Color color = AppTheme.textPrimary;

      switch (touchedIndex) {
        case 0:
          value = data['completed']!.toDouble();
          label = 'Completed';
          color = AppTheme.success;
          break;
        case 1:
          value = data['pending']!.toDouble();
          label = 'Active';
          color = AppTheme.warning;
          break;
        case 2:
          value = data['remaining']!.toDouble();
          label = 'Remaining';
          color = AppTheme.textTertiary;
          break;
      }

      final percent = ((value / total) * 100).toStringAsFixed(1);
      topText = '$percent%';
      midText = label;
      bottomText = '${value.toInt()} Days';
      topColor = color;
    }

    return Row(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 44,
                  sections: [
                    PieChartSectionData(
                      color: AppTheme.success,
                      value: data['completed']!.toDouble(),
                      title: '',
                      radius: touchedIndex == 0 ? 46.0 : 38.0,
                    ),
                    PieChartSectionData(
                      color: AppTheme.warning,
                      value: data['pending']!.toDouble(),
                      title: '',
                      radius: touchedIndex == 1 ? 46.0 : 38.0,
                    ),
                    PieChartSectionData(
                      color: AppTheme.border,
                      value: data['remaining']!.toDouble(),
                      title: '',
                      radius: touchedIndex == 2 ? 46.0 : 38.0,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    topText,
                    style: TextStyle(
                      fontSize: touchedIndex == -1 ? 22 : 18,
                      fontWeight: FontWeight.w800,
                      color: touchedIndex == -1 ? AppTheme.textPrimary : topColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    midText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, color: AppTheme.textTertiary, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                  ),
                  if (touchedIndex != -1) ...[
                    const SizedBox(height: 2),
                    Text(
                      bottomText,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Indicator(color: AppTheme.success, label: 'Completed', value: '${data['completed']}'),
            const SizedBox(height: 12),
            _Indicator(color: AppTheme.warning, label: 'Active', value: '${data['pending']}'),
            const SizedBox(height: 12),
            _Indicator(color: AppTheme.border, label: 'Remaining', value: '${data['remaining']}'),
          ],
        ),
      ],
    );
  }

  String _getCurrentMonthName() {
    final now = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return months[now.month - 1];
  }

  Map<String, int> _calculateChartData() {
    final now = DateTime.now();
    final currentMonth = widget.attendanceHistory.where((a) {
      try {
        final d = DateTime.parse(a.checkinTime!);
        return d.month == now.month && d.year == now.year;
      } catch (e) {
        return false;
      }
    }).toList();

    Map<String, List<Attendance>> sessionsByDay = {};
    for (var attendance in currentMonth) {
      try {
        final d = DateTime.parse(attendance.checkinTime!);
        final dateKey = '${d.year}-${d.month}-${d.day}';
        sessionsByDay.putIfAbsent(dateKey, () => []).add(attendance);
      } catch (e) {
        continue;
      }
    }

    int completed = 0;
    int pending = 0;

    sessionsByDay.forEach((key, sessions) {
      final hasActive = sessions.any((s) => s.checkoutTime == null);
      if (hasActive) {
        pending++;
      } else {
        completed++;
      }
    });

    int attendedCount = completed + pending;
    int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    int totalWorkingDays = 0;

    for (int i = 1; i <= daysInMonth; i++) {
      final day = DateTime(now.year, now.month, i);
      if (day.weekday == DateTime.sunday) continue;
      bool isHoliday = holidayList2026.any((h) =>
          h.date.year == day.year && h.date.month == day.month && h.date.day == day.day);
      if (isHoliday) continue;
      totalWorkingDays++;
    }

    int remaining = (totalWorkingDays - attendedCount).clamp(0, 31);
    return {
      'completed': completed,
      'pending': pending,
      'remaining': remaining,
      'total': totalWorkingDays,
    };
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _Indicator({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}
