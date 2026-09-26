import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/enhanced_attendance_history.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: () async {
            await auth.refreshAttendanceHistory();
          },
          color: AppColors.emerald,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Apple iOS Large Title Header ─────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.background,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ATTENDANCE',
                            style: AppText.sectionHeader,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'History',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: EnhancedAttendanceHistory(
                    attendanceList: auth.attendanceHistory,
                    onRefresh: () async {
                      await auth.refreshAttendanceHistory();
                    },
                    isRefreshing: auth.isRefreshingHistory,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
