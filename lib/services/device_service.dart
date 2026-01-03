import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'unique_device_id';
  static final _deviceInfo = DeviceInfoPlugin();

  /// Returns the unique device ID (UUID) and the device model name.
  /// If a UUID doesn't exist, it generates one and saves it securely.
  static Future<Map<String, String>> getDeviceDetails() async {
    String? deviceId;
    String deviceModel = 'Unknown Device';

    try {
      // 1. Get or Generate Device ID
      deviceId = await _storage.read(key: _deviceIdKey);
      
      if (deviceId == null) {
        deviceId = const Uuid().v4();
        await _storage.write(key: _deviceIdKey, value: deviceId);
      }

      // 2. Get Device Model Name
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceModel = '${webInfo.browserName} on ${webInfo.platform}';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceModel = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceModel = '${iosInfo.name} (${iosInfo.systemName} ${iosInfo.systemVersion})';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceModel = 'Windows PC (${windowsInfo.computerName})';
      }
      
    } catch (e) {
      debugPrint('Error getting device details: $e');
      // Fallback if secure storage fails (unlikely but safe)
      deviceId = deviceId ?? 'fallback-id-${DateTime.now().millisecondsSinceEpoch}';
    }

    return {
      'device_id': deviceId,
      'device_model': deviceModel,
    };
  }
}
