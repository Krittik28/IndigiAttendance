import 'dart:async' as async_timer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../widgets/checkin_map_dialog.dart';
import '../../widgets/client_selection_dialog.dart';
import '../../models/client_model.dart';
import '../../models/client_visit_model.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../models/holiday_model.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/client_visit_controller.dart';
import '../../controllers/holiday_controller.dart';
import '../history_screen.dart';
import '../holiday_screen.dart';
import '../client_visit_history_screen.dart';
import '../leave/leave_approval_list_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _headerAnimController;
  late final AnimationController _cardsAnimController;

  @override
  void initState() {
    super.initState();

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _cardsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final att = Provider.of<AttendanceController>(context, listen: false);
      att.fetchInitialLocation();
      Provider.of<HolidayController>(context, listen: false).fetchHolidays();
      if (auth.currentUser != null) {
        att.fetchTodayStatus(auth.currentUser!.employeeCode);
        auth.fetchPendingLeaves();
        Provider.of<ClientVisitController>(context, listen: false)
            .fetchHistory(auth.currentUser!.employeeCode);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnimController.dispose();
    _cardsAnimController.dispose();
    super.dispose();
  }

  // ─── Pull to Refresh ────────────────────────────────────────────────────────
  Future<void> _onRefresh() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final att = Provider.of<AttendanceController>(context, listen: false);
    final holiday = Provider.of<HolidayController>(context, listen: false);
    final client = Provider.of<ClientVisitController>(context, listen: false);
    await Future.wait([
      auth.refreshAttendanceHistory(),
      att.fetchInitialLocation(),
      holiday.fetchHolidays(refresh: true),
      if (auth.currentUser != null) ...[
        att.fetchTodayStatus(auth.currentUser!.employeeCode),
        auth.fetchPendingLeaves(),
        client.fetchHistory(auth.currentUser!.employeeCode),
      ]
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final att = Provider.of<AttendanceController>(context);
    final clientVisit = Provider.of<ClientVisitController>(context);
    final holiday = Provider.of<HolidayController>(context);
    final user = auth.currentUser;
    final todayHoliday = holiday.getTodayHoliday();
    final upcomingHolidays = holiday.getUpcomingHolidays();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.emerald,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Hero Header ────────────────────────────────────────────────
            _buildSliverHeader(context, auth, att, user),

            // ── Body Content ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Holiday banner
                    if (todayHoliday != null) ...[
                      const SizedBox(height: 20),
                      _buildHolidayBanner(todayHoliday),
                    ],

                    // Upcoming Holidays
                    if (upcomingHolidays.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildUpcomingHolidaysCard(upcomingHolidays),
                    ],

                    // Pending Approvals (for managers)
                    if (user != null && user.canApproveLeave) ...[
                      const SizedBox(height: 16),
                      _buildPendingApprovalsCard(user),
                    ],

                    // Today's Status
                    const SizedBox(height: 24),
                    _buildSectionTitle('Today\'s Status'),
                    const SizedBox(height: 12),
                    att.todayStatus != null
                        ? _buildTodayStatusCard(att.todayStatus!)
                        : _buildLoadingCard(),

                    // Processing / Error indicator
                    if (att.currentProcessingData != null) ...[
                      const SizedBox(height: 12),
                      _buildProcessingBanner(att.currentProcessingData!),
                    ],
                    if (att.errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildErrorBanner(att),
                    ],

                    // Check In/Out action buttons
                    const SizedBox(height: 20),
                    _buildCheckInOutRow(context, att, auth, user),

                    // Client Visit Section
                    const SizedBox(height: 24),
                    _buildClientVisitSection(context, clientVisit, user),

                    // Monthly Overview Chart
                    const SizedBox(height: 28),
                    _buildChartCard(auth.attendanceHistory, auth.lwpCount),

                    // Recent Activity
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      title: 'Recent Activity',
                      action: 'View All',
                      onAction: () =>
                          Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                            builder: (_) => const HistoryScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentActivity(context, auth.attendanceHistory),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildSliverHeader(
    BuildContext context,
    AuthController auth,
    AttendanceController att,
    User? user,
  ) {
    return SliverToBoxAdapter(
      child: _buildHeroBackground(context, auth, att, user),
    );
  }

  Widget _buildHeroBackground(
    BuildContext context,
    AuthController auth,
    AttendanceController att,
    User? user,
  ) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Top Row: Date + Avatar
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_dayName(now.weekday).toUpperCase()}, ${now.day} ${_monthAbbr(now.month).toUpperCase()}',
                          style: AppText.sectionHeader,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$greeting, ${user?.name.split(' ').first ?? 'there'}',
                          style: AppText.displayMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Apple-style circular avatar
                  GestureDetector(
                    onTap: () => _updateProfileImage(auth),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(
                          color: const Color(0xFFE5E5EA),
                          width: 1,
                        ),
                        boxShadow: AppShadows.card,
                      ),
                      child: ClipOval(
                        child: () {
                          final picUrl = user?.empAttachmentUrl;
                          final hasPic = picUrl != null && picUrl.isNotEmpty && picUrl != 'NA';
                          if (hasPic) {
                            return CachedNetworkImage(
                              imageUrl: picUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _defaultAvatar(user?.name ?? ''),
                              placeholder: (_, __) =>
                                  const CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          return _defaultAvatar(user?.name ?? '');
                        }(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Location chip in clean white container
              _buildLocationChip(context, att),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(String name) {
    final initials = name.isNotEmpty
        ? name
            .trim()
            .split(' ')
            .where((s) => s.isNotEmpty)
            .take(2)
            .map((s) => s[0].toUpperCase())
            .join()
        : '?';
    return Container(
      color: AppColors.surfaceSecondary,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationChip(
      BuildContext context, AttendanceController att) {
    return GestureDetector(
      onTap: () => _showLocationDialog(context, att),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: const Color(0xFFE5E5EA),
            width: 0.8,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.emerald,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            att.cachedLocation != null
                ? Flexible(
                    child: Builder(
                      builder: (_) {
                        final locMap = att.cachedLocation;
                        final locStr = locMap?['location'] ?? 'Unknown';
                        final shortLoc = locMap?['shortLocation'];
                        final display = shortLoc ??
                            (locStr.length > 28
                                ? '${locStr.substring(0, 28)}…'
                                : locStr);
                        return Text(
                          display,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.emerald,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Fetching location…',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Title ────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String action,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Row(
            children: [
              Text(
                action,
                style: const TextStyle(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 11, color: AppColors.emerald),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Holiday Banner ────────────────────────────────────────────────────────
  Widget _buildHolidayBanner(Holiday holiday) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9B8EC4), Color(0xFF7B6DAA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B8EC4).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Text('🎉', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Holiday Today!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
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

  // ─── Upcoming Holidays ────────────────────────────────────────────────────
  Widget _buildUpcomingHolidaysCard(List<Holiday> holidays) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const HolidayScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
          border: Border.all(
            color: AppColors.tealAccent.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.tealAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.event_rounded,
                      color: AppColors.tealAccent, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Upcoming Holidays',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.tealAccent,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.tealAccent),
              ],
            ),
            const SizedBox(height: 14),
            ...holidays.take(3).map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_monthAbbr(h.date.month)} ${h.date.day}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          h.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _dayName(h.date.weekday).substring(0, 3),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ─── Pending Approvals ────────────────────────────────────────────────────
  Widget _buildPendingApprovalsCard(User user) {
    if (user.pendingLeaveCount == 0 && user.pendingLeaveByEmployee.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const LeaveApprovalListScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
          border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.pending_actions_rounded,
                  color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leave Approvals',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${user.pendingLeaveCount} pending request${user.pendingLeaveCount != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '${user.pendingLeaveCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Today's Status ───────────────────────────────────────────────────────
  Widget _buildTodayStatusCard(Map<String, dynamic> status) {
    final checkinCount = status['checkinCount'] ?? 0;
    final checkoutCount = status['checkoutCount'] ?? 0;

    bool isActive = checkinCount > checkoutCount;
    bool isDone = checkinCount > 0 && checkinCount == checkoutCount;

    Color accentColor = isActive
        ? AppColors.amber
        : (isDone ? AppColors.emerald : AppColors.textHint);
    IconData icon = isActive
        ? Icons.timer_outlined
        : (isDone ? Icons.check_circle_outline_rounded : Icons.schedule_rounded);
    String title = isActive
        ? 'Shift in Progress'
        : (isDone ? 'Shift Completed' : 'Not Clocked In');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : (isDone ? 'COMPLETED' : 'OFF DUTY'),
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Check-ins: $checkinCount  •  Check-outs: $checkoutCount',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (status['lastCheckin'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last activity: ${_formatTime(status['lastCheckin'])}',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
        boxShadow: AppShadows.card,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.emerald,
          strokeWidth: 2,
        ),
      ),
    );
  }

  // ─── Check In/Out Row ─────────────────────────────────────────────────────
  Widget _buildCheckInOutRow(
    BuildContext context,
    AttendanceController att,
    AuthController auth,
    User? user,
  ) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Check In',
            icon: Icons.login_rounded,
            isPrimary: true,
            isLoading: att.isLoading,
            onPressed: () =>
                _showCheckInOptionsDialog(context, att, user, auth),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Check Out',
            icon: Icons.logout_rounded,
            isPrimary: false,
            isLoading: att.isLoading,
            onPressed: () => _showConfirmationDialog(
              context: context,
              title: 'Confirm Check-out',
              content: 'Are you sure you want to check out now?',
              icon: Icons.logout_rounded,
              iconColor: AppColors.amber,
              controller: att,
              onConfirm: () async {
                if (user == null) return;
                final msg = await att.checkOut(employeeCode: user.employeeCode);
                if (msg != null && context.mounted) {
                  _showSuccessDialog(
                      context, msg.isNotEmpty ? msg : 'Check-out Successful!');
                  att.clearCurrentAttendance();
                  await auth.refreshAttendanceHistory();
                  await att.fetchTodayStatus(user.employeeCode);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── Chart ────────────────────────────────────────────────────────────────
  Widget _buildChartCard(List<Attendance> history, int lwpCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 190,
            child: _AttendancePieChart(
              attendanceHistory: history,
              lwpCount: lwpCount,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Processing / Error banners ─────────────────────────────────────────
  Widget _buildProcessingBanner(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.charcoal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.charcoal.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.coral,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Processing ${data['type']}…',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(AttendanceController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              controller.errorMessage,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: controller.clearError,
            child: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  // ─── Recent Activity ──────────────────────────────────────────────────────
  Widget _buildRecentActivity(
      BuildContext context, List<Attendance> history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded,
                size: 48, color: AppColors.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'No recent activity',
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return Column(
      children: history.take(3).map((a) {
        return GestureDetector(
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => HistoryScreen(
                initialFocusDate: DateTime.tryParse(a.checkinTime ?? ''),
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 0.8),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                // Date block
                Container(
                  width: 50,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayNumber(a.checkinTime ?? ''),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1,
                        ),
                      ),
                      Text(
                        _monthAbbr(DateTime.tryParse(a.checkinTime ?? '')?.month ?? 1),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dayName(
                            DateTime.tryParse(a.checkinTime ?? '')?.weekday ??
                                1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _TimeChip(
                            icon: Icons.login_rounded,
                            time: _formatTime(a.checkinTime ?? ''),
                            color: AppColors.success,
                          ),
                          if (a.checkoutTime != null) ...[
                            const SizedBox(width: 8),
                            _TimeChip(
                              icon: Icons.logout_rounded,
                              time: _formatTime(a.checkoutTime!),
                              color: AppColors.warning,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (a.checkoutTime != null
                            ? AppColors.success
                            : AppColors.warning)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    a.checkoutTime != null ? 'Done' : 'Active',
                    style: TextStyle(
                      color: a.checkoutTime != null
                          ? AppColors.success
                          : AppColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Utilities ─────────────────────────────────────────────────────────────
  String _formatTime(String dt) {
    try {
      final d = DateTime.parse(dt).toLocal();
      final h = d.hour % 12;
      final m = d.minute.toString().padLeft(2, '0');
      final p = d.hour < 12 ? 'AM' : 'PM';
      return '${h == 0 ? 12 : h}:$m $p';
    } catch (_) {
      return dt;
    }
  }

  String _getDayNumber(String dt) {
    try {
      return DateTime.parse(dt).day.toString().padLeft(2, '0');
    } catch (_) {
      return '--';
    }
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  String _dayName(int weekday) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[(weekday - 1).clamp(0, 6)];
  }

  // ─── Dialogs (reused from old DashboardScreen) ────────────────────────────
  Future<void> _updateProfileImage(AuthController auth) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const Text(
              'Update Profile Photo',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.coral),
              ),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.tealAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: AppColors.tealAccent),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source != null) {
      final image =
          await picker.pickImage(source: source, imageQuality: 50);
      if (image != null && mounted) {
        final ok = await auth.updateProfileImage(image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok
                ? 'Profile photo updated!'
                : auth.errorMessage.isNotEmpty
                    ? auth.errorMessage
                    : 'Failed to update photo'),
            backgroundColor:
                ok ? AppColors.success : AppColors.error,
          ));
        }
      }
    }
  }

  void _showCheckInOptionsDialog(
    BuildContext context,
    AttendanceController att,
    User? user,
    AuthController auth,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const Text(
                'Select Check-in Location',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _LocationOptionTile(
                icon: Icons.business_rounded,
                iconColor: AppColors.charcoal,
                iconBg: AppColors.charcoal.withValues(alpha: 0.1),
                title: 'Indigi Office',
                subtitle: 'Geo-fencing enabled check-in',
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  _handleIndigiOfficeCheckIn(context, att, user, auth);
                },
              ),
              const SizedBox(height: 12),
              _LocationOptionTile(
                icon: Icons.person_pin_circle_rounded,
                iconColor: AppColors.coral,
                iconBg: AppColors.coral.withValues(alpha: 0.1),
                title: 'Client Site',
                subtitle: 'Check in from client location',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _handleClientSiteCheckIn(context, att, user, auth);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleIndigiOfficeCheckIn(
    BuildContext context,
    AttendanceController att,
    User? user,
    AuthController auth,
  ) async {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.coral),
      ),
    );

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied.');
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 6),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
        position ??= await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
      }

      const officeLat = 26.132888;
      const officeLong = 91.829733;

      final distance = Geolocator.distanceBetween(
        officeLat,
        officeLong,
        position.latitude,
        position.longitude,
      );

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        showDialog(
          context: context,
          useRootNavigator: true,
          builder: (ctx) => CheckInMapDialog(
            userLocation: LatLng(position!.latitude, position.longitude),
            officeLocation: const LatLng(officeLat, officeLong),
            distance: distance,
            isWithinRange: distance <= 20,
            onConfirm: () async {
              Navigator.of(ctx, rootNavigator: true).pop();
              if (user == null) return;
              final msg = await att.checkIn(employeeCode: user.employeeCode);
              if (msg != null && context.mounted) {
                _showSuccessDialog(context,
                    msg.isNotEmpty ? msg : 'Check-in Successful!');
                await auth.refreshAttendanceHistory();
                await att.fetchTodayStatus(user.employeeCode);
              }
            },
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  void _handleClientSiteCheckIn(
    BuildContext context,
    AttendanceController att,
    User? user,
    AuthController auth,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ClientSelectionDialog(
        onClientSelected: (Client client) {
          _showConfirmationDialog(
            context: context,
            title: 'Confirm Check-in',
            content: 'Check in from client site: ${client.customerName}?',
            icon: Icons.person_pin_circle_rounded,
            iconColor: AppColors.success,
            controller: att,
            onConfirm: () async {
              if (user == null) return;
              final msg = await att.checkInWithClient(
                employeeCode: user.employeeCode,
                clientId: client.id,
              );
              if (msg != null && context.mounted) {
                _showSuccessDialog(
                    context, msg.isNotEmpty ? msg : 'Check-in Successful!');
                await auth.refreshAttendanceHistory();
                await att.fetchTodayStatus(user.employeeCode);
              }
            },
          );
        },
      ),
    );
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onConfirm,
    required AttendanceController controller,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => FutureBuilder<Map<String, String>?>(
          future: controller.fetchLocationSilent(),
          builder: (ctx, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final loc = snapshot.data?['location'] ??
                controller.cachedLocation?['location'] ??
                'Unknown Location';
            final isValid = loc != 'Unknown Location';

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(content,
                      style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isValid
                          ? AppColors.surfaceSecondary
                          : AppColors.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isValid
                            ? const Color(0xFFEEEFF4)
                            : AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isLoading) ...[
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textHint),
                          ),
                          const SizedBox(width: 10),
                          const Text('Fetching location…',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint)),
                        ] else ...[
                          Icon(
                            isValid
                                ? Icons.location_on_rounded
                                : Icons.location_off_rounded,
                            size: 16,
                            color: isValid
                                ? AppColors.textSecondary
                                : AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc,
                              style: TextStyle(
                                fontSize: 12,
                                color: isValid
                                    ? AppColors.textPrimary
                                    : AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isValid)
                            GestureDetector(
                              onTap: () => setState(() {}),
                              child: const Icon(Icons.refresh_rounded,
                                  size: 16, color: AppColors.coral),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.textHint)),
                ),
                ElevatedButton(
                  onPressed: (isLoading || !isValid)
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          onConfirm();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Confirm',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppGradients.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              const Text('Success!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: const Text('Great!',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationDialog(BuildContext context, AttendanceController att) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: AppColors.coral, size: 28),
            ),
            const SizedBox(height: 12),
            const Text('Current Location',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              att.cachedLocation?['location'] ?? 'Unknown Location',
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Coordinates: ${att.cachedLocation?['latitude'] ?? '–'}, ${att.cachedLocation?['longitude'] ?? '–'}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close',
                style: TextStyle(color: AppColors.textHint)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await att.fetchInitialLocation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  // ─── Client Visit Section ──────────────────────────────────────────────────
  Widget _buildClientVisitSection(
    BuildContext context,
    ClientVisitController controller,
    User? user,
  ) {
    final ongoing = controller.ongoingVisit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Client Visit'),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => const ClientVisitHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history_rounded, size: 16, color: AppColors.coral),
              label: const Text(
                'History',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (ongoing == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.coral.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.business_center_rounded,
                        color: AppColors.coral,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need to visit a client site?',
                            style: AppText.headingMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track your client check-in/out and GPS locations.',
                            style: AppText.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () {
                    _startClientVisitFlow(context, controller, user);
                  },
                  icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                  label: const Text(
                    'Start Client Visit',
                    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.charcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          )
        else
          _buildOngoingVisitCard(context, controller, ongoing, user),
      ],
    );
  }

  Widget _buildOngoingVisitCard(
    BuildContext context,
    ClientVisitController controller,
    ClientVisit ongoing,
    User? user,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.coral.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ONGOING CLIENT VISIT',
                    style: TextStyle(
                      color: AppColors.coral,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              _OngoingVisitTimer(checkinTime: ongoing.checkinTime),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            ongoing.clientName,
            style: AppText.headingMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.login_rounded, size: 15, color: AppColors.emerald),
              const SizedBox(width: 6),
              Text(
                'Checked in at ${_formatVisitTime(ongoing.checkinTime)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 15, color: AppColors.textHint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ongoing.checkinLocation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              _showClientVisitCheckoutDialog(context, controller, user);
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text(
              'Check Out of Site',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _startClientVisitFlow(
    BuildContext context,
    ClientVisitController controller,
    User? user,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ClientSelectionDialog(
        onClientSelected: (Client client) {
          _showClientVisitConfirmationDialog(context, controller, client, user);
        },
      ),
    );
  }

  void _showClientVisitConfirmationDialog(
    BuildContext context,
    ClientVisitController controller,
    Client client,
    User? user,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogStatefulContext, setState) {
            return FutureBuilder<Map<String, String>?>(
              future: controller.fetchLocationSilent(),
              builder: (context, snapshot) {
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                final locationData = snapshot.data;
                final location = locationData?['location'] ??
                    controller.cachedLocation?['location'] ??
                    'Unknown Location';
                final isLocationValid = location != 'Unknown Location';

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  title: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_location_alt_rounded,
                          color: AppColors.coral,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Client Visit Check-in',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Do you want to check in for a visit to ${client.customerName}?',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isLocationValid
                              ? AppColors.surfaceSecondary
                              : AppColors.error.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isLocationValid
                                ? AppColors.cardBorder
                                : AppColors.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isLoading) ...[
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textHint,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Fetching location...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ] else ...[
                              Icon(
                                isLocationValid
                                    ? Icons.location_on
                                    : Icons.location_off,
                                size: 16,
                                color: isLocationValid
                                    ? AppColors.coral
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isLocationValid
                                        ? AppColors.textPrimary
                                        : AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isLocationValid)
                                InkWell(
                                  onTap: () {
                                    setState(() {});
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.refresh,
                                      size: 16,
                                      color: AppColors.coral,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textHint),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: (isLoading || !isLocationValid)
                          ? null
                          : () async {
                              Navigator.of(context, rootNavigator: true).pop(); // Pop confirmation dialog

                              showDialog(
                                context: context,
                                useRootNavigator: true,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.coral,
                                  ),
                                ),
                              );

                              try {
                                final success = await controller.checkIn(
                                  employeeCode: user!.employeeCode,
                                  client: client,
                                );

                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop(); // Pop loading dialog
                                }

                                if (success && context.mounted) {
                                  _showSuccessDialog(
                                    context,
                                    'Checked in successfully for visit to ${client.customerName}',
                                  );
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(controller.errorMessage),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.surfaceSecondary,
                        disabledForegroundColor: AppColors.textHint,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showClientVisitCheckoutDialog(
    BuildContext context,
    ClientVisitController controller,
    User? user,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogStatefulContext, setState) {
            return FutureBuilder<Map<String, String>?>(
              future: controller.fetchLocationSilent(),
              builder: (context, snapshot) {
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                final locationData = snapshot.data;
                final location = locationData?['location'] ??
                    controller.cachedLocation?['location'] ??
                    'Unknown Location';
                final isLocationValid = location != 'Unknown Location';

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  title: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.coral,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Confirm Checkout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Are you sure you want to end this client visit now?',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isLocationValid
                              ? AppColors.surfaceSecondary
                              : AppColors.error.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isLocationValid
                                ? AppColors.cardBorder
                                : AppColors.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isLoading) ...[
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textHint,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Fetching location...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ] else ...[
                              Icon(
                                isLocationValid
                                    ? Icons.location_on
                                    : Icons.location_off,
                                size: 16,
                                color: isLocationValid
                                    ? AppColors.coral
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isLocationValid
                                        ? AppColors.textPrimary
                                        : AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isLocationValid)
                                InkWell(
                                  onTap: () {
                                    setState(() {});
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.refresh,
                                      size: 16,
                                      color: AppColors.coral,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textHint),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: (isLoading || !isLocationValid)
                          ? null
                          : () async {
                              Navigator.of(context, rootNavigator: true).pop(); // Pop confirmation dialog

                              showDialog(
                                context: context,
                                useRootNavigator: true,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.coral,
                                  ),
                                ),
                              );

                              try {
                                final success = await controller.checkOut(
                                  employeeCode: user!.employeeCode,
                                );

                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop(); // Pop loading dialog
                                }

                                if (success && context.mounted) {
                                  _showSuccessDialog(
                                    context,
                                    'Checked out of client site successfully',
                                  );
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(controller.errorMessage),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.surfaceSecondary,
                        disabledForegroundColor: AppColors.textHint,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('Checkout'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatVisitTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$h:$minute $period';
    } catch (_) {
      return isoString;
    }
  }
}

// ─── Action Button ─────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    this.isPrimary = true,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.emerald : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.cardBorder, width: 1.0),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppShadows.card,
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isPrimary ? Colors.white : AppColors.emerald,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isPrimary ? Colors.white : AppColors.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isPrimary ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Location Option Tile ─────────────────────────────────────────────────
class _LocationOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LocationOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: const Color(0xFFEEEFF4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Time Chip ────────────────────────────────────────────────────────────
class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String time;
  final Color color;

  const _TimeChip(
      {required this.icon, required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Attendance Pie Chart (carried from old dashboard) ────────────────────
class _AttendancePieChart extends StatefulWidget {
  final List<Attendance> attendanceHistory;
  final int lwpCount;

  const _AttendancePieChart({
    required this.attendanceHistory,
    this.lwpCount = 0,
  });

  @override
  State<_AttendancePieChart> createState() => _AttendancePieChartState();
}

class _AttendancePieChartState extends State<_AttendancePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final holidayController =
        Provider.of<HolidayController>(context, listen: false);
    final holidays = holidayController.holidays;
    final data = _calculateChartData(holidays);

    // Check if empty
    if (data['total'] == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              "No data",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    String centerTextTop;
    String centerTextMiddle;
    String centerTextBottom;
    Color centerTextColor;

    if (touchedIndex == -1) {
      centerTextTop = '${data['total']}';
      centerTextMiddle = 'Working\nDays';
      centerTextBottom = _getCurrentMonthName();
      centerTextColor = Colors.indigo.withValues(alpha: 0.7);
    } else {
      final total = data['total'] ?? 1;
      double value = 0;
      String label = '';
      Color color = Colors.black;

      switch (touchedIndex) {
        case 0:
          value = data['completed']!.toDouble();
          label = 'Completed';
          color = const Color(0xFF4CAF50);
          break;
        case 1:
          value = data['pending']!.toDouble();
          label = 'Pending';
          color = const Color(0xFFFF9800);
          break;
        case 2:
          value = (data['lwp'] ?? 0).toDouble();
          label = 'LWP';
          color = const Color(0xFFE53935);
          break;
        case 3:
          value = data['remaining']!.toDouble();
          label = 'Remaining';
          color = Colors.grey;
          break;
      }

      final percent = ((value / total) * 100).toStringAsFixed(1);
      centerTextTop = '$percent%';
      centerTextMiddle = label;
      centerTextBottom = '${value.toInt()} Days';
      centerTextColor = color;
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
                        touchedIndex =
                            pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: showingSections(data),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerTextTop,
                    style: TextStyle(
                      fontSize: touchedIndex == -1 ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: touchedIndex == -1
                          ? Colors.black87
                          : centerTextColor,
                    ),
                  ),
                  Text(
                    centerTextMiddle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    centerTextBottom,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: touchedIndex == -1
                          ? centerTextColor
                          : Colors.grey[800],
                    ),
                  ),
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
            _buildIndicator(
              color: const Color(0xFF4CAF50),
              text: 'Completed',
              value: '${data['completed']}',
            ),
            const SizedBox(height: 8),
            _buildIndicator(
              color: const Color(0xFFFF9800),
              text: 'Pending',
              value: '${data['pending']}',
            ),
            const SizedBox(height: 8),
            _buildIndicator(
              color: const Color(0xFFE53935),
              text: 'LWP',
              value: '${data['lwp'] ?? 0}',
            ),
            const SizedBox(height: 8),
            _buildIndicator(
              color: Colors.grey[300]!,
              text: 'Remaining',
              value: '${data['remaining']}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicator(
      {required Color color, required String text, required String value}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getCurrentMonthName() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[now.month - 1];
  }

  Map<String, int> _calculateChartData(List<Holiday> holidays) {
    final now = DateTime.now();
    final currentMonth = widget.attendanceHistory.where((a) {
      try {
        final d = DateTime.parse(a.checkinTime!);
        return d.month == now.month && d.year == now.year;
      } catch (e) {
        return false;
      }
    }).toList();

    int completed = currentMonth.where((a) => a.checkoutTime != null).length;
    int pending = currentMonth.where((a) => a.checkoutTime == null).length;
    int attendedCount = completed + pending;
    int lwp = widget.lwpCount;

    // Calculate total working days in month (excluding Sundays and Holidays)
    int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    int totalWorkingDays = 0;

    for (int i = 1; i <= daysInMonth; i++) {
      final day = DateTime(now.year, now.month, i);

      // Check if it's Sunday
      if (day.weekday == DateTime.sunday) {
        continue;
      }

      // Check if it's a Holiday
      bool isHoliday = holidays.any((h) =>
          h.date.year == day.year &&
          h.date.month == day.month &&
          h.date.day == day.day);

      if (isHoliday) {
        continue;
      }

      totalWorkingDays++;
    }

    int remaining = (totalWorkingDays - attendedCount - lwp).clamp(0, 31);

    return {
      'completed': completed,
      'pending': pending,
      'lwp': lwp,
      'remaining': remaining,
      'total': totalWorkingDays,
    };
  }

  List<PieChartSectionData> showingSections(Map<String, int> data) {
    return List.generate(4, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 55.0 : 45.0;

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: const Color(0xFF4CAF50),
            value: data['completed']!.toDouble(),
            title: '',
            radius: radius,
          );
        case 1:
          return PieChartSectionData(
            color: const Color(0xFFFF9800),
            value: data['pending']!.toDouble(),
            title: '',
            radius: radius,
          );
        case 2:
          return PieChartSectionData(
            color: const Color(0xFFE53935),
            value: (data['lwp'] ?? 0).toDouble(),
            title: '',
            radius: radius,
          );
        case 3:
          return PieChartSectionData(
            color: Colors.grey[200],
            value: data['remaining']!.toDouble(),
            title: '',
            radius: radius,
          );
        default:
          throw Error();
      }
    });
  }
}

class _OngoingVisitTimer extends StatefulWidget {
  final String checkinTime;
  const _OngoingVisitTimer({required this.checkinTime});

  @override
  State<_OngoingVisitTimer> createState() => _OngoingVisitTimerState();
}

class _OngoingVisitTimerState extends State<_OngoingVisitTimer> {
  async_timer.Timer? _timer;
  String _durationStr = '0m';

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = async_timer.Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateDuration();
    });
  }

  void _updateDuration() {
    try {
      final checkin = DateTime.parse(widget.checkinTime).toLocal();
      final diff = DateTime.now().difference(checkin);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (mounted) {
        setState(() {
          if (hours > 0) {
            _durationStr = '${hours}h ${minutes}m';
          } else {
            _durationStr = '${minutes}m';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _durationStr = '0m';
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 12, color: AppColors.emerald),
          const SizedBox(width: 4),
          Text(
            _durationStr,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}
