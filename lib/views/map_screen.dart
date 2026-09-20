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
  late LatLng _selectedPosition; // Now mutable to track tap/drag
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
      _selectedPosition = LatLng(locationState.latitude!, locationState.longitude!);
    } else {
      // Default to Tehran
      _selectedPosition = const LatLng(35.6892, 51.3890);
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
        setState(() {
          _selectedPosition = targetPos!;
        });
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
              initialCenter: _selectedPosition,
              initialZoom: 15,
              onMapReady: () {
                if (mounted) {
                  setState(() {
                    _isMapReady = true;
                  });
                }
              },
              // Allow selection by tapping anywhere
              onTap: (tapPosition, latLng) {
                setState(() {
                  _selectedPosition = latLng;
                });
              },
              // Keep pin synchronized if map is dragged
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _selectedPosition = position.center;
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

              MarkerLayer(
                markers: [
                  // 1. Blue Dot for live GPS location
                  if (locationState.liveLatitude != null &&
                      locationState.liveLongitude != null &&
                      locationState.liveLatitude!.isFinite &&
                      locationState.liveLongitude!.isFinite)
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

                  // 2. Selection Pin (Dynamic Marker)
                  if (_isMapReady)
                    Marker(
                      point: _selectedPosition,
                      width: 60.r,
                      height: 80.r,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 40.r,
                              color: Colors.redAccent,
                            ),
                          ),
                          Container(
                            width: 3.w,
                            height: 12.h,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(2.r),
                                bottomRight: Radius.circular(2.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
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
                    Icon(Icons.touch_app, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'برای انتخاب مکان، روی نقشه بزنید یا نقشه را بکشید.',
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
    if (_selectedPosition.latitude.isFinite && _selectedPosition.longitude.isFinite) {
      ref
          .read(locationProvider.notifier)
          .updateManualLocation(_selectedPosition.latitude, _selectedPosition.longitude);

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
