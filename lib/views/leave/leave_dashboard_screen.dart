import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/leave_controller.dart';
import '../../models/leave_model.dart';
import 'apply_leave_screen.dart';

class LeaveDashboardScreen extends StatefulWidget {
  const LeaveDashboardScreen({super.key});

  @override
  State<LeaveDashboardScreen> createState() => _LeaveDashboardScreenState();
}

class _LeaveDashboardScreenState extends State<LeaveDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(context, listen: false);
      if (authController.currentUser != null) {
        Provider.of<LeaveController>(context, listen: false).fetchLeaveData(authController.currentUser!.id);
      }
    });
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
                  return controller.fetchLeaveData(authController.currentUser!.id);
                }
                return Future.value();
              },
              child: CustomScrollView(
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
                              child: Text(
                                controller.errorMessage!,
                                style: TextStyle(color: Colors.red[800]),
                              ),
                            ),
                          
                          const Text(
                            'Your Balance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (balance != null) ...[
                            _buildBalanceGrid(balance),
                            if (balance.isProbation)
                               Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: Colors.orange[800]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Probation Period: EL not applicable. 1 day leave/month allowed.",
                                        style: TextStyle(fontSize: 12, color: Colors.orange[800], fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
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
                              final request = history[index];
                              return _buildHistoryItem(request);
                            },
                            childCount: history.length,
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceGrid(LeaveBalance balance) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildBalanceCard(
              title: 'Casual Leave',
              code: 'CL',
              balance: balance.clDisplay,
              color: Colors.blue,
              width: (constraints.maxWidth - 12) / 2,
            ),
            _buildBalanceCard(
              title: 'Sick Leave',
              code: 'SL',
              balance: balance.slDisplay,
              color: Colors.red,
              width: (constraints.maxWidth - 12) / 2,
            ),
            _buildBalanceCard(
              title: 'Earned Leave',
              code: 'EL',
              balance: balance.elDisplay,
              color: Colors.green,
              width: (constraints.maxWidth - 12) / 2,
            ),
            _buildBalanceCard(
              title: 'Comp Off',
              code: 'CO',
              balance: balance.compOffDisplay,
              color: Colors.purple,
              width: (constraints.maxWidth - 12) / 2,
            ),
            _buildBalanceCard(
              title: 'Work From Home',
              code: 'WFH',
              balance: balance.wfhDisplay,
              color: Colors.teal,
              width: (constraints.maxWidth - 12) / 2,
            ),
            if (balance.carryForwardLeave > 0)
              _buildBalanceCard(
                title: 'Carry Forward',
                code: 'CF',
                balance: balance.cfDisplay,
                color: Colors.orange,
                width: (constraints.maxWidth - 12) / 2,
              ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required String code,
    required String balance,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(Icons.pie_chart_outline, color: color.withValues(alpha: 0.5), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            balance,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(LeaveRequest request) {
    Color statusColor;
    String statusText;

    switch (request.status) {
      case LeaveStatus.approved:
        statusColor = Colors.green;
        statusText = 'Approved';
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
          Text(
            request.reason,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
                    '${request.durationInDays} Day${request.durationInDays > 1 ? 's' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ],
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
