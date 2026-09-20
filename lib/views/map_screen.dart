import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/location_controller.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapController _mapController;
  late final LatLng _initialPosition;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Initialize position from provider once
    final locationState = ref.read(locationProvider);
    if (locationState.latitude != null &&
        locationState.longitude != null &&
        locationState.latitude!.isFinite &&
        locationState.longitude!.isFinite) {
      _initialPosition = LatLng(locationState.latitude!, locationState.longitude!);
    } else {
      // Default to Tehran
      _initialPosition = const LatLng(35.6892, 51.3890);
    }

    // Start live location updates for the blue dot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).startLocationUpdates();
    });
  }

  @override
  void dispose() {
    // Stop updates when leaving map
    ref.read(locationProvider.notifier).stopLocationUpdates();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final locationState = ref.read(locationProvider);
      LatLng? targetPos;

      if (locationState.liveLatitude != null &&
          locationState.liveLongitude != null &&
          locationState.liveLatitude!.isFinite &&
          locationState.liveLongitude!.isFinite) {
        targetPos = LatLng(locationState.liveLatitude!, locationState.liveLongitude!);
      } else {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (position.latitude.isFinite && position.longitude.isFinite) {
          targetPos = LatLng(position.latitude, position.longitude);
        }
      }

      if (targetPos != null) {
        _mapController.move(targetPos, 15);
      } else {
        throw Exception('موقعیت نامعتبر است.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در یافتن موقعیت شما: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('انتخاب موقعیت روی نقشه'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: locationState.isFetching ? null : _moveToCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 15,
              onMapReady: () {
                if (mounted) {
                  setState(() {
                    _isMapReady = true;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://core-sat.maps.yandex.net/tiles?l=sat&x={x}&y={y}&z={z}&scale=1',
                userAgentPackageName: 'com.example.kargah_yab',
              ),

              // Blue Dot for live GPS location
              if (locationState.liveLatitude != null &&
                  locationState.liveLongitude != null &&
                  locationState.liveLatitude!.isFinite &&
                  locationState.liveLongitude!.isFinite)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(locationState.liveLatitude!, locationState.liveLongitude!),
                      width: 20.r,
                      height: 20.r,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 12.r,
                            height: 12.r,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Central Pin Overlay
          if (_isMapReady)
            IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
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
    final camera = _mapController.camera;
    final center = camera.center;

    if (center.latitude.isFinite && center.longitude.isFinite) {
      ref.read(locationProvider.notifier).updateManualLocation(center.latitude, center.longitude);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('موقعیت جدید با موفقیت ثبت شد.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('موقعیت انتخاب شده معتبر نیست.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
