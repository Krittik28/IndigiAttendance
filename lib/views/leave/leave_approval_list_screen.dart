import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../models/leave_model.dart';
import '../../services/api_service.dart';

class LeaveApprovalListScreen extends StatefulWidget {
  const LeaveApprovalListScreen({super.key});

  @override
  State<LeaveApprovalListScreen> createState() => _LeaveApprovalListScreenState();
}

class _LeaveApprovalListScreenState extends State<LeaveApprovalListScreen> {
  final ScrollController _scrollController = ScrollController();
  List<LeaveRequest> _approvals = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchApprovals(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoading && _hasMore) {
      _fetchApprovals();
    }
  }

  Future<void> _fetchApprovals({bool refresh = false}) async {
    if (_isLoading) return;
    
    final authController = Provider.of<AuthController>(context, listen: false);
    if (authController.currentUser == null) return;

    if (refresh) {
      _page = 1;
      _approvals.clear();
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newApprovals = await ApiService.getLeaveApprovalList(
        authController.currentUser!.employeeCode,
        page: _page,
        perPage: 15,
      );

      if (mounted) {
        setState(() {
          if (newApprovals.isEmpty) {
            _hasMore = false;
          } else {
            _approvals.addAll(newApprovals);
            _page++;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleLeaveAction(int leaveId, String status) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUser = authController.currentUser;
    
    if (currentUser == null) return;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final success = await ApiService.leaveAction(
        leaveId: leaveId,
        empCode: currentUser.employeeCode,
        status: status,
      );
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading indicator

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave request ${status.toLowerCase()} successfully'), backgroundColor: Colors.green),
        );
        _fetchApprovals(refresh: true); // Refresh list
      } else {
        throw Exception('API returned failure status');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading indicator
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _undoLeaveAction(int leaveId) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUser = authController.currentUser;
    
    if (currentUser == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final success = await ApiService.undoLeave(
        leaveId: leaveId,
        empCode: currentUser.employeeCode,
      );
      
      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave action undone successfully'), backgroundColor: Colors.green),
        );
        _fetchApprovals(refresh: true);
      } else {
        throw Exception('API returned failure status');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Leave Approvals',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: RefreshIndicator(
        onRefresh: () async { await _fetchApprovals(refresh: true); },
        child: _approvals.isEmpty && !_isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'You\'re all caught up!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No pending leave approvals waiting for you.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _approvals.length + (_isLoading || _hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _approvals.length) {
                    return _isLoading
                        ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                        : const SizedBox.shrink();
                  }
                  return _buildApprovalCard(_approvals[index]);
                },
              ),
      ),
    );
  }

  Widget _buildApprovalCard(LeaveRequest request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                  child: Text(
                    request.employeeName != null && request.employeeName!.isNotEmpty
                        ? request.employeeName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.employeeName ?? 'Unknown Employee',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Emp Code: ${request.employeeCode ?? "N/A"}',
                        style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(request.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(request.status).withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _getStatusName(request.status).toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(request.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getLeaveTypeName(request.type),
                        style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1.5, color: Color(0xFFEEEEEE)),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Duration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                          const SizedBox(height: 6),
                          Text(
                            '${DateFormat('MMM d, yyyy').format(request.startDate)} -\n${DateFormat('MMM d, yyyy').format(request.endDate)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                          const SizedBox(height: 6),
                          Text(
                            request.noOfDays.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                const Text('Reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                const SizedBox(height: 6),
                Text(
                  request.reason.isNotEmpty ? request.reason : 'No reason provided.',
                  style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                ),
                
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Reporting Manager', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: Colors.indigo),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request.rmName ?? 'Not Assigned',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Project Manager', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: Colors.indigo),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request.pmName ?? 'Not Assigned',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (request.status == LeaveStatus.rejected && request.rejectionReason != null && request.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rejection Reason: ${request.rejectionReason}',
                            style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (request.leaveBalance != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            _buildRequestedBalanceItem(request),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _showAllBalancesModal(context, request.leaveBalance!, request.employeeName ?? 'Employee'),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('View All', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.indigo,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Action Buttons Section
          Builder(
            builder: (context) {
              bool isActionEnabled = true;

              if (request.status == LeaveStatus.approved || request.status == LeaveStatus.rejected || request.status == LeaveStatus.pmApproved || request.status == LeaveStatus.cancelled) {
                isActionEnabled = false;
              } else if (request.approverType == 'rm' && (request.status == LeaveStatus.rmApproved || request.status == LeaveStatus.pmApproved)) {
                isActionEnabled = false;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    if (!isActionEnabled && request.approverType == 'pm') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _undoLeaveAction(request.id),
                          icon: const Icon(Icons.undo, size: 20),
                          label: const Text('Undo Decision', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[800],
                            side: BorderSide(color: Colors.orange[400]!, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isActionEnabled ? () => _handleLeaveAction(request.id, 'rejected') : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isActionEnabled ? Colors.red : Colors.grey,
                            side: BorderSide(color: isActionEnabled ? Colors.red[300]! : Colors.grey[300]!, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isActionEnabled ? () => _handleLeaveAction(request.id, 'approved') : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActionEnabled ? Colors.green[600] : Colors.grey[300],
                            foregroundColor: isActionEnabled ? Colors.white : Colors.grey[600],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey,
                          ),
                          child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildRequestedBalanceItem(LeaveRequest request) {
    String label = _getLeaveTypeShortName(request.type);
    String value = _getLeaveTypeValue(request.type, request.leaveBalance!);
    
    return Row(
      children: [
        Text('$label Balance: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  void _showAllBalancesModal(BuildContext context, LeaveBalance balance, String employeeName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$employeeName\'s Balances',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _buildModalBalanceRow('Casual Leave (CL)', balance.clDisplay),
                      _buildModalBalanceRow('Sick Leave (SL)', balance.slDisplay),
                      _buildModalBalanceRow('Earned Leave (EL)', balance.elDisplay),
                      _buildModalBalanceRow('Comp-Off', balance.compOff.toStringAsFixed(1)),
                      _buildModalBalanceRow('Carry Forward', balance.cfDisplay),
                      _buildModalBalanceRow('Work From Home', balance.wfhDisplay),
                      _buildModalBalanceRow('Happiness Leave', balance.hplDisplay),
                      _buildModalBalanceRow('Paternity Leave', balance.ptlDisplay),
                      _buildModalBalanceRow('Maternity Leave', balance.mtlDisplay),
                      _buildModalBalanceRow('Marriage Leave', balance.mrlDisplay),
                      _buildModalBalanceRow('Bereavement Leave', balance.brlDisplay),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalBalanceRow(String label, String value) {
    // Only show if the value is not "0.0" or "0"
    if (value == '0.0' || value == '0') return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ),
        ],
      ),
    );
  }

  String _getLeaveTypeShortName(LeaveType type) {
    switch (type) {
      case LeaveType.sickLeave: return 'SL';
      case LeaveType.casualLeave: return 'CL';
      case LeaveType.earnedLeave: return 'EL';
      case LeaveType.carryForwardLeave: return 'CF';
      case LeaveType.compOff: return 'CO';
      default: return 'Leave';
    }
  }

  String _getLeaveTypeValue(LeaveType type, LeaveBalance balance) {
    switch (type) {
      case LeaveType.sickLeave: return balance.slDisplay;
      case LeaveType.casualLeave: return balance.clDisplay;
      case LeaveType.earnedLeave: return balance.elDisplay;
      case LeaveType.carryForwardLeave: return balance.cfDisplay;
      case LeaveType.workFromHome: return balance.wfhDisplay;
      case LeaveType.happinessLeave: return balance.hplDisplay;
      case LeaveType.paternityLeave: return balance.ptlDisplay;
      case LeaveType.maternityLeave: return balance.mtlDisplay;
      case LeaveType.marriageLeave: return balance.mrlDisplay;
      case LeaveType.bereavementLeave: return balance.brlDisplay;
      case LeaveType.compOff: return balance.compOff.toStringAsFixed(1);
      default: return '-';
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

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
      case LeaveStatus.applied:
        return Colors.blue;
      case LeaveStatus.approved:
      case LeaveStatus.rmApproved:
      case LeaveStatus.pmApproved:
        return Colors.green;
      case LeaveStatus.rejected:
        return Colors.red;
      case LeaveStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusName(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending: return 'Pending';
      case LeaveStatus.applied: return 'Applied';
      case LeaveStatus.approved: return 'Approved';
      case LeaveStatus.rejected: return 'Rejected';
      case LeaveStatus.cancelled: return 'Cancelled';
      case LeaveStatus.rmApproved: return 'RM Approved';
      case LeaveStatus.pmApproved: return 'Final Approved';
    }
  }
}
