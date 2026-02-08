import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/report.dart';
import '../models/status_entry.dart';
import '../services/app_state.dart';
import '../services/moderation_service.dart';
import '../services/report_service.dart';
import '../utils/enums.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';

class ReportDetailsScreen extends StatefulWidget {
  const ReportDetailsScreen({super.key, this.reportId});

  static const String routeName = '/report-details';

  final String? reportId;

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final reportId = widget.reportId;
    if (reportId == null || reportId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Details')),
        body: const Center(child: Text('No report selected')),
      );
    }

    final reportService = context.read<ReportService>();
    final isAdmin = context.watch<AppState>().isAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: StreamBuilder<Report?>(
        stream: reportService.getReportStream(reportId),
        builder: (context, reportSnap) {
          if (reportSnap.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading report…');
          }
          if (reportSnap.hasError) {
            return const ErrorView(
              message: 'Could not load this report. Please try again.',
            );
          }
          final report = reportSnap.data;
          if (report == null) {
            return const EmptyState(
              title: 'Report not found',
              icon: Icons.description_outlined,
            );
          }

          return StreamBuilder<List<StatusEntry>>(
            stream: reportService.getStatusHistoryStream(reportId),
            builder: (context, historySnap) {
              final history = historySnap.data ?? [];
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (report.photoUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          report.photoUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      report.category,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.department,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    StatusChip(status: report.status),
                    const SizedBox(height: 12),
                    Text(
                      report.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(report.locationLat, report.locationLng),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('report'),
                              position: LatLng(
                                report.locationLat,
                                report.locationLng,
                              ),
                            ),
                          },
                          liteModeEnabled: true,
                        ),
                      ),
                    ),
                    if (report.locationAddress != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        report.locationAddress!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Status timeline',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...history.asMap().entries.map(
                          (e) => _TimelineTile(
                            entry: e.value,
                            isLast: e.key == history.length - 1,
                          ),
                        ),
                    const SizedBox(height: 24),
                    if (isAdmin)
                      _AdminControls(
                        report: report,
                        reportId: reportId,
                      )
                    else if (report.status == ReportStatus.resolved)
                      _CitizenResolvedActions(
                        reportId: reportId,
                      )
                    else if (!isAdmin &&
                        report.status == ReportStatus.needsReview)
                      _CitizenAppealAction(
                        report: report,
                        reportId: reportId,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _photoPlaceholder(BuildContext context) {
    return Container(
      height: 200,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry, this.isLast = false});

  final StatusEntry entry;
  final bool isLast;

  static final _dateFormat = DateFormat('MMM d, y • HH:mm');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 24,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.status,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.note!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _dateFormat.format(entry.timestamp),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'by ${entry.updatedBy}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CitizenResolvedActions extends StatelessWidget {
  const _CitizenResolvedActions({required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    final reportService = context.read<ReportService>();
    final uid = context.read<AppState>().currentUser?.uid ?? '';

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () async {
              await reportService.updateStatus(
                reportId: reportId,
                newStatus: ReportStatus.resolved,
                note: 'Confirmed fixed by citizen',
                updatedBy: uid,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as confirmed fixed')),
                );
              }
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirm Fixed'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await reportService.updateStatus(
                reportId: reportId,
                newStatus: ReportStatus.needsReview,
                note: 'Reopened by citizen',
                updatedBy: uid,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report reopened')),
                );
              }
            },
            icon: const Icon(Icons.replay),
            label: const Text('Reopen'),
          ),
        ),
      ],
    );
  }
}

class _AdminControls extends StatefulWidget {
  const _AdminControls({required this.report, required this.reportId});

  final Report report;
  final String reportId;

  @override
  State<_AdminControls> createState() => _AdminControlsState();
}

class _AdminControlsState extends State<_AdminControls> {
  late TextEditingController _noteController;
  late TextEditingController _deptController;
  late TextEditingController _assigneeController;
  ReportStatus _selectedStatus = ReportStatus.reported;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _deptController = TextEditingController(text: widget.report.assignedDepartment);
    _assigneeController = TextEditingController(text: widget.report.assignee);
    _selectedStatus = widget.report.status;
  }

  @override
  void didUpdateWidget(_AdminControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report.id != widget.report.id) {
      _deptController.text = widget.report.assignedDepartment ?? '';
      _assigneeController.text = widget.report.assignee ?? '';
      _selectedStatus = widget.report.status;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _deptController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportService = context.read<ReportService>();
    final uid = context.read<AppState>().currentUser?.uid ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Update status',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ReportStatus>(
          initialValue: _selectedStatus,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: ReportStatus.values
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.value),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedStatus = v ?? _selectedStatus),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Note',
            hintText: 'Optional note for this update',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _deptController,
          decoration: const InputDecoration(
            labelText: 'Assigned department',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _assigneeController,
          decoration: const InputDecoration(
            labelText: 'Assignee',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            if (_selectedStatus != widget.report.status) {
              await reportService.updateStatus(
                reportId: widget.reportId,
                newStatus: _selectedStatus,
                note: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
                updatedBy: uid,
              );
            }
            final patch = <String, dynamic>{};
            if (_deptController.text.trim() !=
                (widget.report.assignedDepartment ?? '')) {
              patch['assignedDepartment'] = _deptController.text.trim();
            }
            if (_assigneeController.text.trim() != (widget.report.assignee ?? '')) {
              patch['assignee'] = _assigneeController.text.trim();
            }
            if (patch.isNotEmpty) {
              await reportService.updateReportFields(widget.reportId, patch);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report updated')),
              );
            }
          },
          child: const Text('Update status & assignment'),
        ),
        if (!widget.report.irrelevantConfirmed) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<ModerationService>().confirmIrrelevant(widget.reportId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as irrelevant; creator strike applied')),
                );
              }
            },
            icon: const Icon(Icons.report_off),
            label: const Text('Irrelevant Confirmed'),
          ),
        ],
        if (widget.report.appealRequested)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Appeal requested by citizen',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
      ],
    );
  }
}

class _CitizenAppealAction extends StatelessWidget {
  const _CitizenAppealAction({required this.report, required this.reportId});

  final Report report;
  final String reportId;

  @override
  Widget build(BuildContext context) {
    if (report.appealRequested) {
      return Text(
        'Appeal requested. An admin will review.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }
    return OutlinedButton.icon(
      onPressed: () async {
        await context.read<ModerationService>().requestAppeal(reportId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appeal requested')),
          );
        }
      },
      icon: const Icon(Icons.gavel),
      label: const Text('Appeal'),
    );
  }
}
