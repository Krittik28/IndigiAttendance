import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';
import '../models/user_model.dart';
import '../models/client_model.dart';
import '../models/attendance_model.dart';
import '../theme/app_theme.dart';
import '../widgets/checkin_map_dialog.dart';
import '../widgets/client_selection_dialog.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();
  Timer? _sessionTimer;
  String _activeSessionDuration = '--:--:--';

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    _startSessionTimer();
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
    _clockTimer.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateActiveSessionDuration();
    });
  }

  void _updateActiveSessionDuration() {
    final attController = Provider.of<AttendanceController>(context, listen: false);
    final status = attController.todayStatus;
    if (status != null && status['checkin'] != null && status['checkout'] == null) {
      try {
        final checkinTime = DateTime.parse(status['checkin']).toLocal();
        final diff = DateTime.now().difference(checkinTime);
        final hours = diff.inHours.toString().padLeft(2, '0');
        final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
        if (mounted) {
          setState(() {
            _activeSessionDuration = '$hours:$minutes:$seconds';
          });
        }
      } catch (_) {
        if (mounted) setState(() => _activeSessionDuration = '--:--:--');
      }
    } else {
      if (mounted) setState(() => _activeSessionDuration = '--:--:--');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final attendanceController = Provider.of<AttendanceController>(context);
    final user = authController.currentUser;
    final status = attendanceController.todayStatus;

    final isCheckedIn = status != null && status['checkin'] != null;
    final isCheckedOut = status != null && status['checkout'] != null;

    final String dateString = DateFormat('EEEE, d MMMM yyyy').format(_currentTime);
    final String timeString = DateFormat('hh:mm:ss a').format(_currentTime);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: AppTheme.surface,
        actions: [
          if (attendanceController.cachedLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location_rounded, color: AppTheme.accent),
              onPressed: () => _showLocationDialog(context, attendanceController),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await attendanceController.fetchInitialLocation();
          if (user != null) {
            await attendanceController.fetchTodayStatus(user.employeeCode);
          }
        },
        color: AppTheme.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Clock Card ──────────────────────────────────────────
              _ClockCard(
                dateString: dateString,
                timeString: timeString,
                isCheckedIn: isCheckedIn,
                isCheckedOut: isCheckedOut,
                activeSessionDuration: _activeSessionDuration,
              ),
              const SizedBox(height: 20),

              // ── Location Card ───────────────────────────────────────
              _LocationCard(controller: attendanceController),
              const SizedBox(height: 20),

              // ── Punch Buttons ───────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _PunchButton(
                      label: 'Punch In',
                      icon: Icons.login_rounded,
                      color: AppTheme.success,
                      isEnabled: !isCheckedIn,
                      isLoading: attendanceController.isLoading,
                      onPressed: () {
                        _showCheckInOptionsDialog(context, attendanceController, user, authController);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PunchButton(
                      label: 'Punch Out',
                      icon: Icons.logout_rounded,
                      color: AppTheme.warning,
                      isEnabled: isCheckedIn && !isCheckedOut,
                      isLoading: attendanceController.isLoading,
                      onPressed: () {
                        _showConfirmationDialog(
                          context: context,
                          title: 'Confirm Punch-out',
                          content: 'Are you sure you want to punch out now?',
                          icon: Icons.logout_rounded,
                          iconColor: AppTheme.warning,
                          controller: attendanceController,
                          onConfirm: () async {
                            final message = await attendanceController.checkOut(
                              employeeCode: user!.employeeCode,
                            );
                            if (message != null && context.mounted) {
                              _showSuccessDialog(context, message.isNotEmpty ? message : 'Punch-out Successful!');
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
              const SizedBox(height: 28),

              // ── Today's Logs ────────────────────────────────────────
              const _SectionLabel(title: "Today's Logs"),
              _TodayLogsCard(status: status),

              if (attendanceController.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ErrorBanner(controller: attendanceController),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCheckInOptionsDialog(
    BuildContext context,
    AttendanceController attendanceController,
    User? user,
    AuthController authController,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Check-in Type', style: AppTheme.headingSM),
                const SizedBox(height: 4),
                const Text('Choose where you are punching in from', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 20),
                _OptionTile(
                  icon: Icons.business_rounded,
                  color: AppTheme.accent,
                  title: 'Office Premises',
                  subtitle: 'Verifies you are within the office location range',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _handleIndigiOfficeCheckIn(context, attendanceController, user, authController);
                  },
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.pin_drop_rounded,
                  color: AppTheme.warning,
                  title: 'Client Site',
                  subtitle: 'Check in from a registered client location',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _handleClientSiteCheckIn(context, attendanceController, user, authController);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleIndigiOfficeCheckIn(
    BuildContext context,
    AttendanceController attendanceController,
    User? user,
    AuthController authController,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
    );

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled. Please enable GPS.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Location permissions are denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in Settings.');
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 7),
        );
      }

      const double officeLat = 26.132888;
      const double officeLong = 91.829733;

      double distanceInMeters = Geolocator.distanceBetween(
        officeLat, officeLong, position.latitude, position.longitude,
      );

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => CheckInMapDialog(
            userLocation: LatLng(position!.latitude, position.longitude),
            officeLocation: const LatLng(officeLat, officeLong),
            distance: distanceInMeters,
            isWithinRange: distanceInMeters <= 40,
            onConfirm: () async {
              Navigator.pop(ctx);
              final message = await attendanceController.checkIn(employeeCode: user!.employeeCode);
              if (message != null && context.mounted) {
                _showSuccessDialog(context, message.isNotEmpty ? message : 'Check-in Successful!');
                await authController.refreshAttendanceHistory();
                await attendanceController.fetchTodayStatus(user.employeeCode);
              }
            },
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusMD),
          ),
        );
      }
    }
  }

  void _handleClientSiteCheckIn(
    BuildContext context,
    AttendanceController attendanceController,
    User? user,
    AuthController authController,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ClientSelectionDialog(
        onClientSelected: (Client client) {
          _showConfirmationDialog(
            context: context,
            title: 'Confirm Punch-in',
            content: 'Check in from client site:\n${client.customerName}?',
            icon: Icons.person_pin_circle,
            iconColor: AppTheme.success,
            controller: attendanceController,
            onConfirm: () async {
              final message = await attendanceController.checkInWithClient(
                employeeCode: user!.employeeCode,
                clientId: client.id,
              );
              if (message != null && context.mounted) {
                _showSuccessDialog(context, message.isNotEmpty ? message : 'Check-in Successful!');
                await authController.refreshAttendanceHistory();
                await attendanceController.fetchTodayStatus(user.employeeCode);
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
    required AttendanceController controller,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusXL),
          backgroundColor: AppTheme.surface,
          icon: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: AppTheme.radiusMD,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          title: Text(title, textAlign: TextAlign.center, style: AppTheme.headingSM),
          content: Text(content, textAlign: TextAlign.center, style: AppTheme.bodyMD),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusMD),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusXL),
        backgroundColor: AppTheme.surface,
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.1),
            borderRadius: AppTheme.radiusMD,
          ),
          child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 28),
        ),
        title: const Text('Success', textAlign: TextAlign.center, style: AppTheme.headingSM),
        content: Text(message, textAlign: TextAlign.center, style: AppTheme.bodyMD),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusMD),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context, AttendanceController controller) {
    final location = controller.cachedLocation;
    if (location == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        bool isRefreshing = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final currentLocation = controller.cachedLocation;
            final locationStr = currentLocation?['location'] ?? 'Unknown location';

            return AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusXL),
            backgroundColor: AppTheme.surface,
            title: const Column(
              children: [
                Icon(Icons.location_on_rounded, color: AppTheme.accent, size: 32),
                SizedBox(height: 8),
                Text(
                  'Your Location',
                  style: AppTheme.headingSM,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight,
                    borderRadius: AppTheme.radiusMD,
                  ),
                  child: Text(
                    locationStr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isRefreshing ? null : () async {
                        setDialogState(() => isRefreshing = true);
                        await controller.fetchInitialLocation();
                        if (dialogContext.mounted) {
                          setDialogState(() => isRefreshing = false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.accent),
                        shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusMD),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: isRefreshing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.accent),
                      label: Text(
                        isRefreshing ? 'Refreshing...' : 'Refresh',
                        style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusMD),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        );
      },
    );
  }
}


// ─── Clock Card ─────────────────────────────────────────────────────────────────

class _ClockCard extends StatelessWidget {
  final String dateString;
  final String timeString;
  final bool isCheckedIn;
  final bool isCheckedOut;
  final String activeSessionDuration;

  const _ClockCard({
    required this.dateString,
    required this.timeString,
    required this.isCheckedIn,
    required this.isCheckedOut,
    required this.activeSessionDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusXL,
        border: Border.all(color: AppTheme.border, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            dateString.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            timeString,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (isCheckedIn && !isCheckedOut) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.08),
                borderRadius: AppTheme.radiusSM,
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_rounded, color: AppTheme.accent, size: 14),
                  const SizedBox(width: 8),
                  const Text(
                    'Session Active',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 12,
                    color: AppTheme.accent.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    activeSessionDuration,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Location Card ───────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final AttendanceController controller;
  const _LocationCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final locationData = controller.cachedLocation;
    final bool isFetching = locationData == null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusLG,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isFetching ? AppTheme.surfaceVariant : AppTheme.accentLight,
              borderRadius: AppTheme.radiusSM,
            ),
            child: Icon(
              isFetching ? Icons.location_searching_rounded : Icons.location_on_rounded,
              color: isFetching ? AppTheme.textTertiary : AppTheme.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFetching ? 'Detecting Location...' : 'Current Location',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isFetching
                      ? 'Fetching your location...'
                      : (locationData['location'] ?? 'Unknown location'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isFetching)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
            ),
        ],
      ),
    );
  }
}

// ─── Punch Button ─────────────────────────────────────────────────────────────────

class _PunchButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PunchButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: isEnabled && !isLoading ? onPressed : null,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: isEnabled ? color.withValues(alpha: 0.07) : AppTheme.surfaceVariant,
            borderRadius: AppTheme.radiusXL,
            border: Border.all(
              color: isEnabled ? color.withValues(alpha: 0.25) : AppTheme.border,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled ? color.withValues(alpha: 0.12) : AppTheme.border.withValues(alpha: 0.5),
                  borderRadius: AppTheme.radiusMD,
                ),
                child: isLoading && isEnabled
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Icon(
                        icon,
                        color: isEnabled ? color : AppTheme.textTertiary,
                        size: 24,
                      ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isEnabled ? AppTheme.textPrimary : AppTheme.textTertiary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────────

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

// ─── Today Logs Card ─────────────────────────────────────────────────────────────

class _TodayLogsCard extends StatelessWidget {
  final Map<String, dynamic>? status;
  const _TodayLogsCard({required this.status});

  static String _formatTime(String dateTime) {
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

  @override
  Widget build(BuildContext context) {
    if (status == null || (status!['checkin'] == null && status!['checkout'] == null)) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.radiusXL,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded, size: 40, color: AppTheme.border),
            const SizedBox(height: 12),
            const Text(
              'No attendance logs recorded today',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              'Punch in to start your work session',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final inTime = status!['checkin'] != null ? _formatTime(status!['checkin']) : '--:--';
    final outTime = status!['checkout'] != null ? _formatTime(status!['checkout']) : null;

    String? checkinLoc;
    String? checkoutLoc;
    if (status!['todayEntries'] != null && (status!['todayEntries'] as List).isNotEmpty) {
      final lastEntry = (status!['todayEntries'] as List).last as Attendance;
      checkinLoc = lastEntry.checkinLocation;
      checkoutLoc = lastEntry.checkoutLocation;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusXL,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _LogRow(
            icon: Icons.login_rounded,
            color: AppTheme.success,
            label: 'Punch In',
            time: inTime,
            location: checkinLoc,
            isPresent: status!['checkin'] != null,
            isTopRow: true,
          ),
          const Divider(height: 1, color: AppTheme.border, indent: 20, endIndent: 20),
          _LogRow(
            icon: Icons.logout_rounded,
            color: AppTheme.warning,
            label: 'Punch Out',
            time: outTime ?? 'Active',
            location: checkoutLoc,
            isPresent: status!['checkout'] != null,
            isTopRow: false,
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String time;
  final String? location;
  final bool isPresent;
  final bool isTopRow;

  const _LogRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.time,
    required this.location,
    required this.isPresent,
    required this.isTopRow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isPresent ? color : AppTheme.textTertiary;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, isTopRow ? 20 : 16, 20, isTopRow ? 16 : 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.1),
              borderRadius: AppTheme.radiusSM,
            ),
            child: Icon(icon, color: effectiveColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (location != null && location!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 11, color: AppTheme.textTertiary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location!,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isPresent ? AppTheme.textPrimary : AppTheme.textTertiary,
                  letterSpacing: -0.3,
                ),
              ),
              if (!isPresent)
                const Text(
                  'Pending',
                  style: TextStyle(fontSize: 10, color: AppTheme.textTertiary, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final AttendanceController controller;
  const _ErrorBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              controller.errorMessage,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: controller.clearError,
            child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.error),
          ),
        ],
      ),
    );
  }
}

// ─── Option Tile (for bottom sheet) ─────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
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
          color: AppTheme.surfaceVariant,
          borderRadius: AppTheme.radiusLG,
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppTheme.radiusSM,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}
