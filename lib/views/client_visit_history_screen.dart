import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/auth_controller.dart';
import '../controllers/client_visit_controller.dart';
import '../models/client_visit_model.dart';
import '../widgets/map_view_dialog.dart';

// ---------------------------------------------------------------------------
// Filter state
// ---------------------------------------------------------------------------

enum _StatusFilter { all, completed, active }

enum _DateFilter { all, thisWeek, thisMonth, lastMonth, custom }

class _FilterState {
  _StatusFilter status = _StatusFilter.all;
  _DateFilter dateRange = _DateFilter.all;
  DateTimeRange? customRange;
  String? clientName; // null = all clients
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ClientVisitHistoryScreen extends StatefulWidget {
  const ClientVisitHistoryScreen({super.key});

  @override
  State<ClientVisitHistoryScreen> createState() =>
      _ClientVisitHistoryScreenState();
}

class _ClientVisitHistoryScreenState extends State<ClientVisitHistoryScreen> {
  final Map<String, bool> _expandedMonths = {};
  final _filterState = _FilterState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshHistory();
    });
  }

  // -------------------------------------------------------------------------
  // Data
  // -------------------------------------------------------------------------

  Future<void> _refreshHistory() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    if (auth.currentUser != null) {
      await Provider.of<ClientVisitController>(
        context,
        listen: false,
      ).fetchHistory(auth.currentUser!.employeeCode);
    }
  }

  List<ClientVisit> _applyFilters(List<ClientVisit> all) {
    return all.where((v) {
      // Status filter
      if (_filterState.status == _StatusFilter.completed &&
          v.checkoutTime == null) {
        return false;
      }
      if (_filterState.status == _StatusFilter.active &&
          v.checkoutTime != null) {
        return false;
      }

      // Client filter
      if (_filterState.clientName != null &&
          v.clientName != _filterState.clientName) {
        return false;
      }

      // Date filter
      if (_filterState.dateRange != _DateFilter.all) {
        final checkin = DateTime.tryParse(v.checkinTime)?.toLocal();
        if (checkin == null) return false;
        final range = _resolvedDateRange();
        if (range != null) {
          final start = DateTime(
            range.start.year,
            range.start.month,
            range.start.day,
          );
          final end = DateTime(
            range.end.year,
            range.end.month,
            range.end.day,
            23,
            59,
            59,
          );
          if (checkin.isBefore(start) || checkin.isAfter(end)) return false;
        }
      }

      return true;
    }).toList();
  }

  DateTimeRange? _resolvedDateRange() {
    final now = DateTime.now();
    switch (_filterState.dateRange) {
      case _DateFilter.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: startOfWeek, end: now);
      case _DateFilter.thisMonth:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case _DateFilter.lastMonth:
        final firstOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final lastOfLastMonth = DateTime(now.year, now.month, 0);
        return DateTimeRange(start: firstOfLastMonth, end: lastOfLastMonth);
      case _DateFilter.custom:
        return _filterState.customRange;
      default:
        return null;
    }
  }

  bool get _hasActiveFilters =>
      _filterState.status != _StatusFilter.all ||
      _filterState.dateRange != _DateFilter.all ||
      _filterState.clientName != null;

  void _clearFilters() => setState(() {
    _filterState.status = _StatusFilter.all;
    _filterState.dateRange = _DateFilter.all;
    _filterState.customRange = null;
    _filterState.clientName = null;
  });

  // -------------------------------------------------------------------------
  // Map
  // -------------------------------------------------------------------------

  Future<void> _openMapLocation(ClientVisit visit) async {
    LatLng? checkinLatLng;
    LatLng? checkoutLatLng;

    try {
      checkinLatLng = LatLng(
        double.parse(visit.checkinLatitude),
        double.parse(visit.checkinLongitude),
      );
    } catch (_) {}

    try {
      if (visit.checkoutLatitude != null && visit.checkoutLongitude != null) {
        checkoutLatLng = LatLng(
          double.parse(visit.checkoutLatitude!),
          double.parse(visit.checkoutLongitude!),
        );
      }
    } catch (_) {}

    if (checkinLatLng == null && checkoutLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid location data available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => MapViewDialog(
        checkinLocation: checkinLatLng,
        checkoutLocation: checkoutLatLng,
        title: (checkinLatLng != null && checkoutLatLng != null)
            ? 'Visit Locations'
            : (checkinLatLng != null
                  ? 'Check-in Location'
                  : 'Check-out Location'),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final visitController = Provider.of<ClientVisitController>(context);
    final allVisits = visitController.visitHistory;
    final filteredVisits = _applyFilters(allVisits);
    final groupedVisits = _groupVisitsByMonth(filteredVisits);
    final stats = _calculateStats(filteredVisits);

    // Unique client names for dropdown
    final clientNames = allVisits.map((v) => v.clientName).toSet().toList()
      ..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Client Visit History',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_hasActiveFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(
                Icons.filter_alt_off_rounded,
                size: 16,
                color: Colors.indigo,
              ),
              label: const Text(
                'Clear',
                style: TextStyle(color: Colors.indigo, fontSize: 13),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        color: Colors.indigo,
        child: visitController.isLoading && allVisits.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: Colors.indigo),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats card
                    _buildStatsCard(stats),
                    const SizedBox(height: 12),

                    // Filter bar
                    _buildFilterBar(clientNames),
                    const SizedBox(height: 16),

                    // Section title
                    Row(
                      children: [
                        const Text(
                          'Past Visits',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_hasActiveFilters)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${filteredVisits.length} result${filteredVisits.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.indigo,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List
                    if (filteredVisits.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: groupedVisits.length,
                        itemBuilder: (context, index) {
                          final entry = groupedVisits.entries.elementAt(index);
                          return _buildMonthSection(entry.key, entry.value);
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Filter bar
  // -------------------------------------------------------------------------

  Widget _buildFilterBar(List<String> clientNames) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Status filter chip
          _FilterChipButton(
            label: _statusLabel(),
            icon: Icons.check_circle_outline_rounded,
            isActive: _filterState.status != _StatusFilter.all,
            onTap: () => _showStatusSheet(),
          ),
          const SizedBox(width: 8),

          // Date filter chip
          _FilterChipButton(
            label: _dateLabel(),
            icon: Icons.calendar_today_rounded,
            isActive: _filterState.dateRange != _DateFilter.all,
            onTap: () => _showDateSheet(),
          ),
          const SizedBox(width: 8),

          // Client filter chip
          _FilterChipButton(
            label: _filterState.clientName ?? 'All Clients',
            icon: Icons.business_rounded,
            isActive: _filterState.clientName != null,
            onTap: () => _showClientSheet(clientNames),
          ),
        ],
      ),
    );
  }

  String _statusLabel() {
    switch (_filterState.status) {
      case _StatusFilter.completed:
        return 'Completed';
      case _StatusFilter.active:
        return 'Active';
      default:
        return 'All Status';
    }
  }

  String _dateLabel() {
    switch (_filterState.dateRange) {
      case _DateFilter.thisWeek:
        return 'This Week';
      case _DateFilter.thisMonth:
        return 'This Month';
      case _DateFilter.lastMonth:
        return 'Last Month';
      case _DateFilter.custom:
        if (_filterState.customRange != null) {
          final s = _filterState.customRange!.start;
          final e = _filterState.customRange!.end;
          return '${s.day}/${s.month} – ${e.day}/${e.month}';
        }
        return 'Custom';
      default:
        return 'All Dates';
    }
  }

  // -------------------------------------------------------------------------
  // Bottom sheets
  // -------------------------------------------------------------------------

  void _showStatusSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BottomSheetPicker(
        title: 'Filter by Status',
        options: const ['All Status', 'Completed', 'Active'],
        selectedIndex: _filterState.status.index,
        onSelect: (i) {
          setState(() {
            _filterState.status = _StatusFilter.values[i];
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDateSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BottomSheetPicker(
        title: 'Filter by Date',
        options: const [
          'All Dates',
          'This Week',
          'This Month',
          'Last Month',
          'Custom Range…',
        ],
        selectedIndex: _filterState.dateRange.index,
        onSelect: (i) async {
          Navigator.pop(context);
          if (i == _DateFilter.custom.index) {
            await _pickCustomRange();
          } else {
            setState(() {
              _filterState.dateRange = _DateFilter.values[i];
              _filterState.customRange = null;
            });
          }
        },
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _filterState.customRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.indigo,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _filterState.dateRange = _DateFilter.custom;
        _filterState.customRange = picked;
      });
    }
  }

  void _showClientSheet(List<String> clientNames) {
    final options = ['All Clients', ...clientNames];
    final selectedIndex = _filterState.clientName == null
        ? 0
        : options.indexOf(_filterState.clientName!);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (_, controller) => _BottomSheetPicker(
          title: 'Filter by Client',
          options: options,
          selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
          scrollController: controller,
          onSelect: (i) {
            setState(() {
              _filterState.clientName = i == 0 ? null : options[i];
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Stats card
  // -------------------------------------------------------------------------

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildStatItem(
              'Total Visits',
              stats['totalCount'].toString(),
              Icons.business_center,
              Colors.indigo,
            ),
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            _buildStatItem(
              'Avg Duration (day)',
              stats['avgDuration'],
              Icons.access_time_filled,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Month sections
  // -------------------------------------------------------------------------

  Widget _buildMonthSection(String monthKey, List<ClientVisit> visits) {
    if (!_expandedMonths.containsKey(monthKey)) {
      _expandedMonths[monthKey] = _expandedMonths.isEmpty;
    }
    final isExpanded = _expandedMonths[monthKey] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.indigo,
            ),
            title: Text(
              _formatMonthKey(monthKey),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${visits.length} visit record${visits.length == 1 ? "" : "s"}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey,
            ),
            onTap: () => setState(() {
              _expandedMonths[monthKey] = !isExpanded;
            }),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            ...visits.map((visit) => _buildVisitItem(visit)),
          ],
        ],
      ),
    );
  }

  Widget _buildVisitItem(ClientVisit visit) {
    final checkinDate = DateTime.tryParse(visit.checkinTime)?.toLocal();
    final checkoutDate = visit.checkoutTime != null
        ? DateTime.tryParse(visit.checkoutTime!)?.toLocal()
        : null;

    final String dayStr = checkinDate != null
        ? checkinDate.day.toString()
        : '--';
    final String monthAbbrStr = checkinDate != null
        ? _getMonthAbbr(checkinDate.month)
        : '---';
    final String dayNameStr = checkinDate != null
        ? _getDayName(checkinDate.weekday)
        : 'Unknown Day';

    String durationStr = 'Ongoing';
    if (checkinDate != null && checkoutDate != null) {
      final diff = checkoutDate.difference(checkinDate);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      durationStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    }

    return InkWell(
      onTap: () => _openMapLocation(visit),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar block
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayStr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  Text(
                    monthAbbrStr,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Middle details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visit.clientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNameStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.login_rounded,
                        size: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        checkinDate != null
                            ? _formatTime(checkinDate)
                            : '--:--',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.logout_rounded,
                        size: 12,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        checkoutDate != null
                            ? _formatTime(checkoutDate)
                            : 'Ongoing',
                        style: TextStyle(
                          fontSize: 11,
                          color: checkoutDate != null
                              ? Colors.black87
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          visit.checkinLocation,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Right status & map icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: checkoutDate != null
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    checkoutDate != null ? 'Completed' : 'Active',
                    style: TextStyle(
                      color: checkoutDate != null
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (checkoutDate != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      durationStr,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.map, size: 16, color: Colors.indigo),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilters
                ? 'No visits match the selected filters'
                : 'No client visit records found',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(
                Icons.filter_alt_off_rounded,
                size: 16,
                color: Colors.indigo,
              ),
              label: const Text(
                'Clear filters',
                style: TextStyle(color: Colors.indigo),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Stats calculation (day-wise average)
  // -------------------------------------------------------------------------

  Map<String, dynamic> _calculateStats(List<ClientVisit> list) {
    final int totalCount = list.length;

    // Group completed visit durations by calendar day
    final Map<String, double> dailyMinutes = {};
    for (var visit in list) {
      if (visit.checkoutTime != null) {
        try {
          final cin = DateTime.parse(visit.checkinTime).toLocal();
          final cout = DateTime.parse(visit.checkoutTime!).toLocal();
          final dayKey =
              '${cin.year}-${cin.month.toString().padLeft(2, '0')}-${cin.day.toString().padLeft(2, '0')}';
          final minutes = cout.difference(cin).inMinutes.toDouble();
          dailyMinutes[dayKey] = (dailyMinutes[dayKey] ?? 0) + minutes;
        } catch (_) {}
      }
    }

    // Average = sum of each day's total / number of days
    String avgStr = '0m';
    if (dailyMinutes.isNotEmpty) {
      final totalMinutes = dailyMinutes.values.fold(0.0, (a, b) => a + b);
      final avgMin = totalMinutes / dailyMinutes.length;
      if (avgMin >= 60) {
        final hr = (avgMin / 60).floor();
        final mn = (avgMin % 60).round();
        avgStr = mn > 0 ? '${hr}h ${mn}m' : '${hr}h';
      } else {
        avgStr = '${avgMin.round()}m';
      }
    }

    return {'totalCount': totalCount, 'avgDuration': avgStr};
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Map<String, List<ClientVisit>> _groupVisitsByMonth(List<ClientVisit> list) {
    final Map<String, List<ClientVisit>> grouped = {};
    for (var visit in list) {
      try {
        final date = DateTime.parse(visit.checkinTime);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []).add(visit);
      } catch (_) {}
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  String _formatMonthKey(String monthKey) {
    try {
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final monthIndex = int.parse(parts[1]);
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[monthIndex - 1]} $year';
    } catch (_) {
      return monthKey;
    }
  }

  String _getMonthAbbr(int month) {
    const list = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return list[month - 1];
  }

  String _getDayName(int weekday) {
    const list = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return list[weekday - 1];
  }

  String _formatTime(DateTime time) {
    final hr = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hr:$min $period';
  }
}

// ---------------------------------------------------------------------------
// Reusable filter chip button
// ---------------------------------------------------------------------------

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.indigo : Colors.grey.shade300,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: isActive ? Colors.white70 : Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable bottom sheet picker
// ---------------------------------------------------------------------------

class _BottomSheetPicker extends StatelessWidget {
  const _BottomSheetPicker({
    required this.title,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
    this.scrollController,
  });

  final String title;
  final List<String> options;
  final int selectedIndex;
  final void Function(int) onSelect;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              controller: scrollController,
              shrinkWrap: scrollController == null,
              itemCount: options.length,
              itemBuilder: (context, i) {
                final isSelected = i == selectedIndex;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.indigo : Colors.grey.shade400,
                    size: 20,
                  ),
                  title: Text(
                    options[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? Colors.indigo : Colors.black87,
                    ),
                  ),
                  onTap: () => onSelect(i),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
