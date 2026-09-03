import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
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

    final beforeScore = session.beforeResult.overallScore;
    final afterScore = session.afterResult?.overallScore ?? beforeScore;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Performance Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtration Performance',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Inflow vs Treated Output (BIS IS 10500)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.excellent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_upward_rounded, size: 13, color: AppColors.excellent),
                      const SizedBox(width: 3),
                      Text(
                        '+${improvement.toStringAsFixed(0)}% Purity',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.excellent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Inflow vs Outflow Score Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RAW INFLOW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$beforeScore / 100',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.poor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TREATED OUTPUT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$afterScore / 100',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.excellent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Comparison Breakdown
            _buildParameterRow(
              context,
              name: 'TDS',
              unit: 'ppm',
              beforeVal: before.tds.toStringAsFixed(0),
              afterVal: after != null ? after.tds.toStringAsFixed(0) : '--',
              safeTarget: AppConstants.bisTdsStandard,
              improved: after != null ? after.tds <= before.tds : true,
            ),
            const Divider(height: 10),
            _buildParameterRow(
              context,
              name: 'Turbidity',
              unit: 'NTU',
              beforeVal: before.turbidity.toStringAsFixed(1),
              afterVal: after != null ? after.turbidity.toStringAsFixed(1) : '--',
              safeTarget: AppConstants.bisTurbidityStandard,
              improved: after != null ? after.turbidity <= before.turbidity : true,
            ),
            const Divider(height: 10),
            _buildParameterRow(
              context,
              name: 'pH Level',
              unit: '',
              beforeVal: before.ph.toStringAsFixed(1),
              afterVal: after != null ? after.ph.toStringAsFixed(1) : '--',
              safeTarget: AppConstants.bisPhStandard,
              improved: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(
    BuildContext context, {
    required String name,
    required String unit,
    required String beforeVal,
    required String afterVal,
    required String safeTarget,
    required bool improved,
  }) {
    final theme = Theme.of(context);
    final unitSuffix = unit.isNotEmpty ? ' $unit' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  '$beforeVal$unitSuffix',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Icon(
                    Icons.east_rounded,
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '$afterVal$unitSuffix',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: improved ? AppColors.excellent : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Target: $safeTarget',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

