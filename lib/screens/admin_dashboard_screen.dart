import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/report.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../utils/enums.dart';
import '../utils/report_constants.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/status_chip.dart';
import 'report_details_screen.dart';

/// Toronto centre for demo seed data.
const double _seedCenterLat = 43.6532;
const double _seedCenterLng = -79.3832;

enum _ViewMode { list, map }

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static const String routeName = '/admin-dashboard';

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  ReportStatus? _statusFilter;
  String? _categoryFilter;
  String _searchKeyword = '';
  bool _flaggedOnly = false;
  _ViewMode _viewMode = _ViewMode.list;

  static final _dateFormat = DateFormat('MMM d, y');

  List<Report> _filter(List<Report> reports) {
    return reports.where((r) {
      if (_flaggedOnly && r.status != ReportStatus.needsReview) return false;
      if (_statusFilter != null && r.status != _statusFilter) return false;
      if (_categoryFilter != null && r.category != _categoryFilter) return false;
      if (_searchKeyword.trim().isNotEmpty) {
        final k = _searchKeyword.trim().toLowerCase();
        final match = (r.description.toLowerCase().contains(k)) ||
            ((r.title ?? '').toLowerCase().contains(k)) ||
            (r.category.toLowerCase().contains(k)) ||
            (r.department.toLowerCase().contains(k));
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _seedDemoData(BuildContext context) async {
    final reportService = context.read<ReportService>();
    final uid = context.read<AppState>().currentUser?.uid;
    if (uid == null) return;

    const dept = {
      'Pothole': 'Public Works',
      'Streetlight': 'Utilities',
      'Graffiti': 'Public Works',
      'Trash': 'Sanitation',
      'Sewage': 'Public Works',
      'Other': 'General',
    };

    final items = [
      (cat: 'Pothole', lat: _seedCenterLat, lng: _seedCenterLng,
       desc: 'Large pothole on King St'),
      (cat: 'Streetlight', lat: _seedCenterLat + 0.001, lng: _seedCenterLng + 0.001,
       desc: 'Light out at intersection'),
      (cat: 'Graffiti', lat: _seedCenterLat - 0.001, lng: _seedCenterLng - 0.001,
       desc: 'Graffiti on wall'),
      (cat: 'Trash', lat: _seedCenterLat + 0.002, lng: _seedCenterLng + 0.002,
       desc: 'Dumped garbage'),
      (cat: 'Sewage', lat: _seedCenterLat - 0.002, lng: _seedCenterLng - 0.002,
       desc: 'Sewer smell'),
      (cat: 'Pothole', lat: _seedCenterLat + 0.0012, lng: _seedCenterLng + 0.0012,
       desc: 'Pothole cluster main'),
      (cat: 'Pothole', lat: _seedCenterLat + 0.00121, lng: _seedCenterLng + 0.00121,
       desc: 'Pothole cluster duplicate'),
      (cat: 'Pothole', lat: _seedCenterLat + 0.00122, lng: _seedCenterLng + 0.00122,
       desc: 'Pothole cluster duplicate'),
    ];

    final ids = <String>[];
    for (final item in items) {
      final report = await reportService.createReport(
        CreateReportData(
          description: item.desc,
          department: dept[item.cat] ?? 'General',
          category: item.cat,
          issueType: item.cat,
          locationLat: item.lat,
          locationLng: item.lng,
          createdBy: uid,
        ),
      );
      ids.add(report.id);
    }

    await reportService.updateStatus(
      reportId: ids[1],
      newStatus: ReportStatus.resolved,
      note: 'Demo seed',
      updatedBy: uid,
    );
    await reportService.updateStatus(
      reportId: ids[2],
      newStatus: ReportStatus.inProgress,
      note: 'Demo seed',
      updatedBy: uid,
    );
    await reportService.updateStatus(
      reportId: ids[3],
      newStatus: ReportStatus.needsReview,
      note: 'Demo seed – flagged',
      updatedBy: uid,
    );
    await reportService.updateStatus(
      reportId: ids[4],
      newStatus: ReportStatus.resolved,
      note: 'Demo seed',
      updatedBy: uid,
    );

    final mainId = ids[5];
    await reportService.updateReportFields(ids[6], {'duplicateOf': mainId});
    await reportService.updateReportFields(ids[7], {'duplicateOf': mainId});
    await reportService.updateReportFields(mainId, {'duplicateCount': 2});
  }

  @override
  Widget build(BuildContext context) {
    final reportService = context.read<ReportService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await context.read<AuthService>().signOut();
            },
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Logout'),
          ),
          IconButton(
            tooltip: _viewMode == _ViewMode.list ? 'Map view' : 'List view',
            icon: Icon(
              _viewMode == _ViewMode.list ? Icons.map_outlined : Icons.list,
            ),
            onPressed: () {
              setState(() {
                _viewMode =
                    _viewMode == _ViewMode.list ? _ViewMode.map : _ViewMode.list;
              });
            },
          ),
          if (kDebugMode)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value != 'seed') return;
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Seed Demo Data'),
                    content: const Text(
                      'Create 8 sample reports around Toronto with mixed statuses, '
                      'a duplicate cluster, and 1 flagged (Needs Review)?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Seed'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await _seedDemoData(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Demo data seeded')),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'seed',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.science),
                    title: Text('Seed Demo Data'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: StreamBuilder<List<Report>>(
        stream: reportService.getAllReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading reports…');
          }
          if (snapshot.hasError) {
            return const ErrorView(
              message: 'Could not load reports. Please try again.',
            );
          }
          final allReports = snapshot.data ?? [];
          final reports = _filter(allReports);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FiltersSection(
                        statusFilter: _statusFilter,
                        categoryFilter: _categoryFilter,
                        searchKeyword: _searchKeyword,
                        flaggedOnly: _flaggedOnly,
                        onStatusChanged: (v) => setState(() => _statusFilter = v),
                        onCategoryChanged: (v) => setState(() => _categoryFilter = v),
                        onSearchChanged: (v) => setState(() => _searchKeyword = v),
                        onFlaggedToggled: () =>
                            setState(() => _flaggedOnly = !_flaggedOnly),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          '${reports.length} report${reports.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                  child: _viewMode == _ViewMode.list
                      ? _ReportList(reports: reports, dateFormat: _dateFormat)
                      : _ReportMap(reports: reports),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FiltersSection extends StatelessWidget {
  const _FiltersSection({
    required this.statusFilter,
    required this.categoryFilter,
    required this.searchKeyword,
    required this.flaggedOnly,
    required this.onStatusChanged,
    required this.onCategoryChanged,
    required this.onSearchChanged,
    required this.onFlaggedToggled,
  });

  final ReportStatus? statusFilter;
  final String? categoryFilter;
  final String searchKeyword;
  final bool flaggedOnly;
  final ValueChanged<ReportStatus?> onStatusChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFlaggedToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width - 24;
              return SizedBox(
                width: maxW,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.hardEdge,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FilterChip(
                        label: const Text('Flagged / Needs Review'),
                        selected: flaggedOnly,
                        onSelected: (_) => onFlaggedToggled(),
                        selectedColor: colorScheme.primaryContainer,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: DropdownButtonFormField<ReportStatus?>(
                            value: statusFilter,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              isDense: true,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All'),
                              ),
                              ...ReportStatus.values.map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.value),
                                ),
                              ),
                            ],
                            onChanged: onStatusChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<String?>(
                            value: categoryFilter,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              isDense: true,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All'),
                              ),
                              ...reportCategories.map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ),
                              ),
                            ],
                            onChanged: onCategoryChanged,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Search',
              hintText: 'Keyword…',
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              filled: true,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({
    required this.reports,
    required this.dateFormat,
  });

  final List<Report> reports;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
        if (reports.isEmpty) {
          return const EmptyState(
            title: 'No reports match filters',
            subtitle: 'Try changing filters or add new reports.',
          );
        }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final r = reports[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    r.category,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                StatusChip(status: r.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  r.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MetaChip(
                      icon: Icons.flag,
                      label: '${r.priorityScore}',
                    ),
                    const SizedBox(width: 8),
                    _MetaChip(
                      icon: Icons.copy,
                      label: '${r.duplicateCount} dup',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(r.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => _openDetails(context, r.id),
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _ReportMap extends StatelessWidget {
  const _ReportMap({required this.reports});

  final List<Report> reports;

  double _markerHue(ReportStatus status) {
    return switch (status) {
      ReportStatus.reported => BitmapDescriptor.hueRed,
      ReportStatus.inProgress => BitmapDescriptor.hueOrange,
      ReportStatus.resolved => BitmapDescriptor.hueGreen,
      ReportStatus.needsReview => BitmapDescriptor.hueViolet,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const EmptyState(
        title: 'No reports to show on map',
        subtitle: 'Try changing filters.',
      );
    }

    final first = reports.first;
    final center = LatLng(first.locationLat, first.locationLng);
    final markers = reports.map((r) {
      return Marker(
        markerId: MarkerId(r.id),
        position: LatLng(r.locationLat, r.locationLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(r.status)),
        onTap: () => _openDetails(context, r.id),
      );
    }).toSet();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: center,
          zoom: 12,
        ),
        markers: markers,
        liteModeEnabled: false,
        onMapCreated: (controller) {
          if (reports.length > 1) {
            _fitBounds(controller, reports);
          }
        },
      ),
    );
  }

  void _fitBounds(GoogleMapController controller, List<Report> reports) {
    if (reports.isEmpty) return;
    double minLat = reports.first.locationLat;
    double maxLat = minLat;
    double minLng = reports.first.locationLng;
    double maxLng = minLng;
    for (final r in reports) {
      if (r.locationLat < minLat) minLat = r.locationLat;
      if (r.locationLat > maxLat) maxLat = r.locationLat;
      if (r.locationLng < minLng) minLng = r.locationLng;
      if (r.locationLng > maxLng) maxLng = r.locationLng;
    }
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        48,
      ),
    );
  }
}

void _openDetails(BuildContext context, String reportId) {
  Navigator.pushNamed(
    context,
    ReportDetailsScreen.routeName,
    arguments: reportId,
  );
}
