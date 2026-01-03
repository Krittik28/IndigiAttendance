import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/holiday_model.dart';

class HolidayScreen extends StatelessWidget {
  const HolidayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groupedHolidays = _groupHolidaysByMonth(holidayList2026);
    final sortedMonths = groupedHolidays.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Holiday List 2026',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedMonths.length,
        itemBuilder: (context, index) {
          final month = sortedMonths[index];
          final holidays = groupedHolidays[month]!;
          return _buildMonthCard(month, holidays);
        },
      ),
    );
  }

  Map<int, List<Holiday>> _groupHolidaysByMonth(List<Holiday> holidays) {
    final Map<int, List<Holiday>> grouped = {};
    for (var holiday in holidays) {
      if (!grouped.containsKey(holiday.date.month)) {
        grouped[holiday.date.month] = [];
      }
      grouped[holiday.date.month]!.add(holiday);
    }
    // Sort holidays within each month just in case
    for (var key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.date.compareTo(b.date));
    }
    return grouped;
  }

  Widget _buildMonthCard(int month, List<Holiday> holidays) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(DateTime(2026, month));
    
    // Check if any holiday in this month is today (for potentially highlighting the month)
    final hasToday = holidays.any((h) => DateUtils.isSameDay(h.date, now));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: hasToday ? Border.all(color: Colors.indigo.withValues(alpha: 0.3), width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: hasToday ? Colors.indigo.withValues(alpha: 0.05) : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: hasToday ? Colors.indigo : Colors.grey[600],
                ),
                const SizedBox(width: 10),
                Text(
                  monthName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasToday ? Colors.indigo : Colors.black87,
                  ),
                ),
                const Spacer(),
                if (hasToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          
          // Holidays List
          ...holidays.map((holiday) => _buildHolidayItem(holiday, now)).toList(),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHolidayItem(Holiday holiday, DateTime now) {
    final isPast = holiday.date.isBefore(DateTime(now.year, now.month, now.day));
    final isToday = DateUtils.isSameDay(holiday.date, now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isToday ? Colors.indigo.withValues(alpha: 0.05) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          // Date Box
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isToday 
                  ? Colors.indigo 
                  : (isPast ? Colors.grey[100] : Colors.red[50]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  holiday.date.day.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isToday 
                        ? Colors.white 
                        : (isPast ? Colors.grey[400] : Colors.red),
                  ),
                ),
                Text(
                  DateFormat('EEE').format(holiday.date).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isToday 
                        ? Colors.white.withValues(alpha: 0.8) 
                        : (isPast ? Colors.grey[400] : Colors.red.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Holiday Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isPast ? Colors.grey[400] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM y').format(holiday.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isToday 
                        ? Colors.indigo 
                        : (isPast ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          
          if (isToday)
            const Icon(Icons.celebration, color: Colors.indigo, size: 20),
        ],
      ),
    );
  }
}