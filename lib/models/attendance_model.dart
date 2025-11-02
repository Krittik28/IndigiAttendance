class Attendance {
  final int id;
  final String employeeCode;
  final String? checkinTime;
  final String? checkoutTime;
  final String? checkinLatitude;
  final String? checkinLongitude;
  final String? checkinLocation;
  final String? checkoutLatitude;
  final String? checkoutLongitude;
  final String? checkoutLocation;

  Attendance({
    required this.id,
    required this.employeeCode,
    this.checkinTime,
    this.checkoutTime,
    this.checkinLatitude,
    this.checkinLongitude,
    this.checkinLocation,
    this.checkoutLatitude,
    this.checkoutLongitude,
    this.checkoutLocation,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      employeeCode: json['employee_code'].toString(),
      checkinTime: json['checkin_time'],
      checkoutTime: json['checkout_time'],
      checkinLatitude: json['checkin_latitude'],
      checkinLongitude: json['checkin_longitude'],
      checkinLocation: json['checkin_location'],
      checkoutLatitude: json['checkout_latitude'],
      checkoutLongitude: json['checkout_longitude'],
      checkoutLocation: json['checkout_location'],
    );
  }
}

class CheckInResponse {
  final bool status;
  final String message;
  final Attendance? data;

  CheckInResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    return CheckInResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? Attendance.fromJson(json['data']) : null,
    );
  }
}

class CheckOutResponse {
  final bool status;
  final String message;
  final Attendance? data;

  CheckOutResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory CheckOutResponse.fromJson(Map<String, dynamic> json) {
    return CheckOutResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? Attendance.fromJson(json['data']) : null,
    );
  }
}

// New model for attendance history response
class AttendanceHistoryResponse {
  final bool status;
  final List<Attendance> data;

  AttendanceHistoryResponse({
    required this.status,
    required this.data,
  });

  factory AttendanceHistoryResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryResponse(
      status: json['status'],
      data: List<Attendance>.from(
        json['data'].map((x) => Attendance.fromJson(x))
      ),
    );
  }
}