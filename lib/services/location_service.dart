import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<Map<String, String>> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await _getLocationWithAddress(26.1445, 91.7362); // Default to Guwahati
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await _getLocationWithAddress(26.1445, 91.7362);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return await _getLocationWithAddress(26.1445, 91.7362);
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Get address from coordinates
      return await _getLocationWithAddress(
        position.latitude, 
        position.longitude
      );
    } catch (e) {
      print('Location error: $e');
      return await _getLocationWithAddress(26.1445, 91.7362);
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

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        address = _buildAddressFromPlacemark(place);
      } else {
        // If no placemarks, use coordinates
        address = 'Lat: ${latitude.toStringAsFixed(4)}, Long: ${longitude.toStringAsFixed(4)}';
      }

      return {
        'latitude': latitude.toStringAsFixed(6),
        'longitude': longitude.toStringAsFixed(6),
        'location': address,
      };
    } catch (e) {
      print('Address lookup error: $e');
      // Fallback to coordinates
      return {
        'latitude': latitude.toStringAsFixed(6),
        'longitude': longitude.toStringAsFixed(6),
        'location': 'Lat: ${latitude.toStringAsFixed(4)}, Long: ${longitude.toStringAsFixed(4)}',
      };
    }
  }

  static String _buildAddressFromPlacemark(Placemark place) {
    List<String> addressParts = [];

    // Add street address
    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }

    // Add sublocality (area)
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }

    // Add locality (city)
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }

    // Add administrative area (state)
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }

    // Add postal code
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      addressParts.add(place.postalCode!);
    }

    // Add country
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }

    // If we have address parts, join them
    if (addressParts.isNotEmpty) {
      return addressParts.join(', ');
    }

    // Fallback to individual components
    if (place.name != null && place.name!.isNotEmpty) {
      return place.name!;
    }

    return 'Unknown Location';
  }
}