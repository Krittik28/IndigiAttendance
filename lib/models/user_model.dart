import 'attendance_model.dart';

class PendingLeaveByEmployee {
  final String employeeName;
  final int count;

  PendingLeaveByEmployee({
    required this.employeeName,
    required this.count,
  });

  factory PendingLeaveByEmployee.fromJson(Map<String, dynamic> json) {
    return PendingLeaveByEmployee(
      employeeName: json['employee_name'] ?? '',
      count: User._parseInt(json['count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_name': employeeName,
      'count': count,
    };
  }
}

class User {
  final int id;
  final String employeeCode;
  final String name;
  final String email;
  final String? empAttachmentUrl;
  final bool canApproveLeave;
  final int pendingLeaveCount;
  final List<PendingLeaveByEmployee> pendingLeaveByEmployee;

  User({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    this.empAttachmentUrl,
    this.canApproveLeave = false,
    this.pendingLeaveCount = 0,
    this.pendingLeaveByEmployee = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      employeeCode: json['employee_code']?.toString() ?? '', // Handle both int and string
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      empAttachmentUrl: json['emp_attachment_url'],
      canApproveLeave: _parseBool(json['can_approve_leave']),
      pendingLeaveCount: _parseInt(json['pending_leave_count']),
      pendingLeaveByEmployee: (json['pending_leave_by_employee'] as List<dynamic>?)
              ?.map((e) => PendingLeaveByEmployee.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  User copyWith({
    int? id,
    String? employeeCode,
    String? name,
    String? email,
    String? empAttachmentUrl,
    bool? canApproveLeave,
    int? pendingLeaveCount,
    List<PendingLeaveByEmployee>? pendingLeaveByEmployee,
  }) {
    return User(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      name: name ?? this.name,
      email: email ?? this.email,
      empAttachmentUrl: empAttachmentUrl ?? this.empAttachmentUrl,
      canApproveLeave: canApproveLeave ?? this.canApproveLeave,
      pendingLeaveCount: pendingLeaveCount ?? this.pendingLeaveCount,
      pendingLeaveByEmployee: pendingLeaveByEmployee ?? this.pendingLeaveByEmployee,
    );
  }
}

class LoginResponse {
  final bool status;
  final String message;
  final User? user;
  final List<Attendance> attendance;

  LoginResponse({
    required this.status,
    required this.message,
    this.user,
    required this.attendance,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    var userData = json['data'];
    if (userData != null && userData is Map<String, dynamic>) {
      userData['can_approve_leave'] = json['can_approve_leave'] ?? userData['can_approve_leave'];
    }

    return LoginResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      user: userData != null ? User.fromJson(userData) : null,
      attendance: json['attendance'] != null 
          ? List<Attendance>.from(
              json['attendance'].map((x) => Attendance.fromJson(x)))
          : [],
    );
  }
}