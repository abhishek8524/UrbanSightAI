import 'dart:math' show cos, pi, sin, sqrt, atan2;

/// Earth radius in meters (WGS84 approximate).
const double earthRadiusMeters = 6371000;

/// Haversine distance between two points in meters.
/// [lat1], [lon1] and [lat2], [lon2] are in degrees.
double haversineDistanceMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusMeters * c;
}

double _toRadians(double degrees) => degrees * (pi / 180);
