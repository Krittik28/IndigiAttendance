import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
    // Determine center and zoom
    LatLng center;
    double zoom = 15.0;

    if (checkinLocation != null && checkoutLocation != null) {
      // Center between points
      center = LatLng(
        (checkinLocation!.latitude + checkoutLocation!.latitude) / 2,
        (checkinLocation!.longitude + checkoutLocation!.longitude) / 2,
      );
      // Adjust zoom could be calculated, but 13 is a safe bet for city-level separation
      zoom = 13.0;
    } else if (checkinLocation != null) {
      center = checkinLocation!;
    } else if (checkoutLocation != null) {
      center = checkoutLocation!;
    } else {
      center = const LatLng(0, 0); // Fallback
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
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: zoom,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.indigi.attendance',
                  ),
                  MarkerLayer(
                    markers: [
                      if (checkinLocation != null)
                        Marker(
                          point: checkinLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                      if (checkoutLocation != null)
                        Marker(
                          point: checkoutLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.orange,
                            size: 40,
                          ),
                        ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}