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
        return Icons.error_rounded;
      case AlertSeverity.warning:
        return Icons.warning_rounded;
      case AlertSeverity.info:
        return Icons.info_rounded;
    }
  }

  String _formatTitle(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      final upper = word.toUpperCase();
      if (upper == 'PH' || upper == 'TDS' || upper == 'NTU' || upper == 'BIS') {
        return upper;
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getSeverityColor();
    final isUnread = !alert.isRead;

    return Card(
      elevation: isUnread ? 1.5 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnread ? color.withValues(alpha: 0.35) : theme.dividerColor.withValues(alpha: 0.2),
          width: isUnread ? 1.2 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subtle colored severity left border strip
              Container(
                width: 4,
                color: color,
              ),

              // Card Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Severity badge, Time, Mark as read action
                      Row(
                        children: [
                          Icon(_getSeverityIcon(), color: color, size: 16),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              alert.severity.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            Formatters.formatTimestamp(alert.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          if (isUnread && onMarkAsRead != null) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: onMarkAsRead,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Clean Title
                      Text(
                        _formatTitle(alert.title),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Description
                      Text(
                        alert.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Bottom Metadata Tags: Value & Threshold
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildMetadataTag(
                            context,
                            icon: Icons.speed_rounded,
                            label: 'Reading: ${alert.sensorValue}',
                            isHighlight: true,
                          ),
                          _buildMetadataTag(
                            context,
                            icon: Icons.shield_outlined,
                            label: 'Limit: ${alert.threshold}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataTag(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isHighlight
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
