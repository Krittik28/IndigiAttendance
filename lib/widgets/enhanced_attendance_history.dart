// enhanced_attendance_history.dart
import 'package:flutter/material.dart';
import '../models/attendance_model.dart';

class EnhancedAttendanceHistory extends StatefulWidget {
  final List<Attendance> attendanceList;
  final Future<void> Function()? onRefresh;
  final bool isRefreshing;

  const EnhancedAttendanceHistory({
    super.key,
    required this.attendanceList,
    this.onRefresh,
    this.isRefreshing = false,
  });

  @override
  State<EnhancedAttendanceHistory> createState() => _EnhancedAttendanceHistoryState();
}

class _EnhancedAttendanceHistoryState extends State<EnhancedAttendanceHistory> {
  String _selectedFilter = 'all'; // 'today', 'week', 'month', 'all'
  bool _showOnlyCompleted = false;
  Map<String, bool> _expandedMonths = {};

  @override
  void initState() {
    super.initState();
    // Initialize all months as expanded
    _initializeExpandedStates();
  }

  void _initializeExpandedStates() {
    final grouped = _groupAttendanceByMonth(widget.attendanceList);
    _expandedMonths = {};
    for (var monthKey in grouped.keys) {
      _expandedMonths[monthKey] = true;
    }
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
          
          const SizedBox(height: 16),
          
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
          'Attendance History',
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Days', summary.totalDays.toString(), Icons.calendar_today),
            _buildStatItem('On Time', summary.onTimeDays.toString(), Icons.check_circle),
            _buildStatItem('Present', summary.presentThisMonth.toString(), Icons.work),
            _buildStatItem('Avg Hours', summary.averageHours.toStringAsFixed(1), Icons.access_time),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        // Time Period Filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              icon: const Icon(Icons.arrow_drop_down, size: 16),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              items: const [
                DropdownMenuItem(value: 'today', child: Text('Today')),
                DropdownMenuItem(value: 'week', child: Text('This Week')),
                DropdownMenuItem(value: 'month', child: Text('This Month')),
                DropdownMenuItem(value: 'all', child: Text('All Time')),
              ],
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Completed Only Filter
        FilterChip(
          label: const Text('Completed Only'),
          selected: _showOnlyCompleted,
          onSelected: (value) => setState(() => _showOnlyCompleted = value),
          backgroundColor: Colors.grey[100],
          selectedColor: Colors.blue[100],
          checkmarkColor: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildAttendanceList(Map<String, List<Attendance>> groupedAttendance) {
    if (groupedAttendance.isEmpty) {
      return _buildEmptyState();
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        child: ListView(
          children: [
            for (var monthEntry in groupedAttendance.entries)
              _buildMonthSection(monthEntry.key, monthEntry.value),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSection(String monthKey, List<Attendance> monthAttendance) {
    final isExpanded = _expandedMonths[monthKey] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                ).toList(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(Attendance attendance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
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
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (attendance.checkoutTime != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.logout, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(attendance.checkoutTime!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
                if (attendance.checkinLocation != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    attendance.checkinLocation!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Status Badge
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
        ],
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
            if (_selectedFilter != 'all' || _showOnlyCompleted)
              const SizedBox(height: 8),
            if (_selectedFilter != 'all' || _showOnlyCompleted)
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
      // 'all' - no filtering needed
    }
    
    // Filter by completion status
    if (_showOnlyCompleted) {
      filtered = filtered.where((attendance) => attendance.checkoutTime != null).toList();
    }
    
    return filtered;
  }

  AttendanceSummary _calculateSummary(List<Attendance> attendanceList) {
    final now = DateTime.now();
    final currentMonthAttendance = attendanceList.where((attendance) {
      try {
        final date = DateTime.parse(attendance.checkinTime!);
        return date.year == now.year && date.month == now.month;
      } catch (e) {
        return false;
      }
    }).length;

    // Simple calculation - you can enhance this with actual business logic
    return AttendanceSummary(
      totalDays: attendanceList.length,
      onTimeDays: attendanceList.length - 2, // Example calculation
      lateDays: 2, // Example calculation
      averageHours: 8.5, // Example calculation
      presentThisMonth: currentMonthAttendance,
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