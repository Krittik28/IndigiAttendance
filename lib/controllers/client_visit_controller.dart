import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client_visit_model.dart';
import '../models/client_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class ClientVisitController with ChangeNotifier {
  ClientVisit? _ongoingVisit;
  List<ClientVisit> _visitHistory = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, String>? _cachedLocation;

  ClientVisit? get ongoingVisit => _ongoingVisit;
  List<ClientVisit> get visitHistory => _visitHistory;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, String>? get cachedLocation => _cachedLocation;

  static const String _ongoingVisitKey = 'ongoing_client_visit';
  static const String _visitHistoryKey = 'client_visit_history';

  ClientVisitController() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load ongoing visit — but only keep it if it started today.
      // If the employee forgot to checkout yesterday (or earlier), we discard
      // it so they can start a fresh visit today instead of being stuck on an
      // old one.
      final ongoingStr = prefs.getString(_ongoingVisitKey);
      if (ongoingStr != null) {
        final candidate = ClientVisit.fromJson(json.decode(ongoingStr));
        if (_isToday(candidate.checkinTime)) {
          _ongoingVisit = candidate;
        } else {
          // Stale visit from a previous day — clear it from storage
          await prefs.remove(_ongoingVisitKey);
          debugPrint('ClientVisitController: Discarded stale ongoing visit from a previous day (id=${candidate.id})');
        }
      }

      // Load history
      final historyStr = prefs.getString(_visitHistoryKey);
      if (historyStr != null) {
        final List decoded = json.decode(historyStr);
        _visitHistory = decoded.map((item) => ClientVisit.fromJson(item)).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading client visits from prefs: $e');
    }
  }

  Future<void> _saveOngoingToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_ongoingVisit != null) {
      await prefs.setString(_ongoingVisitKey, json.encode(_ongoingVisit!.toJson()));
    } else {
      await prefs.remove(_ongoingVisitKey);
    }
  }

  Future<void> _saveHistoryToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _visitHistory.map((v) => v.toJson()).toList();
    await prefs.setString(_visitHistoryKey, json.encode(list));
  }

  Future<Map<String, String>?> fetchLocationSilent() async {
    try {
      final location = await LocationService.getCurrentLocation();
      _cachedLocation = location;
      return location;
    } catch (e) {
      debugPrint('Failed client visit location fetch: $e');
      return null;
    }
  }

  Future<void> fetchHistory(String employeeCode) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Try to get from API
      final serverHistory = await ApiService.getClientVisitHistory(employeeCode);
      if (serverHistory.isNotEmpty) {
        _visitHistory = serverHistory;
        await _saveHistoryToPrefs();

        // If we don't have a local ongoing visit for TODAY, look for one in
        // the server data. A visit is only considered "ongoing" if:
        //   1. It has no checkout_time (still active), AND
        //   2. Its checkin_time is from today (not a forgotten checkout from a
        //      previous day — those are treated as historical records only).
        if (_ongoingVisit == null) {
          try {
            final activeVisit = serverHistory.firstWhere(
              (v) => v.checkoutTime == null && _isToday(v.checkinTime),
            );
            _ongoingVisit = activeVisit;
            await _saveOngoingToPrefs();
            debugPrint('ClientVisitController: Restored today\'s active visit from server (id=${activeVisit.id})');
          } catch (_) {
            // No active visit for today found on server — that's fine
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch client visit history from server, keeping local: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns true if the given ISO-8601 datetime string represents a time that
  /// falls on today's calendar date (in local time).
  bool _isToday(String dateTimeStr) {
    try {
      final date = DateTime.parse(dateTimeStr).toLocal();
      final now = DateTime.now();
      return date.year == now.year &&
             date.month == now.month &&
             date.day == now.day;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkIn({
    required String employeeCode,
    required Client client,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // 1. Get location
      Map<String, String> locationData;
      try {
        locationData = await LocationService.getCurrentLocation();
        _cachedLocation = locationData;
      } catch (e) {
        _isLoading = false;
        _errorMessage = 'Failed to get location. Location is required for check-in.';
        notifyListeners();
        return false;
      }

      // 2. Call API
      final response = await ApiService.checkInClientVisit(
        employeeCode: employeeCode,
        clientId: client.id,
        clientName: client.customerName,
        latitude: locationData['latitude']!,
        longitude: locationData['longitude']!,
        location: locationData['location']!,
      );

      if (response['status'] == true) {
        final visitJson = response['data'];
        
        // Build ClientVisit
        _ongoingVisit = ClientVisit(
          id: visitJson['id'],
          employeeCode: employeeCode,
          clientId: client.id,
          clientName: client.customerName,
          clientShortName: client.clientShortName,
          checkinTime: visitJson['checkin_time'] ?? DateTime.now().toIso8601String(),
          checkinLatitude: locationData['latitude']!,
          checkinLongitude: locationData['longitude']!,
          checkinLocation: locationData['location']!,
        );

        // Immediately reflect the new active visit in the history list so the
        // recent visits section updates without waiting for a full fetchHistory.
        // Remove any pre-existing entry with the same id first (safety dedup).
        _visitHistory.removeWhere((v) => v.id == _ongoingVisit!.id);
        _visitHistory.insert(0, _ongoingVisit!);
        await _saveHistoryToPrefs();

        await _saveOngoingToPrefs();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Check-in failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOut({
    required String employeeCode,
  }) async {
    if (_ongoingVisit == null) {
      _errorMessage = 'No active client visit found.';
      return false;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // 1. Get location
      Map<String, String> locationData;
      try {
        locationData = await LocationService.getCurrentLocation();
        _cachedLocation = locationData;
      } catch (e) {
        _isLoading = false;
        _errorMessage = 'Failed to get location. Location is required for check-out.';
        notifyListeners();
        return false;
      }

      // 2. Call API
      final response = await ApiService.checkOutClientVisit(
        visitId: _ongoingVisit!.id,
        employeeCode: employeeCode,
        latitude: locationData['latitude']!,
        longitude: locationData['longitude']!,
        location: locationData['location']!,
      );

      if (response['status'] == true) {
        final visitJson = response['data'] ?? {};
        
        // Finalize completed visit
        final completedVisit = ClientVisit(
          id: _ongoingVisit!.id,
          employeeCode: employeeCode,
          clientId: _ongoingVisit!.clientId,
          clientName: _ongoingVisit!.clientName,
          clientShortName: _ongoingVisit!.clientShortName,
          checkinTime: _ongoingVisit!.checkinTime,
          checkinLatitude: _ongoingVisit!.checkinLatitude,
          checkinLongitude: _ongoingVisit!.checkinLongitude,
          checkinLocation: _ongoingVisit!.checkinLocation,
          checkoutTime: visitJson['checkout_time'] ?? DateTime.now().toIso8601String(),
          checkoutLatitude: locationData['latitude']!,
          checkoutLongitude: locationData['longitude']!,
          checkoutLocation: locationData['location']!,
        );

        // Remove the stale entry for this visit that was previously fetched from
        // the server (it existed as "Active" with no checkout_time). Then insert
        // the freshly completed version at the top so the recent list updates
        // instantly without a duplicate.
        _visitHistory.removeWhere((v) => v.id == completedVisit.id);
        _visitHistory.insert(0, completedVisit);
        await _saveHistoryToPrefs();

        // Clear ongoing
        _ongoingVisit = null;
        await _saveOngoingToPrefs();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Check-out failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
