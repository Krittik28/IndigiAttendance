import 'attendance_model.dart';

class User {
  final int id;
  final String employeeCode;
  final String name;
  final String email;
  final String? empAttachmentUrl;

  User({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    this.empAttachmentUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      employeeCode: json['employee_code']?.toString() ?? '', // Handle both int and string
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      empAttachmentUrl: json['emp_attachment_url'],
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
    return LoginResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      user: json['data'] != null ? User.fromJson(json['data']) : null,
      attendance: json['attendance'] != null 
          ? List<Attendance>.from(
              json['attendance'].map((x) => Attendance.fromJson(x)))
          : [],
    );
  }
}