import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _employeeCodeKey = 'employee_code';
  static const String _passwordKey = 'password';

  // Save user login data
  static Future<void> saveUserData({
    required String employeeCode,
    required String password,
    required String userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_employeeCodeKey, employeeCode);
    await prefs.setString(_passwordKey, password);
    await prefs.setString(_userKey, userData);
  }

  // Get saved user data
  static Future<Map<String, String>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    
    if (!isLoggedIn) {
      return null;
    }

    final employeeCode = prefs.getString(_employeeCodeKey);
    final password = prefs.getString(_passwordKey);
    final userData = prefs.getString(_userKey);

    if (employeeCode == null || password == null || userData == null) {
      return null;
    }

    return {
      'employeeCode': employeeCode,
      'password': password,
      'userData': userData,
    };
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Clear user data on logout
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_employeeCodeKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_userKey);
  }

  // Save only the login state without sensitive data (for auto-login)
  static Future<void> saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }
}