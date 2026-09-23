import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import '../controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/client_visit_controller.dart';
import '../controllers/leave_controller.dart';
import '../theme/app_theme.dart';
import 'dashboard_tab.dart';
import 'attendance_tab.dart';
import 'leave/leave_dashboard_screen.dart';
import 'more_screen.dart';
import 'menu_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const AttendanceTab(),
    const LeaveDashboardScreen(),
    const MoreScreen(),
    const MenuTab(),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animController.forward();

    // Fetch initial parameters on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final att = Provider.of<AttendanceController>(context, listen: false);
      att.fetchInitialLocation();
      if (auth.currentUser != null) {
        att.fetchTodayStatus(auth.currentUser!.employeeCode);
        auth.fetchPendingLeaves();
        Provider.of<ClientVisitController>(context, listen: false).fetchHistory(auth.currentUser!.employeeCode);
        Provider.of<LeaveController>(context, listen: false).fetchLeaveData(auth.currentUser!.employeeCode);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        durationUntilAlertAgain: Duration.zero,
      ),
      showIgnore: false,
      showLater: false,
      shouldPopScope: () => false,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: _buildTabBar(),
      ),
    );
  }

  Widget _buildTabBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xF2FFFFFF),
            border: Border(
              top: BorderSide(
                color: Color(0x18000000),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  _buildTabItem(0, CupertinoIcons.house_fill, CupertinoIcons.house, 'Home'),
                  _buildTabItem(1, CupertinoIcons.clock_fill, CupertinoIcons.clock, 'Attendance'),
                  _buildTabItem(2, CupertinoIcons.calendar_today, CupertinoIcons.calendar, 'Leaves'),
                  _buildTabItem(3, CupertinoIcons.square_grid_2x2_fill, CupertinoIcons.square_grid_2x2, 'More'),
                  _buildTabItem(4, CupertinoIcons.person_fill, CupertinoIcons.person, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accent.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: AppTheme.radiusSM,
                ),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  size: 22,
                  color: isSelected ? AppTheme.accent : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.accent : const Color(0xFF9CA3AF),
                  letterSpacing: isSelected ? -0.1 : 0,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}