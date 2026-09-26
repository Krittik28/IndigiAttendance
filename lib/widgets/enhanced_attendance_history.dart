// enhanced_attendance_history.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/attendance_model.dart';
import 'map_view_dialog.dart';

class EnhancedAttendanceHistory extends StatefulWidget {
  final List<Attendance> attendanceList;
  final Future<void> Function()? onRefresh;
  final bool isRefreshing;
  final DateTime? initialFocusDate;

  const EnhancedAttendanceHistory({
    super.key,
    required this.attendanceList,
    this.onRefresh,
    this.isRefreshing = false,
    this.initialFocusDate,
  });

  @override
  State<EnhancedAttendanceHistory> createState() => _EnhancedAttendanceHistoryState();
}

class _EnhancedAttendanceHistoryState extends State<EnhancedAttendanceHistory> {
  String _selectedFilter = 'all'; // 'today', 'week', 'month', 'custom', 'all'
  DateTimeRange? _selectedDateRange;
  String _selectedStatus = 'all'; // 'all', 'completed', 'pending'
  final Map<String, bool> _expandedMonths = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialFocusDate != null) {
      _selectedFilter = 'custom';
      final date = widget.initialFocusDate!;
      
      // Set range to the whole month of the focused date
      final startOfMonth = DateTime(date.year, date.month, 1);
      final endOfMonth = DateTime(date.year, date.month + 1, 0); // Last day of month
      
      _selectedDateRange = DateTimeRange(start: startOfMonth, end: endOfMonth);
      
      final monthKey = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      _expandedMonths[monthKey] = true;
    }
  }

 Future<void> _selectDateRange() async {
  final DateTimeRange? picked = await showDialog<DateTimeRange>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          width: 500,   // ✅ Fixed width
          height: 600,  // ✅ Fixed height
          child: Theme(
            data: Theme.of(context).copyWith(
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              colorScheme: const ColorScheme.light(
                primary: Colors.blue,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            child: DateRangePickerDialog(
              helpText: 'Select Start and End Date',
              saveText: 'APPLY',
              cancelText: 'CANCEL',
              initialEntryMode: DatePickerEntryMode.calendar,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: _selectedDateRange ??
                  DateTimeRange(
                    start: DateTime.now().subtract(const Duration(days: 7)),
                    end: DateTime.now(),
                  ),
            ),
          ),
        ),
      );
    },
  );

  // ✅ Handle result
  if (picked != null) {
    setState(() {
      _selectedDateRange = picked;
      _selectedFilter = 'custom';
    });
  } else if (_selectedFilter == 'custom' && _selectedDateRange == null) {
    setState(() {
      _selectedFilter = 'all';
    });
  }
}

  Future<void> _openMapLocation(Attendance attendance) async {
    LatLng? checkinLatLng;
    LatLng? checkoutLatLng;

    try {
      if (attendance.checkinLatitude != null && attendance.checkinLongitude != null) {
        checkinLatLng = LatLng(
          double.parse(attendance.checkinLatitude!),
          double.parse(attendance.checkinLongitude!),
        );
      }
    } catch (e) {
      // Invalid checkin coordinates
    }

    try {
      if (attendance.checkoutLatitude != null && attendance.checkoutLongitude != null) {
        checkoutLatLng = LatLng(
          double.parse(attendance.checkoutLatitude!),
          double.parse(attendance.checkoutLongitude!),
        );
      }
    } catch (e) {
      // Invalid checkout coordinates
    }

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
            ? 'Attendance Locations' 
            : (checkinLatLng != null ? 'Check-in Location' : 'Check-out Location'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAttendance = _filterAttendance(widget.attendanceList);
    final groupedAttendance = _groupAttendanceByMonth(filteredAttendance);
    final summary = _calculateSummary(filteredAttendance);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Refresh
          _buildHeader(),
          
          // const SizedBox(height: 16),
          
          // Statistics Card
          _buildStatisticsCard(summary),
          
          const SizedBox(height: 16),
          
          // Filter Row
          _buildFilterRow(),
          
          const SizedBox(height: 16),
          
          // Attendance List
          _buildAttendanceList(groupedAttendance),
        ],
      ),
    );
  }


  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (widget.isRefreshing)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (widget.onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: widget.onRefresh,
            tooltip: 'Refresh',
          ),
      ],
    );
  }

  Widget _buildStatisticsCard(AttendanceSummary summary) {
    return Card(
      elevation: 0.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildStatItem('Total Days', summary.totalDays.toString(), Icons.calendar_today),
            const SizedBox(width: 12),
            _buildStatItem('Avg Hours', summary.averageHours.toStringAsFixed(1), Icons.access_time),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue[50]!.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateShort(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  void _showTimePeriodSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BottomSheetPicker(
        title: 'Select Time Period',
        options: const [
          'All Time',
          'Today',
          'This Week',
          'This Month',
          'Custom Range...',
        ],
        selectedIndex: _selectedFilter == 'all'
            ? 0
            : _selectedFilter == 'today'
                ? 1
                : _selectedFilter == 'week'
                    ? 2
                    : _selectedFilter == 'month'
                        ? 3
                        : 4,
        onSelect: (index) async {
          Navigator.pop(context);
          if (index == 4) {
            await _selectDateRange();
          } else {
            setState(() {
              _selectedFilter = index == 0
                  ? 'all'
                  : index == 1
                      ? 'today'
                      : index == 2
                          ? 'week'
                          : 'month';
              _selectedDateRange = null;
            });
          }
        },
      ),
    );
  }

  void _showStatusSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BottomSheetPicker(
        title: 'Select Status',
        options: const [
          'All Statuses',
          'Completed Only',
          'Pending Only',
        ],
        selectedIndex: _selectedStatus == 'all'
            ? 0
            : _selectedStatus == 'completed'
                ? 1
                : 2,
        onSelect: (index) {
          setState(() {
            _selectedStatus = index == 0
                ? 'all'
                : index == 1
                    ? 'completed'
                    : 'pending';
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildFilterRow() {
    final bool hasActiveFilters = _selectedFilter != 'all' || _selectedStatus != 'all';

    String periodLabel = 'All Time';
    if (_selectedFilter == 'today') periodLabel = 'Today';
    if (_selectedFilter == 'week') periodLabel = 'This Week';
    if (_selectedFilter == 'month') periodLabel = 'This Month';
    if (_selectedFilter == 'custom') {
      if (_selectedDateRange != null) {
        periodLabel = '${_formatDateShort(_selectedDateRange!.start)} - ${_formatDateShort(_selectedDateRange!.end)}';
      } else {
        periodLabel = 'Custom Range';
      }
    }

    String statusLabel = 'All Statuses';
    if (_selectedStatus == 'completed') statusLabel = 'Completed';
    if (_selectedStatus == 'pending') statusLabel = 'Pending';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipButton(
            label: periodLabel,
            icon: Icons.calendar_today_rounded,
            isActive: _selectedFilter != 'all',
            onTap: _showTimePeriodSheet,
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            label: statusLabel,
            icon: Icons.check_circle_outline_rounded,
            isActive: _selectedStatus != 'all',
            onTap: _showStatusSheet,
          ),
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            _FilterChipButton(
              label: 'Clear',
              icon: Icons.filter_alt_off_rounded,
              isActive: true,
              hasDropdown: false,
              onTap: () {
                setState(() {
                  _selectedFilter = 'all';
                  _selectedStatus = 'all';
                  _selectedDateRange = null;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceList(Map<String, List<Attendance>> groupedAttendance) {
    if (groupedAttendance.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedAttendance.length,
      itemBuilder: (context, index) {
        final entry = groupedAttendance.entries.elementAt(index);
        return _buildMonthSection(entry.key, entry.value);
      },
    );
  }

  Widget _buildMonthSection(String monthKey, List<Attendance> monthAttendance) {
    final isExpanded = _expandedMonths[monthKey] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Month Header
          ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.blue),
            title: Text(
              _formatMonthKey(monthKey),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${monthAttendance.length} attendance records'),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey,
            ),
            onTap: () => setState(() {
              _expandedMonths[monthKey] = !isExpanded;
            }),
          ),
          
          // Month Attendance List
          if (isExpanded)
            Column(
              children: [
                const Divider(height: 1),
                ...monthAttendance.map((attendance) => 
                  _buildAttendanceItem(attendance)
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(Attendance attendance) {
    return InkWell(
      onTap: () => _openMapLocation(attendance),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayFromDate(attendance.checkinTime ?? ''),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    _getMonthAbbrFromDate(attendance.checkinTime ?? ''),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Attendance Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDayName(attendance.checkinTime ?? ''),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.login, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(attendance.checkinTime ?? ''),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      if (attendance.checkoutTime != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.logout, size: 12, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(attendance.checkoutTime!),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                  if (attendance.checkinLocation != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 10, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            attendance.checkinLocation!,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold),
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
            
            // Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: attendance.checkoutTime != null ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    attendance.checkoutTime != null ? 'Completed' : 'Pending',
                    style: TextStyle(
                      color: attendance.checkoutTime != null ? Colors.green : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (attendance.checkinLatitude != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Icon(Icons.map, size: 20, color: Colors.blue[300]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No attendance records found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            if (_selectedFilter != 'all' || _selectedStatus != 'all')
              const SizedBox(height: 8),
            if (_selectedFilter != 'all' || _selectedStatus != 'all')
              Text(
                'Try changing your filters',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  Map<String, List<Attendance>> _groupAttendanceByMonth(List<Attendance> attendanceList) {
    Map<String, List<Attendance>> grouped = {};
    
    for (var attendance in attendanceList) {
      try {
        final date = DateTime.parse(attendance.checkinTime!);
        final monthKey = "${date.year}-${date.month.toString().padLeft(2, '0')}";
        
        if (!grouped.containsKey(monthKey)) {
          grouped[monthKey] = [];
        }
        grouped[monthKey]!.add(attendance);
      } catch (e) {
        // Skip invalid dates
      }
    }
    
    // Sort months descending (newest first)
    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key))
    );
  }

  List<Attendance> _filterAttendance(List<Attendance> attendanceList) {
    List<Attendance> filtered = attendanceList;
    
    // Filter by time period
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'today':
        filtered = filtered.where((attendance) {
          try {
            final date = DateTime.parse(attendance.checkinTime!);
            return date.year == now.year && date.month == now.month && date.day == now.day;
          } catch (e) {
            return false;
          }
        }).toList();
        break;
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        filtered = filtered.where((attendance) {
          try {
            final date = DateTime.parse(attendance.checkinTime!);
            return date.isAfter(startOfWeek);
          } catch (e) {
            return false;
          }
        }).toList();
        break;
      case 'month':
        filtered = filtered.where((attendance) {
          try {
            final date = DateTime.parse(attendance.checkinTime!);
            return date.year == now.year && date.month == now.month;
          } catch (e) {
            return false;
          }
        }).toList();
        break;
      case 'custom':
        if (_selectedDateRange != null) {
          filtered = filtered.where((attendance) {
            try {
              final date = DateTime.parse(attendance.checkinTime!);
              // Include the end date fully by adding one day to end or comparing carefully
              return date.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) && 
                     date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();
        }
        break;
      // 'all' - no filtering needed
    }
    
    // Filter by completion status
    if (_selectedStatus == 'completed') {
      filtered = filtered.where((attendance) => attendance.checkoutTime != null).toList();
    } else if (_selectedStatus == 'pending') {
      filtered = filtered.where((attendance) => attendance.checkoutTime == null).toList();
    }
    
    return filtered;
  }

  AttendanceSummary _calculateSummary(List<Attendance> attendanceList) {
    final now = DateTime.now();
    
    // Track unique days
    final Set<String> uniqueDays = {};
    final Set<String> uniqueDaysWithCompletion = {};
    final Set<String> uniqueDaysThisMonth = {};
    
    double totalHours = 0;

    for (var attendance in attendanceList) {
      try {
        if (attendance.checkinTime == null) continue;

        final checkin = DateTime.parse(attendance.checkinTime!);
        final dateKey = "${checkin.year}-${checkin.month}-${checkin.day}";
        
        // Track unique days present
        uniqueDays.add(dateKey);

        // Count for current month (unique days)
        if (checkin.year == now.year && checkin.month == now.month) {
          uniqueDaysThisMonth.add(dateKey);
        }

        // Calculate hours if both checkin and checkout exist
        if (attendance.checkoutTime != null) {
          final checkout = DateTime.parse(attendance.checkoutTime!);
          final difference = checkout.difference(checkin);
          totalHours += difference.inMinutes / 60.0;
          
          // Mark this day as having a completed session for avg calc
          uniqueDaysWithCompletion.add(dateKey);
        }
      } catch (e) {
        // Skip invalid records
      }
    }

    // Calculate average based on days that actually have accumulated hours
    double averageHours = uniqueDaysWithCompletion.isNotEmpty 
        ? totalHours / uniqueDaysWithCompletion.length 
        : 0.0;

    return AttendanceSummary(
      totalDays: uniqueDays.length,
      onTimeDays: 0, // Not relevant for now
      lateDays: 0, // Not relevant for now
      averageHours: averageHours,
      presentThisMonth: uniqueDaysThisMonth.length,
    );
  }

  String _formatMonthKey(String monthKey) {
    try {
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${monthNames[month - 1]} $year';
    } catch (e) {
      return monthKey;
    }
  }

  String _getDayFromDate(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return date.day.toString();
    } catch (e) {
      return '--';
    }
  }

  String _getMonthAbbrFromDate(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[date.month - 1];
    } catch (e) {
      return '---';
    }
  }

  String _getDayName(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    } catch (e) {
      return 'Unknown Day';
    }
  }

  String _formatTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      final hour = date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour < 12 ? 'AM' : 'PM';
      return '${hour == 0 ? 12 : hour}:$minute $period';
    } catch (e) {
      return dateTime;
    }
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
    this.hasDropdown = true,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final bool hasDropdown;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.blue[800] : Colors.black87,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 16,
                color: isActive ? Colors.blue : Colors.grey[500],
              ),
            ],
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
  });

  final String title;
  final List<String> options;
  final int selectedIndex;
  final void Function(int) onSelect;

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
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, i) {
                final isSelected = i == selectedIndex;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.blue : Colors.grey.shade400,
                    size: 20,
                  ),
                  title: Text(
                    options[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.blue : Colors.black87,
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
