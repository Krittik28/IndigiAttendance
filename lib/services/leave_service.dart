import '../models/leave_model.dart';
import 'api_service.dart';

class LeaveService {
  // Mock Data
  // Removed static mock balance as we are fetching from API


  static final List<LeaveRequest> _mockHistory = [
    LeaveRequest(
      id: '1',
      type: LeaveType.casualLeave,
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().subtract(const Duration(days: 10)),
      reason: 'Personal work',
      status: LeaveStatus.approved,
      appliedDate: DateTime.now().subtract(const Duration(days: 15)),
    ),
    LeaveRequest(
      id: '2',
      type: LeaveType.sickLeave,
      startDate: DateTime.now().subtract(const Duration(days: 40)),
      endDate: DateTime.now().subtract(const Duration(days: 38)),
      reason: 'Fever',
      status: LeaveStatus.approved,
      appliedDate: DateTime.now().subtract(const Duration(days: 42)),
    ),
  ];

  Future<LeaveBalance> getLeaveBalance(int userId) async {
    return await ApiService.getLeaveBalance(userId);
  }

  Future<List<LeaveRequest>> getLeaveHistory() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate API
    return _mockHistory;
  }

  // Returns null if valid, error message string if invalid
  String? validateLeaveRequest(LeaveType type, DateTime start, DateTime end, bool isProbation, int probationMonths) {
    final now = DateTime.now();
    final duration = end.difference(start).inDays + 1;
    final daysInAdvance = start.difference(now).inDays;

    if (end.isBefore(start)) {
      return "End date cannot be before start date.";
    }

    if (start.isBefore(DateTime(now.year, now.month, now.day))) {
       return "Cannot apply for past dates (unless regularizing - currently not supported).";
    }

    if (isProbation) {
      if (type == LeaveType.earnedLeave) {
        return "Earned Leave (EL) is not applicable during probation.";
      }
      // Probation rule: 1 day per completed month. 
      // This is a balance check, technically, but we can flag type issues here.
    }

    switch (type) {
      case LeaveType.casualLeave:
        if (duration > 2) {
          return "Casual Leave (CL) normally cannot exceed 2 consecutive days.";
        }
        break;
      
      case LeaveType.sickLeave:
        // Medical certificate logic is handled in UI (requiring attachment)
        break;

      case LeaveType.earnedLeave:
        if (duration < 3) {
          return "Earned Leave (EL) must be for a minimum of 3 consecutive days.";
        }
        if (daysInAdvance < 14) {
          return "Earned Leave (EL) must be applied at least 14 days in advance.";
        }
        break;

      case LeaveType.compOff:
        // Must be availed within 30 days of the worked day.
        // This requires selecting the 'worked day' against which comp-off is taken.
        // For simple validation, we just ensure it's a valid request.
        break;
        
      default:
        break;
    }
    
    return null;
  }

  Future<bool> applyForLeave(LeaveRequest request) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API
    _mockHistory.insert(0, request);
    return true;
  }
}
