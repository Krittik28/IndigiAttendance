import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<Map<String, String>> getCurrentLocation() async {
    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in settings.');
    }

    // Get current position with retry mechanism
    Position? position;
    int attempts = 0;
    const int maxAttempts = 3;
    
    while (position == null && attempts < maxAttempts) {
      try {
        attempts++;
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        print('Location fetch attempt $attempts failed: $e');
        if (attempts >= maxAttempts) {
          throw Exception('Unable to fetch location after $maxAttempts attempts. Please check your GPS signal.');
        }
        // Small delay before retrying
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (position != null) {
      // Get address from coordinates
      return await _getLocationWithAddress(
        position.latitude, 
        position.longitude
      );
    } else {
      throw Exception('Unable to fetch location.');
    }
  }

  static Future<Map<String, String>> _getLocationWithAddress(
    double latitude, 
    double longitude
  ) async {
    try {
      // Get placemarks from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      String address = 'Unknown Location';
      String shortAddress = 'Unknown Location';

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        address = _buildAddressFromPlacemark(place);
        shortAddress = _buildShortAddressFromPlacemark(place);
      } else {
        // If no placemarks, use coordinates
        address = 'Lat: ${latitude.toStringAsFixed(4)}, Long: ${longitude.toStringAsFixed(4)}';
        shortAddress = address;
      }

      return {
        'latitude': latitude.toStringAsFixed(6),
        'longitude': longitude.toStringAsFixed(6),
        'location': address,
        'shortLocation': shortAddress,
      };
    } catch (e) {
      print('Address lookup error: $e');
      // Fallback to coordinates
      return {
        'latitude': latitude.toStringAsFixed(6),
        'longitude': longitude.toStringAsFixed(6),
        'location': 'Lat: ${latitude.toStringAsFixed(4)}, Long: ${longitude.toStringAsFixed(4)}',
        'shortLocation': 'Lat: ${latitude.toStringAsFixed(4)}, Long: ${longitude.toStringAsFixed(4)}',
      };
    }
  }

  static String _buildShortAddressFromPlacemark(Placemark place) {
    List<String> parts = [];
    
    // Helper to check if a string is a Plus Code
    bool isPlusCode(String? text) {
      if (text == null || text.isEmpty) return false;
      return text.contains('+') && text.length < 15;
    }

    if (place.street != null && place.street!.isNotEmpty && !isPlusCode(place.street)) {
      parts.add(place.street!);
    } else if (place.name != null && place.name!.isNotEmpty && !isPlusCode(place.name)) {
      parts.add(place.name!);
    }
    
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      if (!parts.contains(place.subLocality)) parts.add(place.subLocality!);
    }

    if (parts.length < 2 && place.locality != null && place.locality!.isNotEmpty) {
      if (!parts.contains(place.locality)) parts.add(place.locality!);
    }

    if (parts.isNotEmpty) {
      return parts.take(2).join(', ');
    }
    
    return 'Unknown Location';
  }

  static String _buildAddressFromPlacemark(Placemark place) {
    List<String> addressParts = [];

    // Helper to check if a string is a Plus Code (e.g., "4RMH+5VQ")
    bool isPlusCode(String? text) {
      if (text == null || text.isEmpty) return false;
      // Simple check: contains '+' and is short (usually < 15 chars)
      return text.contains('+') && text.length < 15;
    }

    // 1. Street / Name (Avoid Plus Codes here if possible)
    if (place.street != null && place.street!.isNotEmpty && !isPlusCode(place.street)) {
      addressParts.add(place.street!);
    } else if (place.name != null && place.name!.isNotEmpty && !isPlusCode(place.name)) {
       // Sometimes 'name' has the building name while 'street' has the Plus Code
       addressParts.add(place.name!);
    }

    // 2. SubLocality (Neighborhood/Area)
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      // Avoid duplication if street already contains sublocality
      if (!addressParts.contains(place.subLocality)) {
        addressParts.add(place.subLocality!);
      }
    }

    // 3. Locality (City)
    if (place.locality != null && place.locality!.isNotEmpty) {
      if (!addressParts.contains(place.locality)) {
        addressParts.add(place.locality!);
      }
    }

    // 4. Administrative Area (State) - Optional, keeps it shorter
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }

    // 5. Postal Code
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      addressParts.add(place.postalCode!);
    }

    // If we have valid parts, join them
    if (addressParts.isNotEmpty) {
      return addressParts.join(', ');
    }

    // Fallback: If absolutely nothing else, use the Plus Code or Name
    if (place.name != null && place.name!.isNotEmpty) {
      return place.name!;
    }
    if (place.street != null && place.street!.isNotEmpty) {
      return place.street!;
    }

    return 'Unknown Location';
  }
}