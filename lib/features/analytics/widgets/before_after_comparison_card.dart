import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/water_quality_result.dart';
import '../../../providers/filtration_provider.dart';

class BeforeAfterComparisonCard extends ConsumerWidget {
  const BeforeAfterComparisonCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(filtrationProvider);

    final before = session.beforeReading;
    final after = session.afterReading;
    final improvement = session.improvementPercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BEFORE VS AFTER FILTRATION',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Water Purity Performance',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),

                // Improvement % Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.excellent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.excellent, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, size: 16, color: AppColors.excellent),
                      const SizedBox(width: 4),
                      Text(
                        'Improvement: +${improvement.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.excellent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Purity Score Comparison Bar
            Row(
              children: [
                Expanded(
                  child: _buildScorePill(
                    context,
                    label: 'PURITY BEFORE',
                    score: session.beforeResult.overallScore,
                    grade: session.beforeResult.grade.label,
                    color: AppColors.poor,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                ),
                Expanded(
                  child: _buildScorePill(
                    context,
                    label: 'PURITY AFTER',
                    score: session.afterResult?.overallScore ?? session.beforeResult.overallScore,
                    grade: session.afterResult?.grade.label ?? 'Processing',
                    color: AppColors.excellent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 12),

            // Comparison Table
            _buildTableHeader(context),
            const SizedBox(height: 8),
            _buildTableRow(context, 'pH Level', before.ph.toStringAsFixed(1), after?.ph.toStringAsFixed(1) ?? '--', ''),
            _buildTableRow(context, 'TDS Level', '${before.tds.toStringAsFixed(0)} ppm', after != null ? '${after.tds.toStringAsFixed(0)} ppm' : '--', 'ppm'),
            _buildTableRow(context, 'Turbidity', '${before.turbidity.toStringAsFixed(1)} NTU', after != null ? '${after.turbidity.toStringAsFixed(1)} NTU' : '--', 'NTU'),
            _buildTableRow(context, 'Temperature', '${before.temperature.toStringAsFixed(1)} °C', after != null ? '${after.temperature.toStringAsFixed(1)} °C' : '--', '°C'),
          ],
        ),
      ),
    );
  }

  Widget _buildScorePill(
    BuildContext context, {
    required String label,
    required int score,
    required String grade,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            '$score / 100',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
          Text(
            grade,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 3, child: Text('PARAMETER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
        Expanded(flex: 2, child: Text('BEFORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.poor))),
        Expanded(flex: 2, child: Text('AFTER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.excellent))),
      ],
    );
  }

  Widget _buildTableRow(BuildContext context, String parameter, String beforeVal, String afterVal, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(parameter, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text(beforeVal, style: const TextStyle(fontSize: 13, color: AppColors.poor, fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text(afterVal, style: const TextStyle(fontSize: 13, color: AppColors.excellent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
