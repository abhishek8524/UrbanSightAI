import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/report.dart';
import '../services/report_service.dart';
import '../utils/enums.dart';
import '../utils/location_helper.dart';
import '../widgets/loading_view.dart';
import 'report_details_screen.dart';

/// Default map center when location is unavailable (e.g. San Francisco).
const double _defaultLat = 37.7749;
const double _defaultLng = -122.4194;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.inShell = false});

  static const String routeName = '/home';

  final bool inShell;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LocationResult? _locationResult;
  List<Report> _reports = [];
  StreamSubscription<List<Report>>? _reportsSub;
  GoogleMapController? _mapController;
  bool _reportsListening = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() => _locationResult = null);
    final result = await getCurrentLocation();
    if (mounted) setState(() => _locationResult = result);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_reportsListening) {
      _reportsListening = true;
      _reportsSub = context.read<ReportService>().getAllReports().listen(
        (reports) {
          if (mounted) setState(() => _reports = reports);
        },
        onError: (_) {
          if (mounted) setState(() => _reports = []);
        },
      );
    }
  }

  @override
  void dispose() {
    _reportsSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  LatLng get _center {
    final r = _locationResult;
    if (r is LocationSuccess) {
      return LatLng(r.position.latitude, r.position.longitude);
    }
    return const LatLng(_defaultLat, _defaultLng);
  }

  Set<Marker> get _markers {
    return _reports.map((r) {
      final hue = _markerHueForStatus(r.status);
      return Marker(
        markerId: MarkerId(r.id),
        position: LatLng(r.locationLat, r.locationLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        onTap: () {
          Navigator.pushNamed(
            context,
            ReportDetailsScreen.routeName,
            arguments: r.id,
          );
        },
      );
    }).toSet();
  }

  double _markerHueForStatus(ReportStatus status) {
    return switch (status) {
      ReportStatus.reported => BitmapDescriptor.hueRed,
      ReportStatus.inProgress => BitmapDescriptor.hueOrange,
      ReportStatus.resolved => BitmapDescriptor.hueGreen,
      ReportStatus.needsReview => BitmapDescriptor.hueViolet,
    };
  }

  Widget _buildBody(BuildContext context) {
    if (_locationResult == null) {
      return const LoadingView(message: 'Getting your location…');
    }

    if (_locationResult is LocationDenied) {
      final msg = (_locationResult as LocationDenied).message;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await openLocationSettings();
                  _loadLocation();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open settings'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadLocation,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 14,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            if (_locationResult is LocationSuccess) {
              controller.animateCamera(
                CameraUpdate.newLatLng(_center),
              );
            }
          },
          markers: _markers,
          myLocationEnabled: _locationResult is LocationSuccess,
          myLocationButtonEnabled: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.inShell) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: body,
    );
  }
}
