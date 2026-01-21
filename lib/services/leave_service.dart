import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/leave_model.dart';
import 'api_service.dart';

class LeaveService {
  
  // TODO: Replace with actual API call when endpoint is available
  Future<List<LeaveRequest>> getLeaveHistory() async {
    // Returning empty list for now as we don't have the history endpoint provided in the context
    // and we want to focus on the 'Apply Leave' functionality.
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<LeaveBalance> getLeaveBalance(int userId) async {
    return await ApiService.getLeaveBalance(userId);
  }

  // Returns null if valid, error message string if invalid
  String? validateLeaveRequest(LeaveType type, DateTime start, DateTime end, bool isProbation, int probationMonths) {
    final now = DateTime.now();
    // Normalize 'now' to start of day for accurate comparison
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);
    
    final duration = end.difference(start).inDays + 1;
    final daysInAdvance = startDay.difference(today).inDays;

    if (end.isBefore(start)) {
      return "End date cannot be before start date.";
    }

    if (startDay.isBefore(today)) {
       return "Cannot apply for past dates.";
    }

    // Probation Validation
    if (isProbation) {
      if (type == LeaveType.earnedLeave) {
        return "Earned Leave (EL) is not applicable during probation.";
      }
      // Allowed: CL, SL
    }

    switch (type) {
      case LeaveType.casualLeave:
        // Policy: "Normally, not more than 2 consecutive days"
        if (duration > 2) {
          return "Casual Leave (CL) cannot exceed 2 consecutive days per policy.";
        }
        break;
      
      case LeaveType.sickLeave:
        // Medical certificate logic is handled in UI (requiring attachment for >= 3 days)
        break;

      case LeaveType.earnedLeave:
        // Policy: "Minimum EL availed at a time: 3 consecutive days"
        if (duration < 3) {
          return "Earned Leave (EL) must be for a minimum of 3 consecutive days.";
        }
        // Policy: "Must be applied at least 14 calendar days in advance"
        if (daysInAdvance < 14) {
          return "Earned Leave (EL) must be applied at least 14 days in advance.";
        }
        break;

      case LeaveType.workFromHome:
         // Backend: "Work From Home leave cannot exceed 2 days"
         if (duration > 2) {
           return "Work From Home cannot exceed 2 days.";
         }
         break;

      case LeaveType.compOff:
        // Policy: "Must be availed within 30 days" - Logic requires worked date, skipping simple validation here.
        break;
        
      default:
        break;
    }
    
    return null;
  }

  Future<bool> applyForLeave(LeaveRequest request, String empCode) async {
    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      
      // Convert Enum to Backend String
      String typeStr;
      switch (request.type) {
        case LeaveType.casualLeave: typeStr = 'Casual Leave'; break;
        case LeaveType.sickLeave: typeStr = 'Sick Leave'; break;
        case LeaveType.earnedLeave: typeStr = 'Earned Leave'; break;
        case LeaveType.workFromHome: typeStr = 'Work From Home'; break;
        case LeaveType.compOff: typeStr = 'Comp-Off'; break;
        case LeaveType.paternityLeave: typeStr = 'Paternity Leave'; break;
        case LeaveType.maternityLeave: typeStr = 'Maternity Leave'; break;
        case LeaveType.marriageLeave: typeStr = 'Marriage Leave'; break;
        case LeaveType.bereavementLeave: typeStr = 'Bereavement Leave'; break;
        case LeaveType.happinessLeave: typeStr = 'Happiness Leave'; break;
        case LeaveType.carryForwardLeave: typeStr = 'Carry Forward Leave'; break;
        default: typeStr = 'Other';
      }

      return await ApiService.applyLeave(
        empCode: empCode,
        fromDate: formatter.format(request.startDate),
        toDate: formatter.format(request.endDate),
        reason: request.reason,
        type: typeStr,
        noOfDays: request.durationInDays.toDouble(), // Backend expects numeric
        prescriptionPath: request.attachmentPath,
      );
    } catch (e) {
      debugPrint('Error applying for leave: $e');
      rethrow;
    }
  }
}
