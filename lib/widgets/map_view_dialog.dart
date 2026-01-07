import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapViewDialog extends StatelessWidget {
  final LatLng? checkinLocation;
  final LatLng? checkoutLocation;
  final String title;

  const MapViewDialog({
    super.key,
    this.checkinLocation,
    this.checkoutLocation,
    this.title = 'Location',
  });

  @override
  Widget build(BuildContext context) {
    // Determine camera position
    LatLng center;
    double zoom = 15.0;
    bool isOverlapping = false;

    if (checkinLocation != null && checkoutLocation != null) {
      // Check for overlap (approx within 11 meters)
      if ((checkinLocation!.latitude - checkoutLocation!.latitude).abs() < 0.0001 &&
          (checkinLocation!.longitude - checkoutLocation!.longitude).abs() < 0.0001) {
        isOverlapping = true;
      }

      center = LatLng(
        (checkinLocation!.latitude + checkoutLocation!.latitude) / 2,
        (checkinLocation!.longitude + checkoutLocation!.longitude) / 2,
      );
      zoom = isOverlapping ? 16.0 : 13.0;
    } else if (checkinLocation != null) {
      center = checkinLocation!;
    } else if (checkoutLocation != null) {
      center = checkoutLocation!;
    } else {
      center = const LatLng(0, 0);
    }

    final markers = <Marker>{};
    if (checkinLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('checkin'),
          position: checkinLocation!,
          infoWindow: const InfoWindow(title: 'Check-in Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    if (checkoutLocation != null) {
      LatLng displayPos = checkoutLocation!;
      if (isOverlapping) {
        // Offset slightly if overlapping so both are visible
        displayPos = LatLng(
          checkoutLocation!.latitude + 0.0001,
          checkoutLocation!.longitude + 0.0001,
        );
      }
      markers.add(
        Marker(
          markerId: const MarkerId('checkout'),
          position: displayPos,
          infoWindow: const InfoWindow(title: 'Check-out Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (checkinLocation != null) ...[
                             const Icon(Icons.location_on, color: Colors.green, size: 12),
                             const SizedBox(width: 4),
                             const Text('Check-in', style: TextStyle(fontSize: 12)),
                             const SizedBox(width: 12),
                          ],
                          if (checkoutLocation != null) ...[
                             const Icon(Icons.location_on, color: Colors.orange, size: 12),
                             const SizedBox(width: 4),
                             const Text('Check-out', style: TextStyle(fontSize: 12)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // Map
          SizedBox(
            height: 400,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: center,
                  zoom: zoom,
                ),
                markers: markers,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}