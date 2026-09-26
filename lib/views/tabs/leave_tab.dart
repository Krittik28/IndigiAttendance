import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/leave_controller.dart';
import '../../models/leave_model.dart';
import '../leave/apply_leave_screen.dart';
import '../leave/leave_policy_screen.dart';
import '../leave/leave_approval_list_screen.dart';

class LeaveTab extends StatefulWidget {
  final bool? showBackButton;

  const LeaveTab({super.key, this.showBackButton = false});

  @override
  State<LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends State<LeaveTab> {
  bool get _hasBackButton => widget.showBackButton == true;

  final ScrollController _scrollController = ScrollController();
  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      if (auth.currentUser != null) {
        Provider.of<LeaveController>(context, listen: false)
            .fetchLeaveData(auth.currentUser!.employeeCode);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final auth = Provider.of<AuthController>(context, listen: false);
      if (auth.currentUser != null) {
        Provider.of<LeaveController>(context, listen: false)
            .fetchLeaveData(auth.currentUser!.employeeCode, refresh: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveController = Provider.of<LeaveController>(context);
    final auth = Provider.of<AuthController>(context);
    final user = auth.currentUser;
    final balance = leaveController.balance; // LeaveBalance?
    final history = leaveController.history; // List<LeaveRequest>

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          controller: _scrollController,
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
                        // Top bar with back button (if any) and approvals button (if any)
                        if (_hasBackButton || user?.canApproveLeave == true)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_hasBackButton)
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.cardBorder, width: 0.8),
                                        boxShadow: AppShadows.card,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                if (user?.canApproveLeave == true)
                                  GestureDetector(
                                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                                      MaterialPageRoute(
                                          builder: (_) => const LeaveApprovalListScreen()),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                        border: Border.all(color: AppColors.cardBorder, width: 0.8),
                                        boxShadow: AppShadows.card,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.fact_check_outlined,
                                              size: 14, color: AppColors.textPrimary),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Approvals',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if ((user?.pendingLeaveCount ?? 0) > 0) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              width: 18,
                                              height: 18,
                                              decoration: const BoxDecoration(
                                                color: AppColors.amber,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${user?.pendingLeaveCount ?? 0}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        Text(
                          'LEAVE MANAGEMENT',
                          style: AppText.sectionHeader,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Leave',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Quick Action Buttons
                        Row(
                          children: [
                            _QuickActionChip(
                              icon: Icons.add_rounded,
                              label: 'Apply Leave',
                              isPrimary: true,
                              onTap: () => Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                    builder: (_) => const ApplyLeaveScreen()),
                              ).then((_) {
                                if (user != null) {
                                  leaveController.fetchLeaveData(
                                      user.employeeCode,
                                      refresh: true);
                                }
                              }),
                            ),
                            const SizedBox(width: 10),
                            _QuickActionChip(
                              icon: Icons.policy_outlined,
                              label: 'Policy',
                              isPrimary: false,
                              onTap: () => Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                    builder: (_) => const LeavePolicyScreen()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Content ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leaveController.isLoading && balance == null)
                    const _LoadingSection()
                  else if (balance != null) ...[
                    _sectionLabel('Leave Balance'),
                    const SizedBox(height: 12),
                    _buildBalanceGrid(balance),
                    const SizedBox(height: 28),
                  ],

                  // Leave History
                  _sectionLabel('Leave History'),
                  const SizedBox(height: 12),
                  _buildLeaveHistory(history, leaveController.isLoading),
                  SizedBox(height: _hasBackButton ? 40 : 120),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }

  // Build a grid with all leave balance categories
  Widget _buildBalanceGrid(LeaveBalance balance) {
    final items = [
      _BalanceItem('Casual Leave', balance.casualLeave, 0),
      _BalanceItem('Sick Leave', balance.sickLeave, 1),
      _BalanceItem('Earned Leave', balance.earnedLeave, 2),
      _BalanceItem('Work From Home', balance.workFromHome, 0),
      _BalanceItem('Happiness Leave', balance.happinessLeave, 3),
      _BalanceItem('Paternity Leave', balance.paternityLeave, 3),
      _BalanceItem('Maternity Leave', balance.maternityLeave, 0),
      _BalanceItem('Marriage Leave', balance.marriageLeave, 1),
      _BalanceItem('Bereavement Leave', balance.bereavementLeave, 2),
      _BalanceItem('Comp Off', balance.compOff, 1),
      if (balance.carryForwardLeave > 0)
        _BalanceItem('Carry Forward', balance.carryForwardLeave, 2),
    ];

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder, width: 0.8),
          boxShadow: AppShadows.card,
        ),
        child: const Center(
          child: Text(
            'No leave balance data available',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 0.8),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.value.toStringAsFixed(1).replaceAll('.0', ''),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'days remaining',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildLeaveHistory(List<LeaveRequest> history, bool isLoading) {
    if (isLoading && history.isEmpty) {
      return const _LoadingSection();
    }

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
            Icon(Icons.event_busy_rounded,
                size: 48,
                color: AppColors.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'No leave history',
              style: TextStyle(color: AppColors.textHint, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: history.asMap().entries.map((entry) {
        final i = entry.key;
        final leave = entry.value;
        final isExpanded = _expandedIndices.contains(i);
        final statusColor = _leaveStatusColor(leave.status);
        final leaveTypeStr = _leaveTypeLabel(leave.type);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 0.8),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedIndices.remove(i);
                    } else {
                      _expandedIndices.add(i);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          _leaveIcon(leave.status),
                          color: statusColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leaveTypeStr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatDateRange(leave.startDate, leave.endDate),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              _leaveStatusLabel(leave.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${leave.noOfDays.toStringAsFixed(1)} day${leave.noOfDays != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.expand_more_rounded,
                            color: AppColors.textHint, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildLeaveDetail(leave),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeaveDetail(LeaveRequest leave) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 14),
          if (leave.reason.isNotEmpty)
            _DetailRow(label: 'Reason', value: leave.reason),
          if (leave.rmName != null && leave.rmName!.isNotEmpty)
            _DetailRow(label: 'RM', value: leave.rmName ?? ''),
          if (leave.pmName != null && leave.pmName!.isNotEmpty)
            _DetailRow(label: 'PM', value: leave.pmName ?? ''),
          if (leave.rejectionReason != null && leave.rejectionReason!.isNotEmpty)
            _DetailRow(label: 'Remarks', value: leave.rejectionReason ?? ''),
        ],
      ),
    );
  }

  Color _leaveStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.approved:
      case LeaveStatus.rmApproved:
      case LeaveStatus.pmApproved:
        return AppColors.success;
      case LeaveStatus.rejected:
        return AppColors.error;
      case LeaveStatus.pending:
      case LeaveStatus.applied:
        return AppColors.warning;
      case LeaveStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  String _leaveStatusLabel(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.approved: return 'Approved';
      case LeaveStatus.rmApproved: return 'RM Approved';
      case LeaveStatus.pmApproved: return 'PM Approved';
      case LeaveStatus.rejected: return 'Rejected';
      case LeaveStatus.pending: return 'Pending';
      case LeaveStatus.applied: return 'Applied';
      case LeaveStatus.cancelled: return 'Cancelled';
    }
  }

  IconData _leaveIcon(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.approved:
      case LeaveStatus.rmApproved:
      case LeaveStatus.pmApproved:
        return Icons.check_circle_rounded;
      case LeaveStatus.rejected:
        return Icons.cancel_rounded;
      case LeaveStatus.cancelled:
        return Icons.block_rounded;
      case LeaveStatus.pending:
      case LeaveStatus.applied:
        return Icons.pending_rounded;
    }
  }

  String _leaveTypeLabel(LeaveType type) {
    switch (type) {
      case LeaveType.sickLeave: return 'Sick Leave';
      case LeaveType.casualLeave: return 'Casual Leave';
      case LeaveType.happinessLeave: return 'Happiness Leave';
      case LeaveType.maternityLeave: return 'Maternity Leave';
      case LeaveType.paternityLeave: return 'Paternity Leave';
      case LeaveType.marriageLeave: return 'Marriage Leave';
      case LeaveType.bereavementLeave: return 'Bereavement Leave';
      case LeaveType.earnedLeave: return 'Earned Leave';
      case LeaveType.carryForwardLeave: return 'Carry Forward';
      case LeaveType.workFromHome: return 'Work From Home';
      case LeaveType.compOff: return 'Comp Off';
      case LeaveType.lwp: return 'LWP';
    }
  }

  String _formatDateRange(DateTime from, DateTime to) {
    final fmt = DateFormat('d MMM');
    if (from == to) return fmt.format(from);
    if (from.year == to.year) {
      return '${fmt.format(from)} – ${DateFormat('d MMM yyyy').format(to)}';
    }
    return '${DateFormat('d MMM yyyy').format(from)} – ${DateFormat('d MMM yyyy').format(to)}';
  }
}

// ─── Helper Classes ──────────────────────────────────────────────────────────
class _BalanceItem {
  final String label;
  final double value;
  final int colorIndex;
  const _BalanceItem(this.label, this.value, this.colorIndex);
}


class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.emerald : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.cardBorder, width: 0.8),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : AppShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isPrimary ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
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
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
