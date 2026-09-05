import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/water_quality_result.dart';

/// Displays the overall Water Quality Screening Score with sub-score
/// breakdown, grade badge, score explanation, and disclaimer.
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
      case WaterGrade.veryPoor:
        return AppColors.critical;
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
            // ─── Title + Score + Grade Badge ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WATER QUALITY SCREENING SCORE',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 11,
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

            // ─── Progress Bar ───
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: result.overallScore / 100.0,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
              ),
            ),
            const SizedBox(height: 14),

            // ─── Sub-Score Chips (pH, TDS, Turbidity) ───
            Row(
              children: [
                _buildSubScoreChip(
                  context,
                  label: 'pH',
                  score: result.phScore.round(),
                  color: AppColors.phColor,
                ),
                const SizedBox(width: 8),
                _buildSubScoreChip(
                  context,
                  label: 'TDS',
                  score: result.tdsScore.round(),
                  color: AppColors.tdsColor,
                ),
                const SizedBox(width: 8),
                _buildSubScoreChip(
                  context,
                  label: 'Turbidity',
                  score: result.turbidityScore.round(),
                  color: AppColors.turbidityColor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ─── Score Explanation ───
            Row(
              children: [
                Icon(
                  result.hasAlerts
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 16,
                  color: result.hasAlerts ? AppColors.moderate : AppColors.excellent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.scoreExplanation,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ─── Disclaimer ───
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppConstants.wqiDisclaimer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a small chip showing an individual parameter sub-score.
  Widget _buildSubScoreChip(
    BuildContext context, {
    required String label,
    required int score,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
