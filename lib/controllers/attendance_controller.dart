import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../models/attendance_model.dart';

class AttendanceController with ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  Attendance? _currentAttendance;
  Map<String, dynamic>? _currentProcessingData;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Attendance? get currentAttendance => _currentAttendance;
  Map<String, dynamic>? get currentProcessingData => _currentProcessingData;

  Future<bool> checkIn({required String employeeCode}) async {
    _isLoading = true;
    _errorMessage = '';
    _currentProcessingData = null;
    notifyListeners();

    try {
      final locationData = await LocationService.getCurrentLocation();
      
      // Set current processing data
      _currentProcessingData = {
        'type': 'checkin',
        'time': DateTime.now(),
        'location': locationData['location'],
        'coordinates': '${locationData['latitude']}, ${locationData['longitude']}',
      };
      notifyListeners();

      print('=== CHECK-IN DEBUG INFO ===');
      print('Employee Code: $employeeCode');
      print('Location: ${locationData['location']}');
      print('Coordinates: ${locationData['latitude']}, ${locationData['longitude']}');
      print('==========================');

      final response = await ApiService.checkIn(
        employeeCode: employeeCode,
        latitude: locationData['latitude']!,
        longitude: locationData['longitude']!,
        location: locationData['location']!,
      );

      if (response.status && response.data != null) {
        _currentAttendance = response.data;
        _isLoading = false;
        _errorMessage = '';
        _currentProcessingData = null;
        notifyListeners();
        
        print('✅ Check-in successful!');
        return true;
      } else {
        _errorMessage = _getUserFriendlyErrorMessage(response.message, 'checkin');
        _isLoading = false;
        _currentProcessingData = null;
        notifyListeners();
        
        print('❌ Check-in failed: ${response.message}');
        return false;
      }
    } catch (e) {
      print('💥 Check-in exception: $e');
      
      _errorMessage = _getUserFriendlyErrorMessage(e.toString(), 'checkin');
      _isLoading = false;
      _currentProcessingData = null;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOut({required String employeeCode}) async {
    _isLoading = true;
    _errorMessage = '';
    _currentProcessingData = null;
    notifyListeners();

    try {
      final locationData = await LocationService.getCurrentLocation();
      
      // Set current processing data
      _currentProcessingData = {
        'type': 'checkout',
        'time': DateTime.now(),
        'location': locationData['location'],
        'coordinates': '${locationData['latitude']}, ${locationData['longitude']}',
      };
      notifyListeners();

      print('=== CHECK-OUT DEBUG INFO ===');
      print('Employee Code: $employeeCode');
      print('Location: ${locationData['location']}');
      print('Coordinates: ${locationData['latitude']}, ${locationData['longitude']}');
      print('===========================');

      final response = await ApiService.checkOut(
        employeeCode: employeeCode,
        latitude: locationData['latitude']!,
        longitude: locationData['longitude']!,
        location: locationData['location']!,
      );

      if (response.status && response.data != null) {
        _currentAttendance = response.data;
        _isLoading = false;
        _errorMessage = '';
        _currentProcessingData = null;
        notifyListeners();
        
        print('✅ Check-out successful!');
        return true;
      } else {
        _errorMessage = _getUserFriendlyErrorMessage(response.message, 'checkout');
        _isLoading = false;
        _currentProcessingData = null;
        notifyListeners();
        
        print('❌ Check-out failed: ${response.message}');
        return false;
      }
    } catch (e) {
      print('💥 Check-out exception: $e');
      
      _errorMessage = _getUserFriendlyErrorMessage(e.toString(), 'checkout');
      _isLoading = false;
      _currentProcessingData = null;
      notifyListeners();
      return false;
    }
  }

  String _getUserFriendlyErrorMessage(String apiMessage, String action) {
    final message = apiMessage.toLowerCase();
    
    print('🔍 Raw error message: $apiMessage');
    
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

  // Get today's attendance entries count
  Future<Map<String, dynamic>> getTodayStatus(String employeeCode) async {
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
      
      return {
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
    } catch (e) {
      print('Error getting today status: $e');
      return {
        'checkinCount': 0,
        'checkoutCount': 0,
        'todayEntries': [],
        'lastCheckin': null,
        'lastCheckout': null,
      };
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