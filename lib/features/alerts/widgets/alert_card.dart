import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/alert_model.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onMarkAsRead;

  const AlertCard({
    super.key,
    required this.alert,
    this.onMarkAsRead,
  });

  Color _getSeverityColor() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppColors.severityCritical;
      case AlertSeverity.warning:
        return AppColors.severityWarning;
      case AlertSeverity.info:
        return AppColors.severityInfo;
    }
  }

  IconData _getSeverityIcon() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return Icons.error_outline_rounded;
      case AlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case AlertSeverity.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getSeverityColor();

    return Card(
      color: alert.isRead ? null : color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_getSeverityIcon(), color: color, size: 20),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        alert.severity.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Text(
                      Formatters.formatTimestamp(alert.timestamp),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (!alert.isRead) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                        tooltip: 'Mark as read',
                        onPressed: onMarkAsRead,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              alert.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              alert.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Value: ${alert.sensorValue}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Safety Limit: ${alert.threshold}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
