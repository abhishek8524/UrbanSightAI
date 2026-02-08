import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/report.dart';
import '../services/app_state.dart';
import '../utils/enums.dart';
import '../services/report_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/status_chip.dart';
import 'report_details_screen.dart';

/// Sample reports with pictures shown when the user has no reports yet.
List<Report> _sampleReports(String uid) {
  final now = DateTime.now();
  return [
    Report(
      id: 'sample-1',
      description: 'Large pothole near the intersection causing damage to vehicles.',
      department: 'Public Works',
      category: 'Pothole',
      issueType: 'Pothole',
      photoUrl: 'https://picsum.photos/seed/pothole1/400/300',
      locationLat: 37.7749,
      locationLng: -122.4194,
      locationAddress: 'Sample St & Main Ave',
      status: ReportStatus.reported,
      createdBy: uid,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(days: 2)),
    ),
    Report(
      id: 'sample-2',
      description: 'Streetlight out for over a week. Dark and unsafe at night.',
      department: 'Utilities',
      category: 'Streetlight',
      issueType: 'Streetlight',
      photoUrl: 'https://picsum.photos/seed/streetlight1/400/300',
      locationLat: 37.7755,
      locationLng: -122.4188,
      locationAddress: 'Oak Street',
      status: ReportStatus.inProgress,
      createdBy: uid,
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
    Report(
      id: 'sample-3',
      description: 'Graffiti on the side of the community center building.',
      department: 'Public Works',
      category: 'Graffiti',
      issueType: 'Graffiti',
      photoUrl: 'https://picsum.photos/seed/graffiti1/400/300',
      locationLat: 37.7739,
      locationLng: -122.4201,
      locationAddress: 'City Center',
      status: ReportStatus.resolved,
      createdBy: uid,
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 3)),
    ),
  ];
}

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key, this.inShell = false});

  static const String routeName = '/my-reports';

  final bool inShell;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AppState>().currentUser?.uid;
    final reportService = context.read<ReportService>();

    if (uid == null) {
      return const EmptyState(
        title: 'Sign in to see your reports',
        icon: Icons.person_outline,
      );
    }

    return StreamBuilder<List<Report>>(
      stream: reportService.getMyReports(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Loading your reports…');
        }
        if (snapshot.hasError) {
          return const ErrorView(
            message: 'Something went wrong loading reports. Please try again.',
          );
        }
        final reports = snapshot.data ?? [];
        final showSamples = reports.isEmpty;
        final listToShow = showSamples ? _sampleReports(uid!) : reports;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listToShow.length + (showSamples ? 1 : 0),
          itemBuilder: (context, index) {
            if (showSamples && index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Sample reports (submit a report to see your own here)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              );
            }
            final report = listToShow[showSamples ? index - 1 : index];
            final isSample = showSamples;
            return _ReportCard(
              report: report,
              isSample: isSample,
              onTap: () {
                if (isSample) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('This is sample data. Submit a report to see your reports here.')),
                  );
                } else {
                  Navigator.pushNamed(
                    context,
                    ReportDetailsScreen.routeName,
                    arguments: report.id,
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap, this.isSample = false});

  final Report report;
  final VoidCallback onTap;
  final bool isSample;

  static final _dateFormat = DateFormat('MMM d, y');

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: report.photoUrl != null
                    ? Image.network(
                        report.photoUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(context),
                      )
                    : _placeholder(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.category,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: StatusChip(status: report.status),
                    ),
                    Text(
                      _dateFormat.format(report.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
