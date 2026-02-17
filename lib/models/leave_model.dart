enum LeaveType {
  sickLeave,
  casualLeave,
  happinessLeave,
  maternityLeave,
  paternityLeave,
  marriageLeave,
  bereavementLeave,
  earnedLeave,
  carryForwardLeave,
  workFromHome,
  compOff,
  lwp,
}

enum LeaveStatus {
  pending,
  approved,
  rejected,
  cancelled,
  applied,
}

class LeaveRequest {
  final int id;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final DateTime appliedDate;
  final String? rejectionReason;
  final String? attachmentPath;
  final double noOfDays;
  final String? rmStatus;
  final String? pmStatus;
  final String? rmName;
  final String? pmName;

  LeaveRequest({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.appliedDate,
    this.rejectionReason,
    this.attachmentPath,
    required this.noOfDays,
    this.rmStatus,
    this.pmStatus,
    this.rmName,
    this.pmName,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      type: _parseLeaveType(json['type']),
      startDate: DateTime.parse(json['from_date']),
      endDate: DateTime.parse(json['to_date']),
      reason: json['reason'] ?? '',
      status: _parseLeaveStatus(json['status']),
      appliedDate: DateTime.parse(json['created_at']),
      noOfDays: double.parse(json['no_of_days'].toString()),
      attachmentPath: json['prescription'],
      rmStatus: json['reporting_manager_status'],
      pmStatus: json['project_manager_status'],
      rmName: json['rm_name'],
      pmName: json['pm_name'],
      rejectionReason: json['remarks'],
    );
  }

  static LeaveType _parseLeaveType(String? type) {
    switch (type?.toLowerCase()) {
      case 'casual leave': return LeaveType.casualLeave;
      case 'sick leave': return LeaveType.sickLeave;
      case 'earned leave': return LeaveType.earnedLeave;
      case 'happiness leave': return LeaveType.happinessLeave;
      case 'paternity leave': return LeaveType.paternityLeave;
      case 'maternity leave': return LeaveType.maternityLeave;
      case 'marriage leave': return LeaveType.marriageLeave;
      case 'bereavement leave': return LeaveType.bereavementLeave;
      case 'carry forward leave': return LeaveType.carryForwardLeave;
      case 'work from home': return LeaveType.workFromHome;
      case 'comp-off': return LeaveType.compOff;
      case 'lwp': return LeaveType.lwp;
      default: return LeaveType.casualLeave;
    }
  }

  static LeaveStatus _parseLeaveStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'applied': return LeaveStatus.applied;
      case 'pending': return LeaveStatus.pending;
      case 'approved': return LeaveStatus.approved;
      case 'rejected': return LeaveStatus.rejected;
      case 'cancelled': return LeaveStatus.cancelled;
      default: return LeaveStatus.pending;
    }
  }

  int get durationInDays {
    return noOfDays.toInt();
  }

  bool get isDeletable => status == LeaveStatus.applied || status == LeaveStatus.pending;
  bool get isEditable => status == LeaveStatus.applied || status == LeaveStatus.pending;
}

class LeaveBalance {
  final double casualLeave;
  final double sickLeave;
  final double earnedLeave;
  final double compOff;
  final double carryForwardLeave;
  final double workFromHome;
  final double happinessLeave;
  final double paternityLeave;
  final double maternityLeave;
  final double marriageLeave;
  final double bereavementLeave;
  final double total;
  final double remaining;
  final String? employeeType;

  LeaveBalance({
    required this.casualLeave,
    required this.sickLeave,
    required this.earnedLeave,
    required this.compOff,
    required this.carryForwardLeave,
    required this.workFromHome,
    required this.happinessLeave,
    required this.paternityLeave,
    required this.maternityLeave,
    required this.marriageLeave,
    required this.bereavementLeave,
    required this.total,
    required this.remaining,
    this.employeeType,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json, {String? empType, double? total, double? remaining}) {
    // Priority: 1. Parameters passed to function, 2. JSON fields, 3. Manual calculation as fallback
    double apiTotal = total ?? (json['total'] ?? 30).toDouble();
    double apiRemaining = remaining ?? (json['remaining'] ?? 0).toDouble();

    // If API provided 0 for remaining but categories have values, we use our calculation
    if (apiRemaining == 0) {
      double calcRemaining = (json['cl'] ?? 0).toDouble() +
          (json['sl'] ?? 0).toDouble() +
          (json['el'] ?? 0).toDouble() +
          (json['hpl'] ?? 0).toDouble() +
          (json['ptl'] ?? 0).toDouble() +
          (json['mtl'] ?? 0).toDouble() +
          (json['mrl'] ?? 0).toDouble() +
          (json['brl'] ?? 0).toDouble() +
          (json['cfl'] ?? 0).toDouble() +
          (json['pl'] ?? 0).toDouble();
      
      if (calcRemaining > 0) {
        apiRemaining = calcRemaining;
      }
    }

    return LeaveBalance(
      casualLeave: (json['cl'] ?? 0).toDouble(),
      sickLeave: (json['sl'] ?? 0).toDouble(),
      earnedLeave: (json['el'] ?? 0).toDouble(),
      compOff: (json['co'] ?? 0).toDouble(), 
      carryForwardLeave: (json['cfl'] ?? 0).toDouble(),
      workFromHome: (json['wfh'] ?? 0).toDouble(),
      happinessLeave: (json['hpl'] ?? 0).toDouble(),
      paternityLeave: (json['ptl'] ?? 0).toDouble(),
      maternityLeave: (json['mtl'] ?? 0).toDouble(),
      marriageLeave: (json['mrl'] ?? 0).toDouble(),
      bereavementLeave: (json['brl'] ?? 0).toDouble(),
      total: apiTotal,
      remaining: apiRemaining,
      employeeType: empType,
    );
  }
  
  String get clDisplay => casualLeave.toStringAsFixed(1);
  String get slDisplay => sickLeave.toStringAsFixed(1);
  String get elDisplay => earnedLeave.toStringAsFixed(1);
  String get cfDisplay => carryForwardLeave.toStringAsFixed(1);
  String get wfhDisplay => workFromHome.toStringAsFixed(1);
  String get hplDisplay => happinessLeave.toStringAsFixed(1);
  String get ptlDisplay => paternityLeave.toStringAsFixed(1);
  String get mtlDisplay => maternityLeave.toStringAsFixed(1);
  String get mrlDisplay => marriageLeave.toStringAsFixed(1);
  String get brlDisplay => bereavementLeave.toStringAsFixed(1);
}

class LeaveHistoryResponse {
  final LeaveBalance balance;
  final List<LeaveRequest> history;
  final int currentPage;
  final int lastPage;
  final int total;

  LeaveHistoryResponse({
    required this.balance,
    required this.history,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

// End of file