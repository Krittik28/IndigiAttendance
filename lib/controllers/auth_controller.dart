import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/shared_prefs_service.dart';
import '../services/device_service.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';

class AuthController with ChangeNotifier {
  bool _isLoading = false;
  bool _isCheckingAutoLogin = true;
  String _errorMessage = '';
  User? _currentUser;
  List<Attendance> _attendanceHistory = [];
  bool _isRefreshingHistory = false;

  bool get isLoading => _isLoading;
  bool get isCheckingAutoLogin => _isCheckingAutoLogin;
  String get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  List<Attendance> get attendanceHistory => _attendanceHistory;
  bool get isRefreshingHistory => _isRefreshingHistory;

  AuthController() {
    _checkAutoLogin();
  }

  // Check for auto-login when app starts
  Future<void> _checkAutoLogin() async {
    try {
      final userData = await SharedPrefsService.getUserData();
      
      if (userData != null) {
        // Try to auto-login with saved credentials
        final success = await login(
          userData['employeeCode']!,
          userData['password']!,
          isAutoLogin: true,
        );
        
        if (!success) {
          // If login fails, try to use saved user data as fallback
          try {
            final userMap = json.decode(userData['userData']!);
            _currentUser = User.fromJson(userMap);
          } catch (e) {
            print('Error parsing saved user data: $e');
          }
        }
      }
    } catch (e) {
      print('Auto-login failed: $e');
      // If auto-login fails, clear saved data
      await SharedPrefsService.clearUserData();
    } finally {
      _isCheckingAutoLogin = false;
      notifyListeners();
    }
  }

  Future<bool> login(
    String empCode, 
    String password, {
    bool isAutoLogin = false,
  }) async {
    if (!isAutoLogin) {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
    }

    if (empCode.isEmpty || password.isEmpty) {
      _errorMessage = 'Please enter both employee code and password';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // Fetch Device ID and Model for security binding
      final deviceDetails = await DeviceService.getDeviceDetails();
      
      final response = await ApiService.login(
        empCode, 
        password,
        deviceId: deviceDetails['device_id'],
        deviceModel: deviceDetails['device_model'],
      );
      
      if (response.status && response.user != null) {
        _currentUser = response.user;
        _attendanceHistory = response.attendance;
        _isLoading = false;
        _errorMessage = '';

        // Save login data for auto-login (only if not auto-logging in)
        if (!isAutoLogin) {
          await SharedPrefsService.saveUserData(
            employeeCode: empCode,
            password: password,
            userData: json.encode({
              'id': response.user!.id,
              'employee_code': response.user!.employeeCode,
              'name': response.user!.name,
              'email': response.user!.email,
              'emp_attachment_url': response.user!.empAttachmentUrl,
            }),
          );
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to login: Wrong username or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to login: Wrong username or password';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Updated method to refresh attendance history with better error handling
  Future<void> refreshAttendanceHistory() async {
    if (_currentUser == null) return;

    _isRefreshingHistory = true;
    notifyListeners();

    try {
      final history = await ApiService.getAttendanceHistory(_currentUser!.employeeCode);
      _attendanceHistory = history;
      _isRefreshingHistory = false;
      notifyListeners();
    } catch (e) {
      print('Error refreshing attendance history: $e');
      _isRefreshingHistory = false;
      notifyListeners();
      // Don't show error to user for history refresh, just log it
    }
  }

  Future<void> logout() async {
    // Clear shared preferences
    await SharedPrefsService.clearUserData();
    
    // Clear all state
    _currentUser = null;
    _errorMessage = '';
    _attendanceHistory = [];
    _isRefreshingHistory = false;
    _isLoading = false;
    
    // Notify listeners to trigger UI update
    notifyListeners();
  }
}