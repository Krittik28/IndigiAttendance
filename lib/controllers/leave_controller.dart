import 'package:flutter/material.dart';
import '../models/leave_model.dart';
import '../services/leave_service.dart';
import '../services/api_service.dart';

class LeaveController extends ChangeNotifier {
  final LeaveService _leaveService = LeaveService();

  LeaveBalance? _balance;
  List<LeaveRequest> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _lastPage = 1;
  bool _isMoreLoading = false;

  LeaveBalance? get balance => _balance;
  List<LeaveRequest> get history => _history;
  bool get isLoading => _isLoading;
  bool get isMoreLoading => _isMoreLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _currentPage < _lastPage;

  // Fetch initial data
  Future<void> fetchLeaveData(String empCode, {bool refresh = true}) async {
    if (refresh) {
      _isLoading = true;
      _currentPage = 1;
    } else {
      if (!hasMore || _isMoreLoading) return;
      _isMoreLoading = true;
    }
    
    _errorMessage = null;
    notifyListeners();

    try {
      final pageToFetch = refresh ? 1 : _currentPage + 1;
      final response = await _leaveService.getLeaveData(empCode, page: pageToFetch);
      
      if (refresh) {
        _history = response.history;
      } else {
        _history.addAll(response.history);
      }
      
      _balance = response.balance;
      _currentPage = response.currentPage;
      _lastPage = response.lastPage;

    } catch (e) {
      _errorMessage = "Failed to load leave data: $e";
    } finally {
      _isLoading = false;
      _isMoreLoading = false;
      notifyListeners();
    }
  }

  // Validate before applying
  String? validateRequest(LeaveType type, DateTime start, DateTime end) {
    if (_balance == null) return "Balance not loaded.";
    return _leaveService.validateLeaveRequest(
      type, 
      start, 
      end, 
      _balance!.employeeType,
    );
  }

  // Apply for leave
  Future<bool> submitLeaveRequest({
    required String empCode,
    required LeaveType type,
    required DateTime start,
    required DateTime end,
    required String reason,
    String? attachmentPath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final noOfDays = end.difference(start).inDays + 1.0;
      final validationError = validateRequest(type, start, end);
      if (validationError != null) {
        _errorMessage = validationError;
        return false;
      }

      final newRequest = LeaveRequest(
        id: 0,
        type: type,
        startDate: start,
        endDate: end,
        reason: reason,
        status: LeaveStatus.applied,
        appliedDate: DateTime.now(),
        attachmentPath: attachmentPath,
        noOfDays: noOfDays,
      );

      final success = await _leaveService.applyForLeave(newRequest, empCode);
      if (success) {
        await fetchLeaveData(empCode);
      }
      return success;

    } catch (e) {
      _errorMessage = "Failed to submit request: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateLeaveRequest({
    required int leaveId,
    required String empCode,
    required LeaveType type,
    required DateTime start,
    required DateTime end,
    required String reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final noOfDays = end.difference(start).inDays + 1.0;
      final validationError = validateRequest(type, start, end);
      if (validationError != null) {
        _errorMessage = validationError;
        return false;
      }

      final updatedRequest = LeaveRequest(
        id: leaveId,
        type: type,
        startDate: start,
        endDate: end,
        reason: reason,
        status: LeaveStatus.applied,
        appliedDate: DateTime.now(),
        noOfDays: noOfDays,
      );

      final success = await _leaveService.updateLeave(updatedRequest, empCode);
      if (success) {
        await fetchLeaveData(empCode);
      }
      return success;
    } catch (e) {
      _errorMessage = "Failed to update request: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelLeaveRequest(int leaveId, String empCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _leaveService.cancelLeave(leaveId, empCode);
      if (success) {
        // Give the backend a moment to process the state change before refreshing
        await Future.delayed(const Duration(seconds: 1));
        await fetchLeaveData(empCode);
      }
      return success;
    } catch (e) {
      _errorMessage = "Failed to cancel request: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(String empCode, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await ApiService.changePassword(empCode: empCode, newPassword: newPassword);
      return success;
    } catch (e) {
      _errorMessage = "Failed to change password: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
