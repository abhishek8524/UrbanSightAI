import 'package:geolocator/geolocator.dart';

/// Result of attempting to get the current location.
sealed class LocationResult {}

class LocationSuccess extends LocationResult {
  LocationSuccess(this.position);
  final Position position;
}

class LocationDenied extends LocationResult {
  LocationDenied(this.message);
  final String message;
}

/// Requests permission and returns current position.
/// Returns [LocationDenied] if permission denied or location unavailable.
Future<LocationResult> getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return LocationDenied('Location services are disabled.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    return LocationDenied('Location permission denied.');
  }
  if (permission == LocationPermission.deniedForever) {
    return LocationDenied(
      'Location permission permanently denied. Open app settings to enable.',
    );
  }

  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    return LocationSuccess(position);
  } catch (e) {
    return LocationDenied(e.toString());
  }
}

/// Returns true if app can open location settings.
Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
