import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:indigi_attendance/controllers/auth_controller.dart';
import 'package:indigi_attendance/controllers/leave_controller.dart';
import '../../models/leave_model.dart';
import '../../theme/app_theme.dart';
import 'apply_leave_screen.dart';
import 'leave_policy_screen.dart';

class LeaveDashboardScreen extends StatefulWidget {
  const LeaveDashboardScreen({super.key});

  @override
  State<LeaveDashboardScreen> createState() => _LeaveDashboardScreenState();
}

class _LeaveDashboardScreenState extends State<LeaveDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<int> _expandedIndices = {};

  // ── Filter state ──────────────────────────────────────────────────────────
  LeaveStatus? _filterStatus;   // null = all statuses
  LeaveType?   _filterType;     // null = all types

  List<LeaveRequest> _applyFilters(List<LeaveRequest> all) {
    return all.where((r) {
      if (_filterStatus != null && r.status != _filterStatus) return false;
      if (_filterType   != null && r.type   != _filterType)   return false;
      return true;
    }).toList();
  }

  int get _activeFilterCount =>
      (_filterStatus != null ? 1 : 0) + (_filterType != null ? 1 : 0);

  void _clearFilters() => setState(() { _filterStatus = null; _filterType = null; });

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterBottomSheet(
        currentStatus: _filterStatus,
        currentType: _filterType,
        onApply: (status, type) {
          setState(() {
            _filterStatus = status;
            _filterType   = type;
          });
        },
        onClear: _clearFilters,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(context, listen: false);
      if (authController.currentUser != null) {
        Provider.of<LeaveController>(context, listen: false)
            .fetchLeaveData(authController.currentUser!.employeeCode);
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
    final controller = Provider.of<LeaveController>(context);
    final balance = controller.balance;
    final allHistory = controller.history;
    final filtered  = _applyFilters(allHistory);
    final hasFilters = _activeFilterCount > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Leave'),
        backgroundColor: AppTheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.policy_outlined, color: AppTheme.accent),
            tooltip: 'Leave Policy',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeavePolicyScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 72,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()),
          ),
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          elevation: 2,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Apply Leave',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: controller.isLoading && balance == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              onRefresh: () {
                final authController = Provider.of<AuthController>(context, listen: false);
                if (authController.currentUser != null) {
                  return controller.fetchLeaveData(authController.currentUser!.employeeCode);
                }
                return Future.value();
              },
              color: AppTheme.accent,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Balance Section ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Error message
                          if (controller.errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.errorLight,
                                borderRadius: AppTheme.radiusMD,
                                border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      controller.errorMessage!,
                                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: controller.clearError,
                                    child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.error),
                                  ),
                                ],
                              ),
                            ),

                          if (balance != null) ...[
                            // ── Leave Balance Grid ────────────────────────────
                            const _SectionLabel(title: 'Leave Balance'),
                            _LeaveBalanceGrid(balance: balance),
                            const SizedBox(height: 28),
                          ],

                          // ── History Header with filter ────────────────────
                          Row(
                            children: [
                              const Expanded(child: _SectionLabel(title: 'Leave History')),
                              // Filter button with badge
                              GestureDetector(
                                onTap: () => _showFilterSheet(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: hasFilters ? AppTheme.accent : AppTheme.surfaceVariant,
                                    borderRadius: AppTheme.radiusSM,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.tune_rounded,
                                        size: 14,
                                        color: hasFilters ? Colors.white : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        hasFilters ? 'Filter ($_activeFilterCount)' : 'Filter',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: hasFilters ? Colors.white : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Active filter chips row
                          if (hasFilters) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (_filterStatus != null)
                                  _FilterChipBadge(
                                    label: _statusLabel(_filterStatus!),
                                    onRemove: () => setState(() => _filterStatus = null),
                                  ),
                                if (_filterType != null)
                                  _FilterChipBadge(
                                    label: _typeLabel(_filterType!),
                                    onRemove: () => setState(() => _filterType = null),
                                  ),
                                GestureDetector(
                                  onTap: _clearFilters,
                                  child: const Text(
                                    'Clear all',
                                    style: TextStyle(fontSize: 12, color: AppTheme.error, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],

                          // Result count
                          if (allHistory.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              hasFilters
                                  ? '${filtered.length} of ${allHistory.length} records'
                                  : '${allHistory.length} records',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── History List ─────────────────────────────────────
                  filtered.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 36),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: AppTheme.radiusXL,
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    hasFilters ? Icons.filter_list_off_rounded : Icons.history_toggle_off_rounded,
                                    size: 42,
                                    color: AppTheme.border,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    hasFilters ? 'No records match your filters' : 'No leave history found',
                                    style: const TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                                  ),
                                  if (hasFilters) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: _clearFilters,
                                      child: const Text('Clear filters', style: TextStyle(color: AppTheme.accent)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == filtered.length) {
                                  // ── Load More button (replaces auto scroll) ──
                                  if (!controller.hasMore) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: controller.isMoreLoading
                                          ? const CircularProgressIndicator(color: AppTheme.accent)
                                          : OutlinedButton.icon(
                                              onPressed: () {
                                                final authController = Provider.of<AuthController>(context, listen: false);
                                                if (authController.currentUser != null) {
                                                  controller.fetchLeaveData(
                                                    authController.currentUser!.employeeCode,
                                                    refresh: false,
                                                  );
                                                }
                                              },
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: AppTheme.accent),
                                                shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusMD),
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              ),
                                              icon: const Icon(Icons.expand_more_rounded, color: AppTheme.accent, size: 18),
                                              label: const Text(
                                                'Load more',
                                                style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                    ),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _LeaveHistoryCard(
                                    request: filtered[index],
                                    isExpanded: _expandedIndices.contains(filtered[index].id),
                                    onToggleExpand: () {
                                      setState(() {
                                        if (_expandedIndices.contains(filtered[index].id)) {
                                          _expandedIndices.remove(filtered[index].id);
                                        } else {
                                          _expandedIndices.add(filtered[index].id);
                                        }
                                      });
                                    },
                                    onEdit: () => _editLeave(filtered[index]),
                                    onCancel: () => _confirmCancel(filtered[index]),
                                  ),
                                );
                              },
                              childCount: filtered.length + 1,
                            ),
                          ),
                        ),

                  const SliverToBoxAdapter(child: SizedBox(height: 160)),
                ],
              ),
            ),
    );
  }

  String _statusLabel(LeaveStatus s) {
    switch (s) {
      case LeaveStatus.approved:   return 'Approved';
      case LeaveStatus.rmApproved: return 'RM Approved';
      case LeaveStatus.pmApproved: return 'PM Approved';
      case LeaveStatus.applied:    return 'Applied';
      case LeaveStatus.pending:    return 'Pending';
      case LeaveStatus.rejected:   return 'Rejected';
      case LeaveStatus.cancelled:  return 'Cancelled';
    }
  }

  String _typeLabel(LeaveType t) {
    switch (t) {
      case LeaveType.casualLeave:      return 'Casual';
      case LeaveType.sickLeave:        return 'Sick';
      case LeaveType.earnedLeave:      return 'Earned';
      case LeaveType.workFromHome:     return 'WFH';
      case LeaveType.happinessLeave:   return 'Happiness';
      case LeaveType.paternityLeave:   return 'Paternity';
      case LeaveType.maternityLeave:   return 'Maternity';
      case LeaveType.marriageLeave:    return 'Marriage';
      case LeaveType.bereavementLeave: return 'Bereavement';
      case LeaveType.carryForwardLeave:return 'Carry Forward';
      case LeaveType.compOff:          return 'Comp-Off';
      case LeaveType.lwp:              return 'LWP';
    }
  }

  void _editLeave(LeaveRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ApplyLeaveScreen(existingRequest: request)),
    );
  }

  void _confirmCancel(LeaveRequest request) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusXL),
        backgroundColor: AppTheme.surface,
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.errorLight,
            borderRadius: AppTheme.radiusMD,
          ),
          child: const Icon(Icons.cancel_outlined, color: AppTheme.error, size: 24),
        ),
        title: const Text('Cancel Leave', textAlign: TextAlign.center, style: AppTheme.headingSM),
        content: const Text(
          'Are you sure you want to cancel this leave request?',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final authController = Provider.of<AuthController>(context, listen: false);
              final controller = Provider.of<LeaveController>(context, listen: false);
              final empCode = authController.currentUser?.employeeCode;
              Navigator.pop(dialogContext);
              if (empCode != null) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                );
                final success = await controller.cancelLeaveRequest(request.id, empCode);
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Leave cancelled successfully'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusMD),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chip Badge ─────────────────────────────────────────────────────────

class _FilterChipBadge extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChipBadge({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.10),
        borderRadius: AppTheme.radiusXS,
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accent),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: AppTheme.accent),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bottom Sheet ───────────────────────────────────────────────────────

class _FilterBottomSheet extends StatefulWidget {
  final LeaveStatus? currentStatus;
  final LeaveType?   currentType;
  final void Function(LeaveStatus? status, LeaveType? type) onApply;
  final VoidCallback onClear;

  const _FilterBottomSheet({
    required this.currentStatus,
    required this.currentType,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late LeaveStatus? _status;
  late LeaveType?   _type;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
    _type   = widget.currentType;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filter Leave History',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() { _status = null; _type = null; });
                  },
                  child: const Text('Reset', style: TextStyle(color: AppTheme.error, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status filter
            const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip(null, 'All'),
                _buildStatusChip(LeaveStatus.applied, 'Applied'),
                _buildStatusChip(LeaveStatus.pending, 'Pending'),
                _buildStatusChip(LeaveStatus.approved, 'Approved'),
                _buildStatusChip(LeaveStatus.rmApproved, 'RM Approved'),
                _buildStatusChip(LeaveStatus.pmApproved, 'PM Approved'),
                _buildStatusChip(LeaveStatus.rejected, 'Rejected'),
                _buildStatusChip(LeaveStatus.cancelled, 'Cancelled'),
              ],
            ),
            const SizedBox(height: 20),

            // Type filter
            const Text('Leave Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeChip(null,                     'All'),
                _buildTypeChip(LeaveType.casualLeave,    'Casual'),
                _buildTypeChip(LeaveType.sickLeave,      'Sick'),
                _buildTypeChip(LeaveType.earnedLeave,    'Earned'),
                _buildTypeChip(LeaveType.workFromHome,   'WFH'),
                _buildTypeChip(LeaveType.happinessLeave, 'Happiness'),
                _buildTypeChip(LeaveType.paternityLeave, 'Paternity'),
                _buildTypeChip(LeaveType.maternityLeave, 'Maternity'),
                _buildTypeChip(LeaveType.marriageLeave,  'Marriage'),
                _buildTypeChip(LeaveType.bereavementLeave,'Bereavement'),
                _buildTypeChip(LeaveType.carryForwardLeave,'Carry Forward'),
                _buildTypeChip(LeaveType.compOff,        'Comp-Off'),
                _buildTypeChip(LeaveType.lwp,            'LWP'),
              ],
            ),
            const SizedBox(height: 24),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_status, _type);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusMD),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(LeaveStatus? value, String label) {
    final selected = _status == value;
    return GestureDetector(
      onTap: () => setState(() => _status = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.surfaceVariant,
          borderRadius: AppTheme.radiusSM,
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(LeaveType? value, String label) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.surfaceVariant,
          borderRadius: AppTheme.radiusSM,
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}


// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─── Leave Balance Grid ───────────────────────────────────────────────────────

class _LeaveBalanceGrid extends StatelessWidget {
  final LeaveBalance balance;
  const _LeaveBalanceGrid({required this.balance});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _LeaveTile('Casual Leave',      balance.casualLeave,     const Color(0xFF3D5AFE)),
      _LeaveTile('Sick Leave',        balance.sickLeave,        const Color(0xFFE53935)),
      _LeaveTile('Earned Leave',      balance.earnedLeave,      const Color(0xFF2E7D32)),
      _LeaveTile('Work From Home',    balance.workFromHome,     const Color(0xFF0097A7)),
      _LeaveTile('Happiness Leave',   balance.happinessLeave,   const Color(0xFFD81B60)),
      _LeaveTile('Paternity Leave',   balance.paternityLeave,   const Color(0xFF546E7A)),
      _LeaveTile('Maternity Leave',   balance.maternityLeave,   const Color(0xFF6D4C41)),
      _LeaveTile('Marriage Leave',    balance.marriageLeave,    const Color(0xFFF57C00)),
      _LeaveTile('Bereavement Leave', balance.bereavementLeave, const Color(0xFF5E35B1)),
      if (balance.carryForwardLeave > 0)
        _LeaveTile('Carry Forward',   balance.carryForwardLeave, const Color(0xFF00897B)),
    ];

    // Split tiles into pairs for 2-column layout
    final rows = <List<_LeaveTile>>[];
    for (int i = 0; i < tiles.length; i += 2) {
      rows.add(tiles.sublist(i, i + 2 <= tiles.length ? i + 2 : tiles.length));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusXL,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int r = 0; r < rows.length; r++) ...[
            if (r > 0)
              const Divider(height: 1, thickness: 1, color: AppTheme.border),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _LeaveTileCell(tile: rows[r][0])),
                  if (rows[r].length > 1) ...[
                    const VerticalDivider(width: 1, thickness: 1, color: AppTheme.border),
                    Expanded(child: _LeaveTileCell(tile: rows[r][1])),
                  ] else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaveTile {
  final String name;
  final double remaining; // API returns remaining balance directly
  final Color color;
  const _LeaveTile(this.name, this.remaining, this.color);
}

class _LeaveTileCell extends StatelessWidget {
  final _LeaveTile tile;
  const _LeaveTileCell({required this.tile});

  @override
  Widget build(BuildContext context) {
    final remaining = tile.remaining;
    final isZero = remaining <= 0;
    final displayColor = isZero ? AppTheme.textTertiary : tile.color;

    final remainStr = remaining % 1 == 0
        ? remaining.toInt().toString()
        : remaining.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          // Colored dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: displayColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Leave type name
          Expanded(
            child: Text(
              tile.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isZero ? AppTheme.textTertiary : AppTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Remaining count (directly from API response)
          Text(
            remainStr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isZero ? AppTheme.textTertiary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Leave History Card ───────────────────────────────────────────────────────

class _LeaveHistoryCard extends StatelessWidget {
  final LeaveRequest request;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const _LeaveHistoryCard({
    required this.request,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onEdit,
    required this.onCancel,
  });

  Color get _statusColor {
    switch (request.status) {
      case LeaveStatus.approved:
      case LeaveStatus.pmApproved: return AppTheme.success;
      case LeaveStatus.rmApproved: return const Color(0xFF00897B);
      case LeaveStatus.applied:
      case LeaveStatus.pending: return AppTheme.accent;
      case LeaveStatus.rejected: return AppTheme.error;
      case LeaveStatus.cancelled: return AppTheme.textTertiary;
    }
  }

  String get _statusText {
    switch (request.status) {
      case LeaveStatus.approved: return 'Approved';
      case LeaveStatus.rmApproved: return 'RM Approved';
      case LeaveStatus.pmApproved: return 'PM Approved';
      case LeaveStatus.applied: return 'Applied';
      case LeaveStatus.pending: return 'Pending';
      case LeaveStatus.rejected: return 'Rejected';
      case LeaveStatus.cancelled: return 'Cancelled';
    }
  }

  String _getLeaveTypeName(LeaveType type) {
    switch (type) {
      case LeaveType.sickLeave: return 'Sick Leave';
      case LeaveType.casualLeave: return 'Casual Leave';
      case LeaveType.happinessLeave: return 'Happiness Leave';
      case LeaveType.maternityLeave: return 'Maternity Leave';
      case LeaveType.paternityLeave: return 'Paternity Leave';
      case LeaveType.marriageLeave: return 'Marriage Leave';
      case LeaveType.bereavementLeave: return 'Bereavement Leave';
      case LeaveType.earnedLeave: return 'Earned Leave';
      case LeaveType.carryForwardLeave: return 'Carry Forward Leave';
      case LeaveType.workFromHome: return 'Work From Home';
      case LeaveType.compOff: return 'Comp-Off';
      case LeaveType.lwp: return 'LWP';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusXL,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getLeaveTypeName(request.type),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: AppTheme.radiusXS,
                      ),
                      child: Text(
                        _statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Reason
                LayoutBuilder(
                  builder: (context, constraints) {
                    final span = TextSpan(
                      text: request.reason,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    );
                    final tp = TextPainter(
                      text: span,
                      maxLines: 2,
                      textDirection: Directionality.of(context),
                    );
                    tp.layout(maxWidth: constraints.maxWidth);
                    final isOverflowing = tp.didExceedMaxLines;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.reason,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        ),
                        if (isOverflowing || isExpanded)
                          GestureDetector(
                            onTap: onToggleExpand,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                isExpanded ? 'Show less' : 'Read more',
                                style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 14),

                // Duration and Days row
                Row(
                  children: [
                    Expanded(
                      child: _MetaCell(
                        label: 'Duration',
                        value: '${DateFormat('MMM d').format(request.startDate)} – ${DateFormat('MMM d').format(request.endDate)}',
                        align: CrossAxisAlignment.start,
                      ),
                    ),
                    _MetaCell(
                      label: 'Days',
                      value: '${request.noOfDays} Day${request.noOfDays > 1 ? 's' : ''}',
                      align: CrossAxisAlignment.end,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Manager info row
                Row(
                  children: [
                    Expanded(
                      child: _MetaCell(
                        label: 'RM',
                        value: request.rmName ?? 'Not Assigned',
                        align: CrossAxisAlignment.start,
                      ),
                    ),
                    Expanded(
                      child: _MetaCell(
                        label: 'PM',
                        value: request.pmName ?? 'Not Assigned',
                        align: CrossAxisAlignment.end,
                      ),
                    ),
                  ],
                ),

                // Action buttons
                if (request.isEditable || request.isDeletable) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (request.isEditable)
                        _ActionButton(
                          label: 'Edit',
                          icon: Icons.edit_outlined,
                          color: AppTheme.accent,
                          onTap: onEdit,
                        ),
                      if (request.isEditable && request.isDeletable)
                        const SizedBox(width: 8),
                      if (request.isDeletable)
                        _ActionButton(
                          label: 'Cancel',
                          icon: Icons.cancel_outlined,
                          color: AppTheme.error,
                          onTap: onCancel,
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
}

class _MetaCell extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;

  const _MetaCell({required this.label, required this.value, required this.align});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textTertiary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppTheme.radiusXS,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
