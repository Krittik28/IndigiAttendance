import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:indigi_attendance/controllers/auth_controller.dart';
import 'package:indigi_attendance/controllers/leave_controller.dart';
import '../../models/leave_model.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(context, listen: false);
      if (authController.currentUser != null) {
        Provider.of<LeaveController>(context, listen: false).fetchLeaveData(authController.currentUser!.employeeCode);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final authController = Provider.of<AuthController>(context, listen: false);
      if (authController.currentUser != null) {
        Provider.of<LeaveController>(context, listen: false).fetchLeaveData(authController.currentUser!.employeeCode, refresh: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LeaveController>(context);
    final balance = controller.balance;
    final history = controller.history;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Leave Management',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined, color: Colors.indigo),
            tooltip: 'Leave Policy',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeavePolicyScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ApplyLeaveScreen()),
          );
        },
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Apply Leave'),
      ),
      body: controller.isLoading && balance == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () {
                final authController = Provider.of<AuthController>(context, listen: false);
                if (authController.currentUser != null) {
                  return controller.fetchLeaveData(authController.currentUser!.employeeCode);
                }
                return Future.value();
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (controller.errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[100]!),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(controller.errorMessage!, style: TextStyle(color: Colors.red[800]))),
                                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: controller.clearError),
                                ],
                              ),
                            ),
                          
                          if (balance != null) _buildBalanceGrid(balance),
                          const SizedBox(height: 32),
                          const Text(
                            'Leave History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  history.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Text(
                                'No leave history found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == history.length) {
                                return controller.isMoreLoading 
                                  ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                                  : const SizedBox.shrink();
                              }
                              final request = history[index];
                              return _buildHistoryItem(request);
                            },
                            childCount: history.length + 1,
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceGrid(LeaveBalance balance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Overview Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              _buildOverallProgress(balance),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Remaining Quota',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${balance.remaining.toStringAsFixed(1)} Days',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Out of ${balance.total.toStringAsFixed(1)} allotted days',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Leave Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        // Linear Progress List
        _buildProgressItem('Casual Leave', balance.clDisplay, balance.casualLeave, 12, Colors.blue),
        _buildProgressItem('Sick Leave', balance.slDisplay, balance.sickLeave, 12, Colors.red),
        _buildProgressItem('Earned Leave', balance.elDisplay, balance.earnedLeave, 15, Colors.green),
        _buildProgressItem('Work From Home', balance.wfhDisplay, balance.workFromHome, 24, Colors.orange),
        _buildProgressItem('Happiness Leave', balance.hplDisplay, balance.happinessLeave, 1, Colors.pink),
        _buildProgressItem('Paternity Leave', balance.ptlDisplay, balance.paternityLeave, 7, Colors.blueGrey),
        _buildProgressItem('Maternity Leave', balance.mtlDisplay, balance.maternityLeave, 180, Colors.deepPurple),
        _buildProgressItem('Marriage Leave', balance.mrlDisplay, balance.marriageLeave, 5, Colors.amber),
        _buildProgressItem('Bereavement Leave', balance.brlDisplay, balance.bereavementLeave, 3, Colors.brown),
        if (balance.carryForwardLeave > 0)
          _buildProgressItem('Carry Forward', balance.cfDisplay, balance.carryForwardLeave, 10, Colors.cyan),
      ],
    );
  }

  Widget _buildOverallProgress(LeaveBalance balance) {
    double percent = balance.total > 0 ? (balance.remaining / balance.total) : 0;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: CircularProgressIndicator(
            value: percent,
            strokeWidth: 8,
            backgroundColor: Colors.grey[100],
            color: Colors.indigo,
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          '${(percent * 100).toInt()}%',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.indigo,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressItem(String title, String value, double current, double max, Color color) {
    double progress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$value Days',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Removed old _buildSummaryCard as it is replaced by _buildSummaryItem

  Widget _buildHistoryItem(LeaveRequest request) {
    Color statusColor;
    String statusText;

    switch (request.status) {
      case LeaveStatus.approved:
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case LeaveStatus.applied:
        statusColor = Colors.blue;
        statusText = 'Applied';
        break;
      case LeaveStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case LeaveStatus.rejected:
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      case LeaveStatus.cancelled:
        statusColor = Colors.grey;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getLeaveTypeName(request.type),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final span = TextSpan(
                text: request.reason,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              );
              final tp = TextPainter(
                text: span,
                maxLines: 2,
                textDirection: Directionality.of(context),
              );
              tp.layout(maxWidth: constraints.maxWidth);
              final isTextOverflowing = tp.didExceedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.reason,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: _expandedIndices.contains(request.id) ? null : 2,
                    overflow: _expandedIndices.contains(request.id) ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  if (isTextOverflowing || _expandedIndices.contains(request.id))
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (_expandedIndices.contains(request.id)) {
                            _expandedIndices.remove(request.id);
                          } else {
                            _expandedIndices.add(request.id);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _expandedIndices.contains(request.id) ? 'Read Less' : 'Read More',
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Duration',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('MMM d').format(request.startDate)} - ${DateFormat('MMM d').format(request.endDate)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Days',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${request.noOfDays} Day${request.noOfDays > 1 ? 's' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          if (request.isEditable || request.isDeletable) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (request.isEditable)
                  TextButton.icon(
                    onPressed: () => _editLeave(request),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(foregroundColor: Colors.indigo),
                  ),
                if (request.isDeletable)
                  TextButton.icon(
                    onPressed: () => _confirmCancel(request),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _editLeave(LeaveRequest request) {
     Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplyLeaveScreen(existingRequest: request),
      ),
    );
  }

  void _confirmCancel(LeaveRequest request) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Leave'),
        content: const Text('Are you sure you want to cancel this leave request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('No')),
          TextButton(
            onPressed: () async {
              final authController = Provider.of<AuthController>(context, listen: false);
              final controller = Provider.of<LeaveController>(context, listen: false);
              final empCode = authController.currentUser?.employeeCode;
              
              Navigator.pop(dialogContext); // Close confirmation dialog
              
              if (empCode != null) {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                final success = await controller.cancelLeaveRequest(request.id, empCode);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close loading indicator
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Leave cancelled successfully'))
                    );
                  }
                }
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
}
