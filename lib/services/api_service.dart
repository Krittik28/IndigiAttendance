import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_model.dart';

class ApiService {
  static const String baseUrl = 'https://hrm.indigierp.com/api';

  static Future<LoginResponse> login(String empCode, String password, {String? deviceId, String? deviceModel}) async {
    final url = Uri.parse('$baseUrl/empLoginTest');
    
    final body = {
      'emp_code': empCode,
      'password': password,
    };

    if (deviceId != null) {
      body['registered_device_id'] = deviceId;
    }
    if (deviceModel != null) {
      body['registered_device_model'] = deviceModel;
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: body,
    );

    print('Login Response Status: ${response.statusCode}');
    print('Login Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return LoginResponse.fromJson(jsonResponse);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      // Handle known rejection codes (Unauthorized, Forbidden) gracefully
      // This allows the UI/Controller to see the "Account is linked to another device" message
      // without triggering the generic exception handler that forces offline mode.
      try {
        final jsonResponse = json.decode(response.body);
        // Ensure status is false to trigger rejection logic
        if (jsonResponse['status'] == null) jsonResponse['status'] = false;
        return LoginResponse.fromJson(jsonResponse);
      } catch (e) {
        throw Exception('Login failed - Status: ${response.statusCode}');
      }
    } else {
      String errorMessage;
      try {
        final errorResponse = json.decode(response.body);
        errorMessage = errorResponse['message'] ?? 'Login failed';
      } catch (e) {
        errorMessage = 'Login failed - Status: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  static Future<CheckInResponse> checkIn({
    required String employeeCode,
    required String latitude,
    required String longitude,
    required String location,
  }) async {
    final url = Uri.parse('$baseUrl/checkIn');

    print('Check-in Request: employee_code=$employeeCode, latitude=$latitude, longitude=$longitude, location=$location');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'employee_code': employeeCode,
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
      },
    );

    print('Check-in Response Status: ${response.statusCode}');
    print('Check-in Response Body: ${response.body}');

    // Handle both success and error responses
    final jsonResponse = json.decode(response.body);
    
    if (response.statusCode == 200) {
      return CheckInResponse.fromJson(jsonResponse);
    } else {
      // For non-200 status codes, check if there's a message in the response
      final errorMessage = jsonResponse['message'] ?? 'Check-in failed';
      throw Exception(errorMessage);
    }
  }

  static Future<CheckOutResponse> checkOut({
    required String employeeCode,
    required String latitude,
    required String longitude,
    required String location,
  }) async {
    final url = Uri.parse('$baseUrl/checkOut');

    print('Check-out Request: employee_code=$employeeCode, latitude=$latitude, longitude=$longitude, location=$location');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'employee_code': employeeCode,
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
      },
    );

    print('Check-out Response Status: ${response.statusCode}');
    print('Check-out Response Body: ${response.body}');

    // Handle both success and error responses
    final jsonResponse = json.decode(response.body);
    
    if (response.statusCode == 200) {
      return CheckOutResponse.fromJson(jsonResponse);
    } else {
      // For non-200 status codes, check if there's a message in the response
      final errorMessage = jsonResponse['message'] ?? 'Check-out failed';
      throw Exception(errorMessage);
    }
  }

  // Updated method to fetch attendance history with POST request
  static Future<List<Attendance>> getAttendanceHistory(String employeeCode) async {
    final url = Uri.parse('$baseUrl/attendanceList');

    print('Attendance History Request: employee_code=$employeeCode');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'employee_code': employeeCode,
      },
    );

    print('Attendance History Response Status: ${response.statusCode}');
    print('Attendance History Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      
      if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
        return List<Attendance>.from(
          jsonResponse['data'].map((x) => Attendance.fromJson(x))
        );
      } else {
        throw Exception('Failed to fetch attendance history: ${jsonResponse['message'] ?? 'Unknown error'}');
      }
    } else {
      throw Exception('Failed to fetch attendance history - Status: ${response.statusCode}');
    }
  }

  static Future<LeaveBalance> getLeaveBalance(int userId) async {
    final url = Uri.parse('$baseUrl/leave/current/$userId');
    print('Fetching leave balance for user: $userId');
    
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
      },
    );

    print('Leave Balance Response Status: ${response.statusCode}');
    print('Leave Balance Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        return LeaveBalance.fromJson(jsonResponse['data']);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to fetch leave balance');
      }
    } else {
      throw Exception('Failed to fetch leave balance - Status: ${response.statusCode}');
    }
  }

  static Future<bool> applyLeave({
    required String empCode,
    required String fromDate,
    required String toDate,
    required String reason,
    required String type,
    required double noOfDays,
    String? prescriptionPath,
  }) async {
    final url = Uri.parse('$baseUrl/leave/apply');
    print('Applying for leave: empCode=$empCode, type=$type, days=$noOfDays');

    final request = http.MultipartRequest('POST', url);
    
    // Add text fields
    request.fields['emp_code'] = empCode;
    request.fields['from_date'] = fromDate;
    request.fields['to_date'] = toDate;
    request.fields['reason'] = reason;
    request.fields['type'] = type;
    request.fields['no_of_days'] = noOfDays.toString();

    // Add file if present
    if (prescriptionPath != null && prescriptionPath.isNotEmpty) {
      print('Attaching prescription: $prescriptionPath');
      request.files.add(await http.MultipartFile.fromPath(
        'prescription', 
        prescriptionPath
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('Apply Leave Response Status: ${response.statusCode}');
    print('Apply Leave Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == true) {
        return true;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to apply for leave');
      }
    } else if (response.statusCode == 400 || response.statusCode == 422) {
      // Validation errors
      final jsonResponse = json.decode(response.body);
      throw Exception(jsonResponse['message'] ?? 'Validation failed');
    } else {
      throw Exception('Failed to apply for leave - Status: ${response.statusCode}');
    }
  }
}