import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../models/attendance_model.dart';

class AttendanceController with ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  Attendance? _currentAttendance;
  Map<String, dynamic>? _currentProcessingData;
  Map<String, String>? _cachedLocation;
  bool _isFetchingLocation = false;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Attendance? get currentAttendance => _currentAttendance;
  Map<String, dynamic>? get currentProcessingData => _currentProcessingData;
  Map<String, String>? get cachedLocation => _cachedLocation;
  bool get isFetchingLocation => _isFetchingLocation;

  Future<Map<String, String>?> fetchLocationSilent() async {
    try {
      debugPrint('📍 Silently fetching location...');
      final location = await LocationService.getCurrentLocation();
      _cachedLocation = location;
      // We don't notifyListeners here to avoid rebuilding during a build phase
      // The dialog will handle the display of this specific fetch
      return location;
    } catch (e) {
      debugPrint('⚠️ Failed to fetch silent location: $e');
      return null;
    }
  }

  Future<void> fetchInitialLocation() async {
    _isFetchingLocation = true;
    notifyListeners();
    
    try {
      debugPrint('📍 Fetching initial location for dashboard...');
      _cachedLocation = await LocationService.getCurrentLocation();
      debugPrint('📍 Initial location fetched: ${_cachedLocation!['location']}');
    } catch (e) {
      debugPrint('⚠️ Failed to fetch initial location: $e');
    } finally {
      _isFetchingLocation = false;
      notifyListeners();
    }
  }

  Future<String?> checkIn({required String employeeCode}) async {
    _isLoading = true;
    _errorMessage = '';
    _currentProcessingData = null;
    notifyListeners();

    try {
      Map<String, String> locationData;
      try {
        locationData = await LocationService.getCurrentLocation();
        // Update cache with successful fetch
        _cachedLocation = locationData;
      } catch (e) {
        debugPrint('⚠️ Live location fetch failed during check-in: $e');
        if (_cachedLocation != null) {
          debugPrint('ℹ️ Using cached location: ${_cachedLocation!['location']}');
          locationData = _cachedLocation!;
        } else {
          // Try one last time to get *any* location or fail
          debugPrint('⚠️ No cached location available. Retrying one last time...');
          locationData = await LocationService.getCurrentLocation();
        }
      }
      
      // Set current processing data
      _currentProcessingData = {
        'type': 'checkin',
        'time': DateTime.now(),
        'location': locationData['location'],
        'coordinates': '${locationData['latitude']}, ${locationData['longitude']}',
      };
      notifyListeners();

      debugPrint('=== CHECK-IN DEBUG INFO ===');
      debugPrint('Employee Code: $employeeCode');
      debugPrint('Location: ${locationData['location']}');
      debugPrint('Coordinates: ${locationData['latitude']}, ${locationData['longitude']}');
      debugPrint('==========================');

      final response = await ApiService.checkIn(
        employeeCode: employeeCode,
        latitude: locationData['latitude']!,
        longitude: locationData['longitude']!,
        location: locationData['location']!,
      );

      if (response.status) {
        _currentAttendance = response.data;
        _isLoading = false;
        _errorMessage = '';
        _currentProcessingData = null;
        
        // Refresh today's status to update the dashboard UI
        await fetchTodayStatus(employeeCode);
        
        notifyListeners();
        
        debugPrint('✅ Check-in successful!');
        return (response.warningMessage != null && response.warningMessage!.isNotEmpty)
            ? response.warningMessage
            : response.message;
      } else {
        _errorMessage = _getUserFriendlyErrorMessage(response.message, 'checkin');
        _isLoading = false;
        _currentProcessingData = null;
        notifyListeners();
        
        debugPrint('❌ Check-in failed: ${response.message}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Check-in exception: $e');
      
      _errorMessage = _getUserFriendlyErrorMessage(e.toString(), 'checkin');
      _isLoading = false;
      _currentProcessingData = null;
      notifyListeners();
      return null;
    }
  }

  Future<String?> checkInWithClient({
    required String employeeCode,
    required int clientId,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    _currentProcessingData = null;
    notifyListeners();

    try {
      Map<String, String> locationData;
      try {
        locationData = await LocationService.getCurrentLocation();
        // Update cache with successful fetch
        _cachedLocation = locationData;
      } catch (e) {
        debugPrint('⚠️ Live location fetch failed during client check-in: $e');
        if (_cachedLocation != null) {
          debugPrint('ℹ️ Using cached location: ${_cachedLocation!['location']}');
          locationData = _cachedLocation!;
        } else {
          // Try one last time to get *any* location or fail
          debugPrint('⚠️ No cached location available. Retrying one last time...');
          locationData = await LocationService.getCurrentLocation();
        }
      }
      
      // Set current processing data
      _currentProcessingData = {
        'type': 'checkin',
        'time': DateTime.now(),
        'location': locationData['location'],
        'coordinates': '${locationData['latitude']}, ${locationData['longitude']}',
      };
      notifyListeners();

      debugPrint('=== CLIENT CHECK-IN DEBUG INFO ===');
      debugPrint('Employee Code: $employeeCode');
      debugPrint('Client ID: $clientId');
      debugPrint('Location: ${locationData['location']}');
      debugPrint('Coordinates: ${locationData['latitude']}, ${locationData['longitude']}');
      debugPrint('=================================');

      final response = await ApiService.checkInWithClient(
        employeeCode: employeeCode,
        latitude: locationData['latitude']!,
        longitude: locationData['longitude']!,
        location: locationData['location']!,
        clientId: clientId,
      );

      if (response.status) {
        _currentAttendance = response.data;
        _isLoading = false;
        _errorMessage = '';
        _currentProcessingData = null;
        
        // Refresh today's status to update the dashboard UI
        await fetchTodayStatus(employeeCode);
        
        notifyListeners();
        
        debugPrint('✅ Client Check-in successful!');
        return (response.warningMessage != null && response.warningMessage!.isNotEmpty)
            ? response.warningMessage
            : response.message;
      } else {
        _errorMessage = _getUserFriendlyErrorMessage(response.message, 'checkin');
        _isLoading = false;
        _currentProcessingData = null;
        notifyListeners();
        
        debugPrint('❌ Client Check-in failed: ${response.message}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Client Check-in exception: $e');
      
      _errorMessage = _getUserFriendlyErrorMessage(e.toString(), 'checkin');
      _isLoading = false;
      _currentProcessingData = null;
      notifyListeners();
      return null;
    }
  }

  Future<String?> checkOut({required String employeeCode}) async {
    _isLoading = true;
    _errorMessage = '';
    _currentProcessingData = null;
    notifyListeners();

    try {
      Map<String, String> locationData;
      try {
        locationData = await LocationService.getCurrentLocation();
        // Update cache with successful fetch
        _cachedLocation = locationData;
      } catch (e) {
        debugPrint('⚠️ Live location fetch failed during check-out: $e');
        if (_cachedLocation != null) {
          debugPrint('ℹ️ Using cached location: ${_cachedLocation!['location']}');
          locationData = _cachedLocation!;
        } else {
           // Try one last time to get *any* location or fail
          debugPrint('⚠️ No cached location available. Retrying one last time...');
          locationData = await LocationService.getCurrentLocation();
        }
      }
      
      // Set current processing data
      _currentProcessingData = {
        'type': 'checkout',
        'time': DateTime.now(),
        'location': locationData['location'],
        'coordinates': '${locationData['latitude']}, ${locationData['longitude']}',
      };
      notifyListeners();

      debugPrint('=== CHECK-OUT DEBUG INFO ===');
      debugPrint('Employee Code: $employeeCode');
      debugPrint('Location: ${locationData['location']}');
      debugPrint('Coordinates: ${locationData['latitude']}, ${locationData['longitude']}');
      debugPrint('===========================');

      final response = await ApiService.checkOut(
        employeeCode: employeeCode,
        latitude: locationData['latitude']!,
        longitude: locationData['longitude']!,
        location: locationData['location']!,
      );

      if (response.status) {
        _currentAttendance = response.data;
        _isLoading = false;
        _errorMessage = '';
        _currentProcessingData = null;
        
        // Refresh today's status to update the dashboard UI
        await fetchTodayStatus(employeeCode);
        
        notifyListeners();
        
        debugPrint('✅ Check-out successful!');
        return (response.warningMessage != null && response.warningMessage!.isNotEmpty)
            ? response.warningMessage
            : response.message;
      } else {
        _errorMessage = _getUserFriendlyErrorMessage(response.message, 'checkout');
        _isLoading = false;
        _currentProcessingData = null;
        notifyListeners();
        
        debugPrint('❌ Check-out failed: ${response.message}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Check-out exception: $e');
      
      _errorMessage = _getUserFriendlyErrorMessage(e.toString(), 'checkout');
      _isLoading = false;
      _currentProcessingData = null;
      notifyListeners();
      return null;
    }
  }

  String _getUserFriendlyErrorMessage(String apiMessage, String action) {
    final message = apiMessage.toLowerCase();
    
    debugPrint('🔍 Raw error message: $apiMessage');
    
    // Remove validation restrictions since multiple entries are allowed
    if (message.contains('successful')) {
      return '${action == 'checkin' ? 'Check-in' : 'Check-out'} successful!';
    } else if (message.contains('exception:')) {
      // Remove "Exception: " prefix if present
      final cleanMessage = message.replaceAll('exception:', '').trim();
      return cleanMessage.isNotEmpty ? cleanMessage : '${action == 'checkin' ? 'Check-in' : 'Check-out'} failed. Please try again.';
    } else {
      return apiMessage.isNotEmpty ? apiMessage : '${action == 'checkin' ? 'Check-in' : 'Check-out'} failed. Please try again.';
    }
  }

  Map<String, dynamic>? _todayStatus;
  
  Map<String, dynamic>? get todayStatus => _todayStatus;
  
  // Get today's attendance entries count
  Future<void> fetchTodayStatus(String employeeCode) async {
    try {
      final history = await ApiService.getAttendanceHistory(employeeCode);
      final today = DateTime.now();
      
      int checkinCount = 0;
      int checkoutCount = 0;
      List<Attendance> todayEntries = [];

      for (var attendance in history) {
        if (attendance.checkinTime != null) {
          final checkinDate = DateTime.parse(attendance.checkinTime!);
          if (checkinDate.year == today.year &&
              checkinDate.month == today.month &&
              checkinDate.day == today.day) {
            todayEntries.add(attendance);
            if (attendance.checkinTime != null) checkinCount++;
            if (attendance.checkoutTime != null) checkoutCount++;
          }
        }
      }
      
      _todayStatus = {
        'checkinCount': checkinCount,
        'checkoutCount': checkoutCount,
        'todayEntries': todayEntries,
        'lastCheckin': todayEntries.isNotEmpty && todayEntries.last.checkinTime != null 
            ? todayEntries.last.checkinTime 
            : null,
        'lastCheckout': todayEntries.isNotEmpty && todayEntries.last.checkoutTime != null 
            ? todayEntries.last.checkoutTime 
            : null,
      };
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting today status: $e');
      _todayStatus = {
        'checkinCount': 0,
        'checkoutCount': 0,
        'todayEntries': [],
        'lastCheckin': null,
        'lastCheckout': null,
      };
      notifyListeners();
    }
  }

  void clearCurrentAttendance() {
    _currentAttendance = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void clearProcessingData() {
    _currentProcessingData = null;
    notifyListeners();
  }
}