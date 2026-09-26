import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/holiday_model.dart';
import '../services/api_service.dart';

class HolidayController extends ChangeNotifier {
  static const String _cacheKey = 'cached_holidays_json';
  static const String _cacheYearKey = 'cached_holidays_year';

  List<Holiday> _holidays = [];
  int? _year;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  List<Holiday> get holidays => _holidays;
  int? get year => _year;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  HolidayController() {
    _loadCachedHolidays();
  }

  /// Load cached holidays from SharedPreferences for instant offline display
  Future<void> _loadCachedHolidays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final cachedYear = prefs.getInt(_cacheYearKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = json.decode(cachedJson);
        if (decoded is List) {
          _holidays = decoded
              .map((item) => Holiday.fromJson(item as Map<String, dynamic>))
              .toList();
          _holidays.sort((a, b) => a.date.compareTo(b.date));
          _year = cachedYear ?? (_holidays.isNotEmpty ? _holidays.first.date.year : null);
          _isInitialized = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading cached holidays: $e');
    }
  }

  /// Save holidays to local storage for offline use
  Future<void> _saveHolidaysToCache(List<Holiday> holidays, int? year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(holidays.map((h) => h.toJson()).toList());
      await prefs.setString(_cacheKey, jsonString);
      if (year != null) {
        await prefs.setInt(_cacheYearKey, year);
      }
    } catch (e) {
      debugPrint('Error saving holidays to cache: $e');
    }
  }

  /// Fetch holidays from API
  Future<void> fetchHolidays({bool refresh = false, int? year}) async {
    if (_isLoading) return;

    // If not refreshing and already fetched, skip
    if (!refresh && _holidays.isNotEmpty && _errorMessage == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getHolidays(year: year);
      _holidays = response.data;
      _holidays.sort((a, b) => a.date.compareTo(b.date));
      _year = response.year ?? (year ?? (_holidays.isNotEmpty ? _holidays.first.date.year : DateTime.now().year));
      _isInitialized = true;
      _errorMessage = null;

      // Cache for offline usage
      await _saveHolidaysToCache(_holidays, _year);
    } catch (e) {
      debugPrint('Error fetching holidays: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get holiday for today if exists
  Holiday? getTodayHoliday() {
    final now = DateTime.now();
    try {
      return _holidays.firstWhere(
        (h) => h.date.year == now.year && h.date.month == now.month && h.date.day == now.day,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get upcoming holidays within next [days] days (default 7)
  List<Holiday> getUpcomingHolidays({int days = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.add(Duration(days: days));

    return _holidays.where((h) {
      final hDate = DateTime(h.date.year, h.date.month, h.date.day);
      return hDate.isAfter(today) && hDate.isBefore(limit.add(const Duration(days: 1)));
    }).toList();
  }

  /// Check whether a given DateTime is a holiday
  bool isHoliday(DateTime date) {
    return _holidays.any(
      (h) => h.date.year == date.year && h.date.month == date.month && h.date.day == date.day,
    );
  }

  /// Group holidays by month
  Map<int, List<Holiday>> getGroupedHolidays() {
    final Map<int, List<Holiday>> grouped = {};
    for (var holiday in _holidays) {
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
