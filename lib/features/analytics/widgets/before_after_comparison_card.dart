import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
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

    final beforeResult = session.beforeResult;
    final afterResult = session.afterResult;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header with Overflow Protection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BEFORE VS AFTER FILTRATION',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Indian BIS IS 10500:2012 Safety Benchmark',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Improvement % Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.excellent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.excellent, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up, size: 14, color: AppColors.excellent),
                      const SizedBox(width: 4),
                      Text(
                        '+${improvement.toStringAsFixed(1)}%',
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
            const SizedBox(height: 16),

            // Purity Score Comparison Bar
            Row(
              children: [
                Expanded(
                  child: _buildScorePill(
                    context,
                    label: 'PURITY BEFORE',
                    score: beforeResult.overallScore,
                    grade: beforeResult.grade.label,
                    color: AppColors.poor,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 20),
                ),
                Expanded(
                  child: _buildScorePill(
                    context,
                    label: 'PURITY AFTER',
                    score: afterResult?.overallScore ?? beforeResult.overallScore,
                    grade: afterResult?.grade.label ?? 'Processing',
                    color: AppColors.excellent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 8),

            // Table Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildLegendTag(context, 'SAFE 🟢', AppColors.excellent),
                const SizedBox(width: 8),
                _buildLegendTag(context, 'WARNING 🟡', AppColors.moderate),
                const SizedBox(width: 8),
                _buildLegendTag(context, 'RISKY 🔴', AppColors.poor),
              ],
            ),
            const SizedBox(height: 12),

            // Comparison Table with Indian Standard Column
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 480),
                child: Column(
                  children: [
                    _buildTableHeader(context),
                    const Divider(height: 12),

                    // 1. pH Level
                    _buildTableRow(
                      context,
                      parameter: 'pH Level',
                      beforeVal: before.ph.toStringAsFixed(1),
                      beforeStatus: beforeResult.phStatus,
                      afterVal: after != null ? after.ph.toStringAsFixed(1) : '--',
                      afterStatus: afterResult?.phStatus ?? SensorStatus.normal,
                      safeLimit: AppConstants.bisPhStandard,
                    ),

                    // 2. TDS Level
                    _buildTableRow(
                      context,
                      parameter: 'TDS (ppm)',
                      beforeVal: '${before.tds.toStringAsFixed(0)}',
                      beforeStatus: beforeResult.tdsStatus,
                      afterVal: after != null ? '${after.tds.toStringAsFixed(0)}' : '--',
                      afterStatus: afterResult?.tdsStatus ?? SensorStatus.good,
                      safeLimit: AppConstants.bisTdsStandard,
                    ),

                    // 3. Turbidity
                    _buildTableRow(
                      context,
                      parameter: 'Turbidity (NTU)',
                      beforeVal: before.turbidity.toStringAsFixed(1),
                      beforeStatus: beforeResult.turbidityStatus,
                      afterVal: after != null ? after.turbidity.toStringAsFixed(1) : '--',
                      afterStatus: afterResult?.turbidityStatus ?? SensorStatus.normal,
                      safeLimit: AppConstants.bisTurbidityStandard,
                    ),

                    // 4. Salinity
                    _buildTableRow(
                      context,
                      parameter: 'Salinity (ppt)',
                      beforeVal: before.salinity.toStringAsFixed(2),
                      beforeStatus: beforeResult.salinityStatus,
                      afterVal: after != null ? after.salinity.toStringAsFixed(2) : '--',
                      afterStatus: afterResult?.salinityStatus ?? SensorStatus.normal,
                      safeLimit: AppConstants.bisSalinityStandard,
                    ),

                    // 5. Temperature
                    _buildTableRow(
                      context,
                      parameter: 'Temp (°C)',
                      beforeVal: before.temperature.toStringAsFixed(1),
                      beforeStatus: beforeResult.tempStatus,
                      afterVal: after != null ? after.temperature.toStringAsFixed(1) : '--',
                      afterStatus: afterResult?.tempStatus ?? SensorStatus.normal,
                      safeLimit: AppConstants.bisTempStandard,
                    ),
                  ],
                ),
              ),
            ),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            '$score / 100',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
          Text(
            grade,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    const headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey);
    return const Row(
      children: [
        SizedBox(width: 110, child: Text('PARAMETER', style: headerStyle)),
        SizedBox(width: 90, child: Text('BEFORE', style: headerStyle)),
        SizedBox(width: 90, child: Text('AFTER', style: headerStyle)),
        SizedBox(width: 140, child: Text('SAFE LIMIT (BIS IS 10500)', style: headerStyle)),
      ],
    );
  }

  Widget _buildTableRow(
    BuildContext context, {
    required String parameter,
    required String beforeVal,
    required SensorStatus beforeStatus,
    required String afterVal,
    required SensorStatus afterStatus,
    required String safeLimit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              parameter,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),

          // BEFORE Value + Status Badge
          SizedBox(
            width: 90,
            child: _buildValuePill(beforeVal, beforeStatus),
          ),

          // AFTER Value + Status Badge
          SizedBox(
            width: 90,
            child: _buildValuePill(afterVal, afterStatus),
          ),

          // INDIAN STANDARD GENERAL SAFE LIMIT
          SizedBox(
            width: 140,
            child: Text(
              safeLimit,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuePill(String val, SensorStatus status) {
    Color bg;
    Color fg;
    String prefix;

    switch (status) {
      case SensorStatus.critical:
        bg = AppColors.poor.withOpacity(0.15);
        fg = AppColors.poor;
        prefix = '🔴 ';
        break;
      case SensorStatus.warning:
        bg = AppColors.moderate.withOpacity(0.15);
        fg = AppColors.moderate;
        prefix = '🟡 ';
        break;
      case SensorStatus.good:
      case SensorStatus.normal:
        bg = AppColors.excellent.withOpacity(0.15);
        fg = AppColors.excellent;
        prefix = '🟢 ';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          '$prefix$val',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }
}
