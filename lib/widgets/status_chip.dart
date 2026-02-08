import 'package:flutter/material.dart';

import '../utils/enums.dart';

/// Consistent status chip with icon for report status.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ReportStatus status;

  static IconData _iconFor(ReportStatus s) {
    return switch (s) {
      ReportStatus.reported => Icons.flag_outlined,
      ReportStatus.inProgress => Icons.autorenew,
      ReportStatus.resolved => Icons.check_circle_outline,
      ReportStatus.needsReview => Icons.pending_outlined,
    };
  }

  static Color _colorFor(BuildContext context, ReportStatus s) {
    final scheme = Theme.of(context).colorScheme;
    return switch (s) {
      ReportStatus.reported => scheme.error,
      ReportStatus.inProgress => scheme.tertiary,
      ReportStatus.resolved => scheme.primary,
      ReportStatus.needsReview => scheme.secondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context, status);
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(status), size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.value,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
