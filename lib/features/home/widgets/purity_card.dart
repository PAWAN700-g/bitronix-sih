import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/water_quality_result.dart';

class PurityCard extends StatelessWidget {
  final WaterQualityResult result;

  const PurityCard({
    super.key,
    required this.result,
  });

  Color _getGradeColor(WaterGrade grade) {
    switch (grade) {
      case WaterGrade.excellent:
        return AppColors.excellent;
      case WaterGrade.good:
        return AppColors.good;
      case WaterGrade.moderate:
        return AppColors.moderate;
      case WaterGrade.poor:
        return AppColors.poor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradeColor = _getGradeColor(result.grade);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OVERALL PURITY SCORE',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${result.overallScore}',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: gradeColor,
                          ),
                        ),
                        Text(
                          ' / 100',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Grade Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: gradeColor, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'GRADE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: gradeColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.grade.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: gradeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar Visualizer
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: result.overallScore / 100.0,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  result.hasAlerts ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                  size: 16,
                  color: result.hasAlerts ? AppColors.moderate : AppColors.excellent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.hasAlerts
                        ? 'Sensors detected values outside optimal drinking parameters.'
                        : 'All parameters within optimal drinking water safety guidelines.',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
