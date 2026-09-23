import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/client_visit_controller.dart';
import '../models/user_model.dart';
import '../models/client_model.dart';
import '../models/client_visit_model.dart';
import '../widgets/client_selection_dialog.dart';
import 'client_visit_history_screen.dart';
import '../theme/app_theme.dart';

class VisitsTab extends StatefulWidget {
  const VisitsTab({super.key});

  @override
  State<VisitsTab> createState() => _VisitsTabState();
}

class _VisitsTabState extends State<VisitsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final clientVisitController = Provider.of<ClientVisitController>(context, listen: false);
      if (auth.currentUser != null) {
        clientVisitController.fetchHistory(auth.currentUser!.employeeCode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final clientVisitController = Provider.of<ClientVisitController>(context);
    final user = authController.currentUser;
    final ongoing = clientVisitController.ongoingVisit;
    final history = clientVisitController.visitHistory;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Client Visits',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.indigo),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ClientVisitHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            await clientVisitController.fetchHistory(user.employeeCode);
          }
        },
        color: Colors.indigo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ongoing != null) ...[
                // Ongoing client visit card
                _buildOngoingVisitCard(clientVisitController, ongoing, user),
              ] else ...[
                // Start a new client visit card
                _buildStartVisitCard(clientVisitController, user),
              ],
              const SizedBox(height: 24),

              // Recent visits log list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Visits',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ClientVisitHistoryScreen()),
                      );
                    },
                    child: const Text('View All', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildVisitsHistoryList(history),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOngoingVisitCard(
    ClientVisitController controller,
    ClientVisit ongoing,
    User? user,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusXL,
        border: Border.all(color: AppTheme.border, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  borderRadius: AppTheme.radiusSM,
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.directions_run_rounded, color: AppTheme.accent, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'ONGOING VISIT',
                      style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              _OngoingVisitTimer(
                checkinTime: ongoing.checkinTime,
                textColor: AppTheme.accent,
                backgroundColor: AppTheme.accent.withValues(alpha: 0.08),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            ongoing.clientName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppTheme.textTertiary, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ongoing.checkinLocation,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_filled_rounded, color: AppTheme.textTertiary, size: 14),
              const SizedBox(width: 6),
              Text(
                'Checked in: ${_formatTime(ongoing.checkinTime)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showClientVisitCheckoutDialog(context, controller, user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMD),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'End Client Visit',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartVisitCard(ClientVisitController controller, User? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business_center_rounded, color: Colors.indigo, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Client Visit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Visits require GPS validation.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _startClientVisitFlow(context, controller, user),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text(
              'Select Client & Punch In',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsHistoryList(List<ClientVisit> history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            'No visit logs recorded yet.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    final recentHistory = history.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentHistory.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final visit = recentHistory[index];
          final dateStr = _formatLogDate(visit.checkinTime);
          final inTime = _formatTime(visit.checkinTime);
          final outTime = visit.checkoutTime != null ? _formatTime(visit.checkoutTime!) : 'Active';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.business_rounded, color: Colors.indigo, size: 20),
            ),
            title: Text(
              visit.clientName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '$dateStr  |  In: $inTime - Out: $outTime',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 10, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'In: ${visit.checkinLocation}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (visit.checkoutLocation != null && visit.checkoutLocation!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Out: ${visit.checkoutLocation}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: visit.checkoutTime != null ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                visit.checkoutTime != null ? 'Completed' : 'Active',
                style: TextStyle(
                  color: visit.checkoutTime != null ? Colors.green[700] : Colors.amber[700],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
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
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final locationData = snapshot.data;
                final location = locationData?['location'] ?? controller.cachedLocation?['location'] ?? 'Unknown Location';
                final isLocationValid = location != 'Unknown Location';

                return AlertDialog(
                  title: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_location_alt_rounded, color: Colors.indigo, size: 28),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Client Visit Punch-In',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Confirm check-in to ${client.customerName}?',
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
                    ],
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: (isLoading || !isLocationValid) ? null : () async {
                        final navigator = Navigator.of(context);
                        navigator.pop(); // Pop confirmation dialog
                        
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.indigo)),
                        );

                        final success = await controller.checkIn(
                          employeeCode: user!.employeeCode,
                          client: client,
                        );

                        navigator.pop(); // Pop loading dialog

                        if (success && context.mounted) {
                          _showSuccessDialog(context, 'Checked in successfully for visit to ${client.customerName}');
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(controller.errorMessage)),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
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
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final locationData = snapshot.data;
                final location = locationData?['location'] ?? controller.cachedLocation?['location'] ?? 'Unknown Location';
                final isLocationValid = location != 'Unknown Location';

                return AlertDialog(
                  title: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.logout_rounded, color: Colors.orange.shade700, size: 28),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Confirm Checkout',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Are you sure you want to end this client visit now?',
                        style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
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
                    ],
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: (isLoading || !isLocationValid) ? null : () async {
                        final navigator = Navigator.of(context);
                        navigator.pop(); // Pop confirmation dialog

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.indigo)),
                        );

                        final success = await controller.checkOut(
                          employeeCode: user!.employeeCode,
                        );

                        navigator.pop(); // Pop loading dialog

                        if (success && context.mounted) {
                          _showSuccessDialog(context, 'Checked out of client site successfully');
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(controller.errorMessage)),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Checkout'),
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

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          radius: 28,
          child: Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 36),
        ),
        title: const Text('Success', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateTime) {
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

  String _formatLogDate(String dateTime) {
    try {
      final date = DateTime.parse(dateTime).toLocal();
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return 'Today';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
        return 'Yesterday';
      }
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    } catch (_) {
      return dateTime;
    }
  }
}

class _OngoingVisitTimer extends StatefulWidget {
  final String checkinTime;
  final Color? textColor;
  final Color? backgroundColor;

  const _OngoingVisitTimer({
    required this.checkinTime,
    this.textColor,
    this.backgroundColor,
  });

  @override
  State<_OngoingVisitTimer> createState() => _OngoingVisitTimerState();
}

class _OngoingVisitTimerState extends State<_OngoingVisitTimer> {
  Timer? _timer;
  String _durationStr = '0m';

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateDuration();
    });
  }

  void _updateDuration() {
    try {
      final checkin = DateTime.parse(widget.checkinTime).toLocal();
      final diff = DateTime.now().difference(checkin);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      
      if (hours > 0) {
        setState(() {
          _durationStr = '${hours}h ${minutes}m';
        });
      } else {
        setState(() {
          _durationStr = '${minutes}m';
        });
      }
    } catch (_) {
      setState(() {
        _durationStr = '0m';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? Colors.white.withValues(alpha: 0.2);
    final txtColor = widget.textColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: widget.backgroundColor != null ? Border.all(color: widget.textColor!.withValues(alpha: 0.15)) : null,
      ),
      child: Text(
        _durationStr,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: txtColor,
        ),
      ),
    );
  }
}
