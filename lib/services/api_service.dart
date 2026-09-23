import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_model.dart';
import '../models/client_model.dart';
import '../models/client_visit_model.dart';

class ApiService {
  static const String baseUrl = 'https://hrm.indigierp.com/api';

  static Future<LoginResponse> login(
    String empCode,
    String password, {
    String? deviceId,
    String? deviceModel,
    String? fcmToken,
  }) async {
    final url = Uri.parse('$baseUrl/empLogin');

    final body = {'emp_code': empCode, 'password': password};

    if (deviceId != null) {
      body['registered_device_id'] = deviceId;
    }
    if (deviceModel != null) {
      body['registered_device_model'] = deviceModel;
    }
    // if (fcmToken != null) {
    //   body['fcm_token'] = fcmToken;
    // }

    _logRequest(method: 'POST', url: url, body: body);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: body,
    );

    _logResponse(
      method: 'POST',
      url: url,
      statusCode: response.statusCode,
      body: response.body,
    );

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

    final reqBody = {
      'employee_code': employeeCode,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
    };
    _logRequest(method: 'POST', url: url, body: reqBody);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: reqBody,
    );

    _logResponse(
      method: 'POST',
      url: url,
      statusCode: response.statusCode,
      body: response.body,
    );

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

  static Future<CheckInResponse> checkInWithClient({
    required String employeeCode,
    required String latitude,
    required String longitude,
    required String location,
    required int clientId,
  }) async {
    final url = Uri.parse('$baseUrl/checkIn1');

    final reqBody = {
      'employee_code': employeeCode,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'client_id': clientId.toString(),
    };
    _logRequest(method: 'POST', url: url, body: reqBody);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: reqBody,
    );

    _logResponse(
      method: 'POST',
      url: url,
      statusCode: response.statusCode,
      body: response.body,
    );

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

    final reqBody = {
      'employee_code': employeeCode,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
    };
    _logRequest(method: 'POST', url: url, body: reqBody);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: reqBody,
    );

    _logResponse(
      method: 'POST',
      url: url,
      statusCode: response.statusCode,
      body: response.body,
    );

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
  static Future<List<Attendance>> getAttendanceHistory(
    String employeeCode,
  ) async {
    final url = Uri.parse('$baseUrl/attendanceList');

    final reqBody = {'employee_code': employeeCode};
    _logRequest(method: 'POST', url: url, body: reqBody);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: reqBody,
    );

    _logResponse(
      method: 'POST',
      url: url,
      statusCode: response.statusCode,
      body: response.body,
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
        return List<Attendance>.from(
          jsonResponse['data'].map((x) => Attendance.fromJson(x)),
        );
      } else {
        throw Exception(
          'Failed to fetch attendance history: ${jsonResponse['message'] ?? 'Unknown error'}',
        );
      }
    } else {
      throw Exception(
        'Failed to fetch attendance history - Status: ${response.statusCode}',
      );
    }
  }

  static Future<LeaveHistoryResponse> getLeaveList(
    String employeeCode, {
    int page = 1,
  }) async {
    final url = Uri.parse('$baseUrl/leaves/list');
    debugPrint('Fetching leave list for empCode: $employeeCode, page: $page');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {'emp_code': employeeCode, 'page': page.toString()},
    );

    debugPrint('Leave List Response Status: ${response.statusCode}');
    debugPrint('Leave List Response Body: ${response.body}');
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == true) {
        final balances = jsonResponse['balances'];
        final historyData = jsonResponse['leave_history'];
        final empType = jsonResponse['employee_type'];

        final balance = LeaveBalance.fromJson(
          balances,
          empType: empType,
          // total and remaining will be handled by the model's fromJson logic
        );

        final history = List<LeaveRequest>.from(
          historyData['data'].map((x) => LeaveRequest.fromJson(x)),
        );

        return LeaveHistoryResponse(
          balance: balance,
          history: history,
          currentPage: historyData['current_page'],
          lastPage: historyData['last_page'],
          total: historyData['total'],
        );
      } else {
        throw Exception(
          jsonResponse['message'] ?? 'Failed to fetch leave list',
        );
      }
    } else {
      throw Exception(
        'Failed to fetch leave list - Status: ${response.statusCode}',
      );
    }
  }

  static Future<List<LeaveRequest>> getLeaveApprovalList(
    String employeeCode, {
    int page = 1,
    int perPage = 15,
  }) async {
    final url = Uri.parse(
      '$baseUrl/leaveApprovalList?emp_code=$employeeCode&page=$page&per_page=$perPage',
    );
    debugPrint(
      'Fetching leave approval list for empCode: $employeeCode, page: $page',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'emp_code': employeeCode,
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );

    debugPrint('Leave Approval List Response Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == true) {
        var dataField = jsonResponse['data'];
        List? data;

        if (dataField is Map) {
          data = dataField['data'] as List?;
        } else if (dataField is List) {
          data = dataField;
        }

        final userType = jsonResponse['user_type']?.toString();

        if (data != null) {
          return data
              .map(
                (x) => LeaveRequest.fromJson(x, currentApproverType: userType),
              )
              .toList();
        }
        return [];
      } else {
        throw Exception(
          jsonResponse['message'] ?? 'Failed to fetch leave approval list',
        );
      }
    } else {
      throw Exception(
        'Failed to fetch leave approval list - Status: ${response.statusCode}',
      );
    }
  }

  static Future<bool> undoLeave({
    required int leaveId,
    required String empCode,
  }) async {
    final url = Uri.parse('$baseUrl/undoLeaveApi');
    debugPrint('Undo Leave: leave_id=$leaveId emp_code=$empCode');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {'leave_id': leaveId.toString(), 'emp_code': empCode},
    );

    debugPrint('Undo Leave Response Status: ${response.statusCode}');
    debugPrint('Undo Leave Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == true) {
        return true;
      } else {
        throw Exception(
          jsonResponse['message'] ?? 'Failed to undo leave',
        );
      }
    } else {
      throw Exception('Failed to undo leave - Status: ${response.statusCode}');
    }
  }

  static Future<bool> leaveAction({
    required int leaveId,
    required String empCode,
    required String status,
  }) async {
    final url = Uri.parse('$baseUrl/leaveAction');
    debugPrint(
      'Leave Action: leave_id=$leaveId emp_code=$empCode status=$status',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'leave_id': leaveId.toString(),
        'emp_code': empCode,
        'status': status,
      },
    );

    debugPrint('Leave Action Response Status: ${response.statusCode}');
    debugPrint('Leave Action Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == true) {
        return true;
      } else {
        throw Exception(
          jsonResponse['message'] ?? 'Failed to perform leave action',
        );
      }
    } else {
      throw Exception(
        'Failed to perform leave action - Status: ${response.statusCode}',
      );
    }
  }

  static Future<Map<String, dynamic>> getPendingLeaves(String empCode) async {
    final url = Uri.parse('$baseUrl/pendingLeavesApi?emp_code=$empCode');
    debugPrint('Pending Leaves Request: emp_code=$empCode');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    debugPrint('Pending Leaves Response Status: ${response.statusCode}');
    debugPrint('Pending Leaves Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final data = jsonResponse['data'] ?? {};
      return {
        'pending_leave_count': data['pending_leave_count'] ?? 0,
        'pending_leave_by_employee': data['pending_leave_by_employee'] ?? [],
      };
    } else {
      throw Exception(
        'Failed to fetch pending leaves - Status: ${response.statusCode}',
      );
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
    debugPrint(
      'Applying for leave: empCode=$empCode, type=$type, days=$noOfDays',
    );

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
      debugPrint('Attaching prescription: $prescriptionPath');
      request.files.add(
        await http.MultipartFile.fromPath('prescription', prescriptionPath),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('Apply Leave Response Status: ${response.statusCode}');
    debugPrint('Apply Leave Response Body: ${response.body}');

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
      throw Exception(
        'Failed to apply for leave - Status: ${response.statusCode}',
      );
    }
  }

  static Future<bool> updateLeave({
    required int leaveId,
    required String empCode,
    required String fromDate,
    required String toDate,
    required String reason,
    required String type,
    required double noOfDays,
  }) async {
    final url = Uri.parse('$baseUrl/leave/edit');

    debugPrint('Updating leave: $leaveId for $empCode');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'leave_id': leaveId.toString(),
        'emp_code': empCode,
        'from_date': fromDate,
        'to_date': toDate,
        'reason': reason,
        'type': type,
        'no_of_days': noOfDays.toString(),
      },
    );

    debugPrint('Update Leave Response: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['status'] == true;
    } else {
      throw Exception(
        'Failed to update leave - Status: ${response.statusCode}',
      );
    }
  }

  static Future<bool> cancelLeave({
    required int leaveId,
    required String empCode,
  }) async {
    final url = Uri.parse('$baseUrl/leave/cancel');

    debugPrint('Cancelling leave: $leaveId for $empCode');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {'leave_id': leaveId.toString(), 'emp_code': empCode},
    );

    debugPrint('Cancel Leave Response: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['status'] == true;
    } else {
      throw Exception(
        'Failed to cancel leave - Status: ${response.statusCode}',
      );
    }
  }

  static Future<bool> changePassword({
    required String empCode,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/profile/update');

    debugPrint('Changing password for: $empCode');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {'emp_code': empCode, 'password': newPassword},
    );

    debugPrint('Change Password Response: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['status'] == true;
    } else {
      throw Exception(
        'Failed to change password - Status: ${response.statusCode}',
      );
    }
  }

  static Future<String?> updateProfileImage({
    required String empCode,
    required String imagePath,
  }) async {
    final url = Uri.parse('$baseUrl/profile/image');
    debugPrint('Updating profile image for: $empCode');

    final request = http.MultipartRequest('POST', url);
    request.fields['emp_code'] = empCode;
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('Update Profile Image Response Status: ${response.statusCode}');
    debugPrint('Update Profile Image Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == true) {
        return jsonResponse['image_url']; // Assuming the API returns the new URL
      } else {
        throw Exception(
          jsonResponse['message'] ?? 'Failed to update profile image',
        );
      }
    } else {
      throw Exception(
        'Failed to update profile image - Status: ${response.statusCode}',
      );
    }
  }

  static Future<List<Client>> getCustomerList() async {
    final url = Uri.parse('$baseUrl/customer-list');
    _logRequest(method: 'GET', url: url);

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    _logResponse(
      method: 'GET',
      url: url,
      statusCode: response.statusCode,
      body: response.body,
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
        return List<Client>.from(
          jsonResponse['data'].map((x) => Client.fromJson(x)),
        );
      } else {
        throw Exception(
          'Failed to fetch customer list: ${jsonResponse['message'] ?? 'Unknown error'}',
        );
      }
    } else {
      throw Exception(
        'Failed to fetch customer list - Status: ${response.statusCode}',
      );
    }
  }

  static Future<Map<String, dynamic>> checkInClientVisit({
    required String employeeCode,
    required int clientId,
    required String clientName,
    required String latitude,
    required String longitude,
    required String location,
  }) async {
    final url = Uri.parse('$baseUrl/client-visit/checkin');

    final reqBody = {
      'employee_code': employeeCode,
      'client_id': clientId.toString(),
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
    };
    _logRequest(method: 'POST', url: url, body: reqBody);

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: reqBody,
          )
          .timeout(const Duration(seconds: 5));

      _logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
      );
      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonResponse;
      } else {
        final errorMessage =
            jsonResponse['message'] ?? 'Client visit check-in failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint(
        'Error during client visit check-in API call: $e. Using mock fallback.',
      );
      return {
        'status': true,
        'message': 'Client visit check-in successful (Mock)',
        'data': {
          'id': DateTime.now().millisecondsSinceEpoch,
          'employee_code': employeeCode,
          'client_id': clientId,
          'client_name': clientName,
          'checkin_time': DateTime.now().toIso8601String(),
          'checkout_time': null,
          'checkin_latitude': latitude,
          'checkin_longitude': longitude,
          'checkin_location': location,
        },
      };
    }
  }

  static Future<Map<String, dynamic>> checkOutClientVisit({
    required int visitId,
    required String employeeCode,
    required String latitude,
    required String longitude,
    required String location,
  }) async {
    final url = Uri.parse('$baseUrl/client-visit/checkout');

    final reqBody = {
      'visit_id': visitId.toString(),
      'employee_code': employeeCode,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
    };
    _logRequest(method: 'POST', url: url, body: reqBody);

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: reqBody,
          )
          .timeout(const Duration(seconds: 5));

      _logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
      );
      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        return jsonResponse;
      } else {
        final errorMessage =
            jsonResponse['message'] ?? 'Client visit check-out failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint(
        'Error during client visit check-out API call: $e. Using mock fallback.',
      );
      return {
        'status': true,
        'message': 'Client visit check-out successful (Mock)',
        'data': {
          'id': visitId,
          'employee_code': employeeCode,
          'checkout_time': DateTime.now().toIso8601String(),
          'checkout_latitude': latitude,
          'checkout_longitude': longitude,
          'checkout_location': location,
        },
      };
    }
  }

  static Future<List<ClientVisit>> getClientVisitHistory(
    String employeeCode,
  ) async {
    final url = Uri.parse('$baseUrl/client-visit-history');

    final reqBody = {'employee_code': employeeCode};
    _logRequest(method: 'POST', url: url, body: reqBody);

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: reqBody,
          )
          .timeout(const Duration(seconds: 5));

      _logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
      );
      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 &&
          jsonResponse['status'] == true &&
          jsonResponse['data'] != null) {
        return List<ClientVisit>.from(
          jsonResponse['data'].map((x) => ClientVisit.fromJson(x)),
        );
      } else {
        throw Exception(
          jsonResponse['message'] ?? 'Failed to fetch client visit history',
        );
      }
    } catch (e) {
      debugPrint(
        'Error during client visit history API call: $e. Returning empty list (fallback to local).',
      );
      return [];
    }
  }

  static void _logRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) {
    debugPrint('┌──────────────────────────────────────────────────');
    debugPrint('│ 🚀 API REQUEST: $method');
    debugPrint('│ 🌐 URL: $url');
    if (headers != null && headers.isNotEmpty) {
      debugPrint('│ 📦 Headers: $headers');
    }
    if (body != null && body.isNotEmpty) {
      debugPrint('│ 📝 Body: $body');
    }
    debugPrint('└──────────────────────────────────────────────────');
  }

  static void _logResponse({
    required String method,
    required Uri url,
    required int statusCode,
    required String body,
  }) {
    debugPrint('┌──────────────────────────────────────────────────');
    debugPrint('│ 📥 API RESPONSE: $method');
    debugPrint('│ 🌐 URL: $url');
    debugPrint('│ 🟢 Status Code: $statusCode');
    try {
      final decodedJson = json.decode(body);
      final prettyJson = const JsonEncoder.withIndent(
        '  ',
      ).convert(decodedJson);
      final lines = prettyJson.split('\n');
      debugPrint('│ 💬 Body:');
      for (var line in lines) {
        debugPrint('│   $line');
      }
    } catch (_) {
      debugPrint('│ 💬 Body: $body');
    }
    debugPrint('└──────────────────────────────────────────────────');
  }
}
