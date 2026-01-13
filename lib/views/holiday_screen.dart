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
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          for (var month in sortedMonths) ...[
            SliverPersistentHeader(
              pinned: true,
              delegate: _MonthHeaderDelegate(
                month: month,
                hasToday: groupedHolidays[month]!.any(
                  (h) => DateUtils.isSameDay(h.date, DateTime.now()),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final holidays = groupedHolidays[month]!;
                  final holiday = holidays[index];
                  final isLast = index == holidays.length - 1;
                  return _buildHolidayItem(holiday, DateTime.now(), isLast);
                },
                childCount: groupedHolidays[month]!.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ],
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
    for (var key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.date.compareTo(b.date));
    }
    return grouped;
  }

  Widget _buildHolidayItem(Holiday holiday, DateTime now, bool isLast) {
    final isPast = holiday.date.isBefore(DateTime(now.year, now.month, now.day));
    final isToday = DateUtils.isSameDay(holiday.date, now);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: Colors.grey.shade100),
          left: BorderSide(color: Colors.grey.shade100),
          right: BorderSide(color: Colors.grey.shade100),
        ),
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              )
            : null,
      ),
      child: Row(
        children: [
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

class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int month;
  final bool hasToday;

  _MonthHeaderDelegate({required this.month, required this.hasToday});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final monthName = DateFormat('MMMM').format(DateTime(2026, month));
    
    return Container(
      height: maxExtent,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: hasToday ? Colors.indigo.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          if (overlapsContent || shrinkOffset > 0)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
         decoration: BoxDecoration(
            color: hasToday ? Colors.indigo.withValues(alpha: 0.05) : Colors.grey[50],
             borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 60.0;

  @override
  double get minExtent => 60.0;

  @override
  bool shouldRebuild(covariant _MonthHeaderDelegate oldDelegate) {
    return oldDelegate.month != month || oldDelegate.hasToday != hasToday;
  }
}