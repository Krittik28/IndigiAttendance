import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/holiday_controller.dart';
import '../models/holiday_model.dart';

class HolidayScreen extends StatefulWidget {
  const HolidayScreen({super.key});

  @override
  State<HolidayScreen> createState() => _HolidayScreenState();
}

class _HolidayScreenState extends State<HolidayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final holidayController = Provider.of<HolidayController>(context, listen: false);
      if (holidayController.holidays.isEmpty) {
        holidayController.fetchHolidays();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final holidayController = Provider.of<HolidayController>(context);
    final groupedHolidays = holidayController.getGroupedHolidays();
    final sortedMonths = groupedHolidays.keys.toList()..sort();
    final currentYear = holidayController.year ?? DateTime.now().year;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Holidays',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              currentYear.toString(),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => holidayController.fetchHolidays(refresh: true),
          ),
        ],
      ),
      body: _buildBody(holidayController, groupedHolidays, sortedMonths, currentYear),
    );
  }

  Widget _buildBody(
    HolidayController holidayController,
    Map<int, List<Holiday>> groupedHolidays,
    List<int> sortedMonths,
    int currentYear,
  ) {
    if (holidayController.isLoading && holidayController.holidays.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.indigo),
      );
    }

    if (holidayController.errorMessage != null && holidayController.holidays.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Failed to load holidays',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                holidayController.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => holidayController.fetchHolidays(refresh: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (holidayController.holidays.isEmpty) {
      return RefreshIndicator(
        color: Colors.indigo,
        onRefresh: () => holidayController.fetchHolidays(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No holidays found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.indigo,
      onRefresh: () => holidayController.fetchHolidays(refresh: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          for (var month in sortedMonths) ...[
            _SliverMonthSection(
              year: currentYear,
              month: month,
              holidays: groupedHolidays[month]!,
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _SliverMonthSection extends StatelessWidget {
  final int year;
  final int month;
  final List<Holiday> holidays;

  const _SliverMonthSection({
    required this.year,
    required this.month,
    required this.holidays,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM').format(DateTime(year, month));
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