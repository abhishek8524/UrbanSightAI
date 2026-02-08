import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/report_service.dart';
import '../utils/location_helper.dart';
import '../utils/report_constants.dart';
import 'report_details_screen.dart';

const Map<String, String> categoryToDepartment = {
  'Pothole': 'Public Works',
  'Streetlight': 'Utilities',
  'Graffiti': 'Public Works',
  'Trash': 'Sanitation',
  'Sewage': 'Public Works',
  'Other': 'General',
};

const double _defaultMapLat = 37.7749;
const double _defaultMapLng = -122.4194;

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key, this.inShell = false});

  static const String routeName = '/report-issue';

  final bool inShell;

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _category;
  Uint8List? _photoBytes;
  LatLng? _pin;
  bool _submitting = false;
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _descriptionController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  bool get _isSuspended {
    final user = context.read<AppState>().appUser;
    if (user?.suspendedUntil == null) return false;
    return DateTime.now().isBefore(user!.suspendedUntil!);
  }

  String get _department => _category != null
      ? (categoryToDepartment[_category!] ?? 'General')
      : '';

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source);
    if (xFile != null && mounted) {
      final bytes = await xFile.readAsBytes();
      if (mounted) setState(() => _photoBytes = bytes);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useMyLocation() async {
    final result = await getCurrentLocation();
    if (result is LocationSuccess && mounted) {
      setState(() {
        _pin = LatLng(result.position.latitude, result.position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_pin!),
      );
    }
  }

  Future<void> _submit() async {
    if (_isSuspended) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account is suspended. You cannot submit reports.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_category == null || _category!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_photoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a photo')),
      );
      return;
    }
    if (_pin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a location on the map')),
      );
      return;
    }

    final appState = context.read<AppState>();
    final uid = appState.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to report')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final reportService = context.read<ReportService>();
      final report = await reportService.createReport(
        CreateReportData(
          description: _descriptionController.text.trim(),
          department: _department,
          category: _category!,
          issueType: _category!,
          locationLat: _pin!.latitude,
          locationLng: _pin!.longitude,
          createdBy: uid,
        ),
        imageBytes: _photoBytes,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSuccessDialog(report.id);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }

  void _showSuccessDialog(String reportId) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Report submitted'),
        content: Text('Report ID: $reportId'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(
                context,
                ReportDetailsScreen.routeName,
                arguments: reportId,
              );
            },
            child: const Text('View report'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: reportCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v),
            validator: (v) => (v == null || v.isEmpty) ? 'Select a category' : null,
          ),
          const SizedBox(height: 12),
          if (_department.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Department: $_department',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe the issue',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a description' : null,
          ),
          const SizedBox(height: 16),
          const Text('Photo', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_photoBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _photoBytes!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _photoPreviewPlaceholder(),
                  ),
                ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: _showPhotoOptions,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(_photoLabel),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Location', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _pin ?? const LatLng(_defaultMapLat, _defaultMapLng),
                      zoom: 14,
                    ),
                    onMapCreated: (c) => _mapController = c,
                    onTap: (latLng) => setState(() => _pin = latLng),
                    markers: _pin != null
                        ? {
                            Marker(
                              markerId: const MarkerId('pin'),
                              position: _pin!,
                            ),
                          }
                        : {},
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: FilledButton.tonalIcon(
                      onPressed: _useMyLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use my location'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit report'),
          ),
        ],
      ),
    );
  }

  String get _photoLabel => _photoBytes != null ? 'Change photo' : 'Add photo';

  Widget _photoPreviewPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.inShell) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: body,
    );
  }
}
