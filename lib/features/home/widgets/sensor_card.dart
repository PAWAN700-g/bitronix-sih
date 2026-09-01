import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/water_quality_result.dart';

class SensorCard extends StatelessWidget {
  final String name;
  final String value;
  final String unit;
  final SensorStatus status;
  final IconData icon;
  final Color accentColor;

  const SensorCard({
    super.key,
    required this.name,
    required this.value,
    required this.unit,
    required this.status,
    required this.icon,
    required this.accentColor,
  });

  Color _getStatusColor() {
    switch (status) {
      case SensorStatus.normal:
        return AppColors.excellent;
      case SensorStatus.good:
        return AppColors.good;
      case SensorStatus.warning:
        return AppColors.moderate;
      case SensorStatus.critical:
        return AppColors.critical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
