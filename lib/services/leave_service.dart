import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/leave_model.dart';
import 'api_service.dart';

class LeaveService {
  
  Future<LeaveHistoryResponse> getLeaveData(String empCode, {int page = 1}) async {
    return await ApiService.getLeaveList(empCode, page: page);
  }

  // Returns null if valid, error message string if invalid
  String? validateLeaveRequest(LeaveType type, DateTime start, DateTime end, String? empType) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);
    
    final duration = end.difference(start).inDays + 1;
    final daysInAdvance = startDay.difference(today).inDays;

    if (end.isBefore(start)) {
      return "End date cannot be before start date.";
    }

    // Allow same day application
    if (startDay.isBefore(today)) {
       return "Cannot apply for past dates.";
    }

    bool isProbation = empType?.toLowerCase() == 'probation';

    if (isProbation) {
      if (type == LeaveType.earnedLeave) {
        return "Earned Leave (EL) is not applicable during probation.";
      }
    }

    switch (type) {
      case LeaveType.casualLeave:
        if (duration > 2) {
          return "Casual Leave (CL) cannot exceed 2 consecutive days per policy.";
        }
        break;
      
      case LeaveType.workFromHome:
         if (duration > 2) {
           return "Work From Home cannot exceed 2 days.";
         }
         break;
        
      default:
        break;
    }
    
    return null;
  }

  Future<bool> applyForLeave(LeaveRequest request, String empCode) async {
    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      
      return await ApiService.applyLeave(
        empCode: empCode,
        fromDate: formatter.format(request.startDate),
        toDate: formatter.format(request.endDate),
        reason: request.reason,
        type: _mapLeaveType(request.type),
        noOfDays: request.noOfDays,
        prescriptionPath: request.attachmentPath,
      );
    } catch (e) {
      debugPrint('Error applying for leave: $e');
      rethrow;
    }
  }

  Future<bool> updateLeave(LeaveRequest request, String empCode) async {
    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      return await ApiService.updateLeave(
        leaveId: request.id,
        empCode: empCode,
        fromDate: formatter.format(request.startDate),
        toDate: formatter.format(request.endDate),
        reason: request.reason,
        type: _mapLeaveType(request.type),
        noOfDays: request.noOfDays,
      );
    } catch (e) {
      debugPrint('Error updating leave: $e');
      rethrow;
    }
  }

  Future<bool> cancelLeave(int leaveId, String empCode) async {
    return await ApiService.cancelLeave(leaveId: leaveId, empCode: empCode);
  }

  String _mapLeaveType(LeaveType type) {
    switch (type) {
      case LeaveType.casualLeave: return 'Casual Leave';
      case LeaveType.sickLeave: return 'Sick Leave';
      case LeaveType.earnedLeave: return 'Earned Leave';
      case LeaveType.workFromHome: return 'Work From Home';
      case LeaveType.compOff: return 'Comp-Off';
      case LeaveType.paternityLeave: return 'Paternity Leave';
      case LeaveType.maternityLeave: return 'Maternity Leave';
      case LeaveType.marriageLeave: return 'Marriage Leave';
      case LeaveType.bereavementLeave: return 'Bereavement Leave';
      case LeaveType.happinessLeave: return 'Happiness Leave';
      case LeaveType.carryForwardLeave: return 'Carry Forward Leave';
      case LeaveType.lwp: return 'LWP';
      default: return 'Casual Leave';
    }
  }
}
