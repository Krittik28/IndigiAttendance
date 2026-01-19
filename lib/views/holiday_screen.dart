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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Holidays',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '2026',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          for (var month in sortedMonths) ...[
            _SliverMonthSection(
              month: month,
              holidays: groupedHolidays[month]!,
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
}

class _SliverMonthSection extends StatelessWidget {
  final int month;
  final List<Holiday> holidays;

  const _SliverMonthSection({
    required this.month,
    required this.holidays,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM').format(DateTime(2026, month));
    final hasToday = holidays.any((h) => DateUtils.isSameDay(h.date, DateTime.now()));

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Month Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text(
                  monthName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: hasToday ? Colors.indigo : Colors.black87,
                  ),
                ),
                if (hasToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.indigo,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Holiday Items
          ...holidays.asMap().entries.map((entry) {
            return _ModernHolidayItem(
              holiday: entry.value,
              index: entry.key,
            );
          }),
        ]),
      ),
    );
  }
}

class _ModernHolidayItem extends StatefulWidget {
  final Holiday holiday;
  final int index;

  const _ModernHolidayItem({
    required this.holiday,
    required this.index,
  });

  @override
  State<_ModernHolidayItem> createState() => _ModernHolidayItemState();
}

class _ModernHolidayItemState extends State<_ModernHolidayItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Staggered delay based on index
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = widget.holiday.date.isBefore(DateTime(now.year, now.month, now.day));
    final isToday = DateUtils.isSameDay(widget.holiday.date, now);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big Date Column
              SizedBox(
                width: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      widget.holiday.date.day.toString(),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isToday
                            ? Colors.indigo
                            : (isPast ? Colors.grey[300] : Colors.red),
                      ),
                    ),
                    Text(
                      DateFormat('EEE').format(widget.holiday.date).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? Colors.indigo.withValues(alpha: 0.7)
                            : (isPast ? Colors.grey[300] : Colors.red.withValues(alpha: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Event Card
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday ? Colors.indigo : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isToday 
                        ? null 
                        : Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: isToday
                            ? Colors.indigo.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: isToday ? 12 : 4,
                        offset: isToday ? const Offset(0, 6) : const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.holiday.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isToday
                                          ? Colors.white
                                          : (isPast ? Colors.grey[400] : Colors.black87),
                                    ),
                                  ),
                                ),
                                if (isToday)
                                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, d MMMM').format(widget.holiday.date),
                              style: TextStyle(
                                fontSize: 13,
                                color: isToday
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}