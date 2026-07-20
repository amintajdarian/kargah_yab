import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/location_controller.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late MapController _mapController;
  bool _isMapReady = false;
  GeoPoint? _currentCenter;

  @override
  void initState() {
    super.initState();
    final locationState = ref.read(locationProvider);
    _mapController = MapController(
      initPosition: GeoPoint(
        latitude: locationState.latitude ?? 35.6892,
        longitude: locationState.longitude ?? 51.3890,
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationState = ref.watch(locationProvider);

    // Initial center coordinates
    final initialLat = locationState.latitude ?? 35.6892;
    final initialLng = locationState.longitude ?? 51.3890;

    return Scaffold(
      appBar: AppBar(
        title: const Text('انتخاب موقعیت روی نقشه'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // OSM Map Widget
          OSMFlutter(
            controller: _mapController,
            onMapIsReady: (isReady) {
              if (isReady) {
                setState(() {
                  _isMapReady = true;
                });
              }
            },
            osmOption: OSMOption(
              userLocationMarker: UserLocationMaker(
                personMarker: const MarkerIcon(
                  icon: Icon(Icons.location_history, color: Colors.blue, size: 48),
                ),
                directionArrowMarker: const MarkerIcon(icon: Icon(Icons.double_arrow, size: 48)),
              ),
              zoomOption: const ZoomOption(
                initZoom: 15,
                minZoomLevel: 3,
                maxZoomLevel: 19,
                stepZoom: 1.0,
              ),
              userTrackingOption: const UserTrackingOption(
                enableTracking: true,
                unFollowUser: false,
              ),
              roadConfiguration: const RoadOption(roadColor: Colors.blueAccent),
            ),
          ),

          // Central Pin Overlay
          if (_isMapReady)
            IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24.h), // Adjust for pin bottom alignment
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 48.r,
                    color: Colors.redAccent,
                    shadows: const [
                      Shadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),

          // Top Info Banner
          Positioned(
            top: 16.h,
            left: 16.w,
            right: 16.w,
            child: Card(
              color: theme.colorScheme.surface.withOpacity(0.9),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'نقشه را بکشید تا مرکز آن روی مکان مورد نظر تنظیم شود.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Button
          Positioned(
            bottom: 24.h,
            left: 24.w,
            right: 24.w,
            child: ElevatedButton.icon(
              onPressed: _isMapReady ? _confirmLocation : null,
              icon: const Icon(Icons.gps_fixed, color: Colors.white),
              label: const Text('تایید و ثبت موقعیت'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shadowColor: Colors.black45,
                elevation: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLocation() async {
    try {
      // Get the current center from the map controller
      final center = await _mapController.centerMap;

      // Update the location state globally
      ref.read(locationProvider.notifier).updateManualLocation(center.latitude, center.longitude);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('موقعیت جدید با موفقیت ثبت شد.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        // Return to the previous screen (FormScreen)
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در دریافت موقعیت از نقشه: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
