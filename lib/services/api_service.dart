import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/attendance_model.dart';

class ApiService {
  static const String baseUrl = 'https://hrm.indigierp.com/api';

  static Future<LoginResponse> login(String empCode, String password) async {
    final url = Uri.parse('$baseUrl/empLogin');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'emp_code': empCode,
        'password': password,
      },
    );

    print('Login Response Status: ${response.statusCode}');
    print('Login Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return LoginResponse.fromJson(jsonResponse);
    } else {
      try {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? 'Login failed');
      } catch (e) {
        throw Exception('Login failed - Status: ${response.statusCode}');
      }
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
}