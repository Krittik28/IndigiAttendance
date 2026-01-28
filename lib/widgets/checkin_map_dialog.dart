import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CheckInMapDialog extends StatefulWidget {
  final LatLng userLocation;
  final LatLng officeLocation;
  final double distance;
  final bool isWithinRange;
  final VoidCallback onConfirm;

  const CheckInMapDialog({
    super.key,
    required this.userLocation,
    required this.officeLocation,
    required this.distance,
    required this.isWithinRange,
    required this.onConfirm,
  });

  @override
  State<CheckInMapDialog> createState() => _CheckInMapDialogState();
}

class _CheckInMapDialogState extends State<CheckInMapDialog> {
  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    // Determine bounds to show both points
    LatLngBounds bounds;
    if (widget.userLocation.latitude > widget.officeLocation.latitude &&
        widget.userLocation.longitude > widget.officeLocation.longitude) {
      bounds = LatLngBounds(
        southwest: widget.officeLocation,
        northeast: widget.userLocation,
      );
    } else if (widget.userLocation.longitude > widget.officeLocation.longitude) {
      bounds = LatLngBounds(
        southwest: LatLng(widget.userLocation.latitude, widget.officeLocation.longitude),
        northeast: LatLng(widget.officeLocation.latitude, widget.userLocation.longitude),
      );
    } else if (widget.userLocation.latitude > widget.officeLocation.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(widget.officeLocation.latitude, widget.userLocation.longitude),
        northeast: LatLng(widget.userLocation.latitude, widget.officeLocation.longitude),
      );
    } else {
      bounds = LatLngBounds(
        southwest: widget.userLocation,
        northeast: widget.officeLocation,
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isWithinRange 
                        ? Colors.green.withValues(alpha: 0.1) 
                        : Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isWithinRange ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: widget.isWithinRange ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isWithinRange ? 'You are in range' : 'You are out of range',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Distance: ${widget.distance.toStringAsFixed(0)}m (Max 20m)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
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
            height: 300,
            width: double.infinity,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.officeLocation,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                mapController = controller;
                // Fit bounds with more padding (100) to zoom out
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngBounds(bounds, 100),
                    );
                  }
                });
              },
              markers: {
                Marker(
                  markerId: const MarkerId('office'),
                  position: widget.officeLocation,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  infoWindow: const InfoWindow(title: 'Indigi Office'),
                ),
                Marker(
                  markerId: const MarkerId('user'),
                  position: widget.userLocation,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    widget.isWithinRange ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed
                  ),
                  infoWindow: const InfoWindow(title: 'Your Location'),
                ),
              },
              circles: {
                Circle(
                  circleId: const CircleId('geofence'),
                  center: widget.officeLocation,
                  radius: 20, // 20 meters
                  fillColor: Colors.blue.withValues(alpha: 0.25),
                  strokeColor: Colors.blue.withValues(alpha: 0.6),
                  strokeWidth: 2,
                ),
              },
              myLocationEnabled: false,
              zoomControlsEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.isWithinRange ? widget.onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isWithinRange ? const Color(0xFF4CAF50) : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  widget.isWithinRange ? 'CONFIRM CHECK-IN' : 'CANNOT CHECK IN',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
