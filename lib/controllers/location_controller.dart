import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationState {
  final double? latitude;
  final double? longitude;
  final bool isFetching;
  final String? errorMessage;
  final String address;

  LocationState({
    this.latitude,
    this.longitude,
    this.isFetching = false,
    this.errorMessage,
    this.address = '',
  });

  LocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isFetching,
    String? errorMessage,
    String? address,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isFetching: isFetching ?? this.isFetching,
      errorMessage: errorMessage ?? this.errorMessage,
      address: address ?? this.address,
    );
  }
}

class LocationController extends StateNotifier<LocationState> {
  LocationController() : super(LocationState());
  StreamSubscription<Position>? _positionStreamSubscription;

  Future<void> fetchCurrentLocation() async {
    state = state.copyWith(isFetching: true, errorMessage: null);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isFetching: false,
          errorMessage: 'خدمات مکان‌یابی غیرفعال است. لطفا GPS خود را روشن کنید.',
        );
        return;
      }

      var status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
      }

      if (!status.isGranted) {
        state = state.copyWith(
          isFetching: false,
          errorMessage: 'مجوز دسترسی به مکان داده نشد.',
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        isFetching: false,
      );
    } catch (e) {
      state = state.copyWith(
        isFetching: false,
        errorMessage: 'خطا در دریافت موقعیت مکانی: $e',
      );
    }
  }

  void startLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    });
  }

  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void updateManualLocation(double lat, double lng) {
    state = state.copyWith(
      latitude: lat,
      longitude: lng,
      errorMessage: null,
    );
  }

  void updateAddress(String address) {
    state = state.copyWith(address: address);
  }

  void clearLocation() {
    state = LocationState();
  }
}

final locationProvider = StateNotifierProvider<LocationController, LocationState>((ref) {
  return LocationController();
});
