import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:neshan_maps_flutter/map.dart';

import '../controllers/location_controller.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final NeshanMapController _mapController = NeshanMapController();
  bool _isMapReady = false;
  LatLng? _currentCenter;

  // Swap this with your actual Neshan web map key from platform.neshan.org
  static const String _neshanWebKey = 'web.9eac8e1b3e014635b3215228ad201b3c';

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    await _mapController.ready;
    if (mounted) {
      setState(() {
        _isMapReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationState = ref.watch(locationProvider);

    // Initial center coordinates
    final initialLat = locationState.latitude ?? 35.6892;
    final initialLng = locationState.longitude ?? 51.3890;

    // Set initial center if not already set
    _currentCenter ??= LatLng(initialLat, initialLng);

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
          // Neshan Map Widget
          NeshanMap(
            mapKey: _neshanWebKey,
            controller: _mapController,
            onLocationChanged: (double lat, double lng) {
              _currentCenter = LatLng(lat, lng);
            },
            config: NeshanMapConfig(
              mapType: NeshanMapType.neshanRaster,
              initialCenter: LatLng(initialLat, initialLng),
              initialZoom: 15.0,
              showTraffic: false,
            ),
          ),

          // Central Pin Overlay
          if (_isMapReady)
            Align(
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
      // Use the tracked center coordinate
      final center = _currentCenter;

      if (center != null) {
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
      } else {
        // Fallback if _currentCenter is somehow null
        await _mapController.ready;
        final LatLng? fallbackCenter = await _mapController.getCurrentLocation();
        if (fallbackCenter != null) {
          ref.read(locationProvider.notifier).updateManualLocation(fallbackCenter.latitude, fallbackCenter.longitude);
          if (mounted) Navigator.of(context).pop();
        }
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
