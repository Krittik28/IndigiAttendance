import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import '../controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';
import '../views/history_screen.dart';
import '../views/holiday_screen.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../models/holiday_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    // Fetch location when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final att = Provider.of<AttendanceController>(context, listen: false);
      att.fetchInitialLocation();
      if (auth.currentUser != null) {
        att.fetchTodayStatus(auth.currentUser!.employeeCode);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final attendanceController = Provider.of<AttendanceController>(context);
    final user = authController.currentUser;
    final todayHoliday = _getTodayHoliday();
    final upcomingHolidays = _getUpcomingHolidays();

    // Calculate opacity for the app bar profile image
    // AppBar expanded height is 170. Toolbar height is approx 56.
    // Transition range: Start fading in around 100, fully visible by 140.
    final double profileOpacity = ((_scrollOffset - 100) / 40).clamp(0.0, 1.0);

    return UpgradeAlert(
      upgrader: Upgrader(
        durationUntilAlertAgain: Duration.zero,
      ),
      showIgnore: false,
      showLater: false,
      shouldPopScope: () => false,
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Modern light grey background
      bottomNavigationBar: _buildBottomBar(context, attendanceController, authController, user),
      body: RefreshIndicator(
        onRefresh: () async {
          await authController.refreshAttendanceHistory();
          // Also refresh location on pull-to-refresh
          await attendanceController.fetchInitialLocation();
          if (user != null) {
            await attendanceController.fetchTodayStatus(user.employeeCode);
          }
        },
        color: Colors.indigo,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              expandedHeight: 170.0,
              centerTitle: false,
              titleSpacing: 20,
              title: attendanceController.cachedLocation != null
                  ? InkWell(
                      onTap: () => _showLocationDialog(context, attendanceController),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.indigo),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                attendanceController.cachedLocation!['shortLocation'] ?? 
                                (attendanceController.cachedLocation!['location']!.length > 25 
                                  ? '${attendanceController.cachedLocation!['location']!.substring(0, 25)}...' 
                                  : attendanceController.cachedLocation!['location']!),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fetching location...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
              actions: [
                 if (profileOpacity > 0)
                  Opacity(
                    opacity: profileOpacity,
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: user?.empAttachmentUrl != null && user!.empAttachmentUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: user.empAttachmentUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.indigo, size: 18),
                                  placeholder: (context, url) => Container(color: Colors.grey[100]),
                                )
                              : const Icon(Icons.person, color: Colors.indigo, size: 18),
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined, color: Colors.black87),
                  tooltip: 'Holiday List',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HolidayScreen()),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(Icons.logout_rounded, color: Colors.black87),
                    tooltip: 'Logout',
                    onPressed: () => _showLogoutDialog(context, authController),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 10),
                  alignment: Alignment.bottomLeft,
                  child: _buildProfileSection(user),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Holiday Banner
                    if (todayHoliday != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.celebration, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Holiday Today!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    todayHoliday.name,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                                          ),
                                        ),
                        
                                      // Upcoming Holidays Card
                                      if (upcomingHolidays.isNotEmpty)
                                        _buildUpcomingHolidaysCard(upcomingHolidays),
                        
                                      // Monthly Summary Chart
                                      _buildChartSection(authController.attendanceHistory),
                    const SizedBox(height: 24),

                    // Today's Status Card
                    if (attendanceController.todayStatus != null)
                      _buildTodayStatusCard(attendanceController.todayStatus!)
                    else
                      _buildLoadingCard(),

                    // Live Status/Processing Indicators
                    if (attendanceController.currentProcessingData != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildProcessingCard(
                          attendanceController.currentProcessingData!,
                        ),
                      ),

                    if (attendanceController.errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildErrorCard(attendanceController),
                      ),

                    const SizedBox(height: 24),

                    // Recent Activity Section
                    _buildSectionHeader(
                      context, 
                      title: 'Recent Activity', 
                      actionLabel: 'View All',
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 12),

                    _buildRecentActivityList(context, authController.attendanceHistory),
                    
                    const SizedBox(height: 40),
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

  Widget _buildProfileSection(User? user) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: user?.empAttachmentUrl != null && user!.empAttachmentUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: user.empAttachmentUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) {
                        return const Center(
                          child: Icon(Icons.person, color: Colors.indigo, size: 32),
                        );
                      },
                      placeholder: (context, url) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.person, color: Colors.indigo, size: 32),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 25),
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.name ?? 'Employee',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ID: ${user?.employeeCode ?? 'N/A'}',
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (user?.empAttachmentUrl == null || user!.empAttachmentUrl!.isEmpty || user.empAttachmentUrl == "NA") ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 12, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Kindly update profile image in HRM web portal',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(List<Attendance> history) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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
            height: 180,
            child: _AttendancePieChart(attendanceHistory: history),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildTodayStatusCard(Map<String, dynamic> status) {
    final checkinCount = status['checkinCount'] ?? 0;
    final checkoutCount = status['checkoutCount'] ?? 0;
    
    // Determine state
    bool isActive = checkinCount > checkoutCount;
    bool isDone = checkinCount > 0 && checkinCount == checkoutCount;
    
    Color accentColor = isActive ? Colors.orange : (isDone ? Colors.green : Colors.grey);
    IconData icon = isActive ? Icons.timer : (isDone ? Icons.check_circle : Icons.today);
    String title = isActive ? 'Shift in Progress' : (isDone ? 'Shift Completed' : 'Not Started');
    String subtitle = 'Check-ins: $checkinCount  •  Check-outs: $checkoutCount';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                if (status['lastCheckin'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Last activity: ${_formatTime(status['lastCheckin'])}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {
    required String title, 
    required String actionLabel, 
    required VoidCallback onAction
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.indigo),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList(BuildContext context, List<Attendance> history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              "No recent activity",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final recent = history.take(3).toList();

    return Column(
      children: recent.map((attendance) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryScreen(
                  initialFocusDate: DateTime.tryParse(attendance.checkinTime ?? ''),
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayFromDate(attendance.checkinTime ?? ''),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _getMonthAbbrFromDate(attendance.checkinTime ?? '').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDayName(attendance.checkinTime ?? ''),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildTimeChip(Icons.login, _formatTime(attendance.checkinTime ?? ''), Colors.green),
                          if (attendance.checkoutTime != null) ...[
                            const SizedBox(width: 8),
                            _buildTimeChip(Icons.logout, _formatTime(attendance.checkoutTime!), Colors.orange),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(attendance.checkoutTime != null),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeChip(IconData icon, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isCompleted ? 'Done' : 'Active',
        style: TextStyle(
          color: isCompleted ? Colors.green : Colors.orange,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProcessingCard(Map<String, dynamic> processingData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo),
          ),
          const SizedBox(width: 12),
          Text(
            'Processing ${processingData['type']}...',
            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(AttendanceController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            onPressed: () => controller.clearError(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.3),
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
                Icon(icon, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }

  List<Holiday> _getUpcomingHolidays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    return holidayList2026.where((h) {
      final hDate = DateTime(h.date.year, h.date.month, h.date.day);
      return hDate.isAfter(today) && hDate.isBefore(nextWeek.add(const Duration(days: 1)));
    }).toList();
  }

  Widget _buildUpcomingHolidaysCard(List<Holiday> holidays) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HolidayScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event, color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Upcoming Holidays',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.teal),
                ],
              ),
              const SizedBox(height: 16),
              ...holidays.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_getMonthAbbrFromDate(h.date.toString())} ${h.date.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        h.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _getDayName(h.date.toString()).substring(0, 3),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    AttendanceController attendanceController,
    AuthController authController,
    User? user,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Updated to withValues
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.login_rounded,
                label: 'Check In',
                color: const Color(0xFF4CAF50), // Material Green 500
                isLoading: attendanceController.isLoading,
                onPressed: () {
                  _showConfirmationDialog(
                    context: context,
                    title: 'Confirm Check-in',
                    content: 'Are you sure you want to check in now?',
                    icon: Icons.login_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    controller: attendanceController,
                    onConfirm: () async {
                      final success = await attendanceController.checkIn(
                        employeeCode: user!.employeeCode,
                      );
                      if (success && context.mounted) {
                        _showSuccessDialog(context, 'Check-in Successful!');
                        await authController.refreshAttendanceHistory();
                        await attendanceController.fetchTodayStatus(user.employeeCode);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.logout_rounded,
                label: 'Check Out',
                color: const Color(0xFFFF9800), // Material Orange 500
                isLoading: attendanceController.isLoading,
                onPressed: () {
                  _showConfirmationDialog(
                    context: context,
                    title: 'Confirm Check-out',
                    content: 'Are you sure you want to check out now?',
                    icon: Icons.logout_rounded,
                    iconColor: const Color(0xFFFF9800),
                    controller: attendanceController,
                    onConfirm: () async {
                      final success = await attendanceController.checkOut(
                        employeeCode: user!.employeeCode,
                      );
                      if (success && context.mounted) {
                        _showSuccessDialog(context, 'Check-out Successful!');
                        attendanceController.clearCurrentAttendance();
                        await authController.refreshAttendanceHistory();
                        await attendanceController.fetchTodayStatus(user.employeeCode);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Utility Methods ---

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

  String _getDayFromDate(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return date.day.toString().padLeft(2, '0');
    } catch (e) {
      return '--';
    }
  }

  String _getMonthAbbrFromDate(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[date.month - 1];
    } catch (e) {
      return '-';
    }
  }

  String _getDayName(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    } catch (e) {
      return 'Unknown';
    }
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder<Map<String, String>?>(
              future: controller.fetchLocationSilent(),
              builder: (context, snapshot) {
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final locationData = snapshot.data;
                // Use snapshot data if available, otherwise fallback to cache, then unknown
                final location = locationData?['location'] ?? controller.cachedLocation?['location'] ?? 'Unknown Location';
                final isLocationValid = location != 'Unknown Location';

                return AlertDialog(
                  title: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        content,
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isLocationValid ? Colors.grey[100] : Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLocationValid ? Colors.grey[300]! : Colors.red.withValues(alpha: 0.2)
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isLoading) ...[
                              const SizedBox(
                                width: 16, 
                                height: 16, 
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Fetching location...',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ] else ...[
                              Icon(
                                isLocationValid ? Icons.location_on : Icons.location_off, 
                                size: 16, 
                                color: isLocationValid ? Colors.grey[600] : Colors.red
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isLocationValid ? Colors.grey[800] : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isLocationValid)
                                InkWell(
                                  onTap: () {
                                    // Trigger a rebuild to retry the FutureBuilder
                                    setState(() {}); 
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.refresh, size: 16, color: Colors.indigo),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      if (!isLoading && !isLocationValid)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Location required. Tap icon to retry.',
                            style: TextStyle(fontSize: 11, color: Colors.red.withValues(alpha: 0.8)),
                          ),
                        ),
                    ],
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: (isLoading || !isLocationValid) ? null : () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ],
                );
              },
            );
          }
        );
      },
    );
  }

  void _showLocationDialog(BuildContext context, AttendanceController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on, color: Colors.indigo, size: 28),
            ),
            const SizedBox(height: 12),
            const Text(
              'Current Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.cachedLocation?['location'] ?? 'Unknown Location',
              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Coordinates: ${controller.cachedLocation?['latitude'] ?? '-'}, ${controller.cachedLocation?['longitude'] ?? '-'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await controller.fetchInitialLocation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
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
        content: const Text('Are you sure you want to log out of your account?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authController.logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.green, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Success',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Great!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Chart Components ---

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
                      color: touchedIndex == -1 ? Colors.black87 : centerTextColor,
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
                      color: touchedIndex == -1 ? centerTextColor : Colors.grey[800],
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
            const SizedBox(height: 12),
            _buildIndicator(
              color: const Color(0xFFFF9800),
              text: 'Pending',
              value: '${data['pending']}',
            ),
            const SizedBox(height: 12),
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

  Widget _buildIndicator({required Color color, required String text, required String value}) {
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
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
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

    // Group by day to handle multiple check-ins
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
      // If ANY session is active (no checkout), the day is Pending/Active
      bool hasActive = sessions.any((s) => s.checkoutTime == null);
      if (hasActive) {
        pending++;
      } else {
        completed++;
      }
    });

    int attendedCount = completed + pending;
    
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
      bool isHoliday = holidayList2026.any((h) => 
        h.date.year == day.year && 
        h.date.month == day.month && 
        h.date.day == day.day
      );
      
      if (isHoliday) {
        continue;
      }

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

  List<PieChartSectionData> showingSections(Map<String, int> data) {
    return List.generate(3, (i) {
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