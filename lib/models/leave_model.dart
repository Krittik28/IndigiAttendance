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
}

class LeaveRequest {
  final String id;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final DateTime appliedDate;
  final String? rejectionReason;
  final String? attachmentPath; 

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
  });

  int get durationInDays {
    return endDate.difference(startDate).inDays + 1;
  }
}

class LeaveBalance {
  final double casualLeave; // cl
  final double sickLeave; // sl
  final double earnedLeave; // el
  final double compOff; // defaulting to 0 as not in provided API response example, or maybe mapped to something else?
  final double carryForwardLeave; // cfl
  final double workFromHome; // wfh
  final double privilegeLeave; // pl
  final double happinessLeave; // hpl
  final double paternityLeave; // ptl
  final double maternityLeave; // mtl
  final double marriageLeave; // mrl
  final double bereavementLeave; // brl
  
  final double total;
  final double remaining;

  final bool isProbation;
  final int probationMonthsCompleted; 

  LeaveBalance({
    required this.casualLeave,
    required this.sickLeave,
    required this.earnedLeave,
    required this.compOff,
    required this.carryForwardLeave,
    required this.workFromHome,
    required this.privilegeLeave,
    required this.happinessLeave,
    required this.paternityLeave,
    required this.maternityLeave,
    required this.marriageLeave,
    required this.bereavementLeave,
    required this.total,
    required this.remaining,
    required this.isProbation,
    this.probationMonthsCompleted = 0,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      casualLeave: (json['cl'] ?? 0).toDouble(),
      sickLeave: (json['sl'] ?? 0).toDouble(),
      earnedLeave: (json['el'] ?? 0).toDouble(),
      // 'compOff' is not explicitly in the provided list, keeping it 0 or using 'pl' if that was intended? 
      // Assuming 'pl' is Privilege Leave. For now Comp Off 0.
      compOff: 0.0, 
      carryForwardLeave: (json['cfl'] ?? 0).toDouble(),
      workFromHome: (json['wfh'] ?? 0).toDouble(),
      privilegeLeave: (json['pl'] ?? 0).toDouble(),
      happinessLeave: (json['hpl'] ?? 0).toDouble(),
      paternityLeave: (json['ptl'] ?? 0).toDouble(),
      maternityLeave: (json['mtl'] ?? 0).toDouble(),
      marriageLeave: (json['mrl'] ?? 0).toDouble(),
      bereavementLeave: (json['brl'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      remaining: (json['remaining'] ?? 0).toDouble(),
      isProbation: false, // Defaulting as not in response
      probationMonthsCompleted: 0,
    );
  }
  
  String get clDisplay => casualLeave.toStringAsFixed(1);
  String get slDisplay => sickLeave.toStringAsFixed(1);
  String get elDisplay => earnedLeave.toStringAsFixed(1);
  String get compOffDisplay => compOff.toStringAsFixed(1);
  String get cfDisplay => carryForwardLeave.toStringAsFixed(1);
  String get wfhDisplay => workFromHome.toStringAsFixed(1);
}

// End of file