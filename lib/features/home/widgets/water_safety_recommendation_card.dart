import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sensor_reading.dart';
import '../../../models/water_quality_result.dart';
import '../../../providers/filtration_provider.dart';

class ParameterDiagnostic {
  final String name;
  final String currentValue;
  final String safeTargetValue;
  final SensorStatus status;
  final String issueDescription;
  final String recommendedFiltration;
  final IconData filterIcon;

  const ParameterDiagnostic({
    required this.name,
    required this.currentValue,
    required this.safeTargetValue,
    required this.status,
    required this.issueDescription,
    required this.recommendedFiltration,
    required this.filterIcon,
  });
}

class WaterSafetyRecommendationCard extends ConsumerWidget {
  final SensorReading reading;
  final WaterQualityResult result;

  const WaterSafetyRecommendationCard({
    super.key,
    required this.reading,
    required this.result,
  });

  List<ParameterDiagnostic> _getDiagnostics() {
    final List<ParameterDiagnostic> diagnostics = [];

    // 1. pH Check
    if (result.phStatus == SensorStatus.critical || result.phStatus == SensorStatus.warning) {
      diagnostics.add(
        ParameterDiagnostic(
          name: 'pH Level',
          currentValue: '${reading.ph.toStringAsFixed(1)}',
          safeTargetValue: AppConstants.bisPhStandard,
          status: result.phStatus,
          issueDescription: reading.ph < 6.5
              ? 'Acidic water detected (pH < 6.5).'
              : 'Alkaline water detected (pH > 8.5).',
          recommendedFiltration: 'Calcite & Corosex Mineralizer Chamber',
          filterIcon: Icons.science_outlined,
        ),
      );
    }

    // 2. TDS Check
    if (result.tdsStatus == SensorStatus.critical || result.tdsStatus == SensorStatus.warning) {
      diagnostics.add(
        ParameterDiagnostic(
          name: 'TDS Level',
          currentValue: '${reading.tds.toStringAsFixed(0)} ppm',
          safeTargetValue: AppConstants.bisTdsStandard,
          status: result.tdsStatus,
          issueDescription: 'High Total Dissolved Solids exceeds drinking limit.',
          recommendedFiltration: 'High-Pressure Reverse Osmosis (RO) Membrane',
          filterIcon: Icons.water_outlined,
        ),
      );
    }

    // 3. Turbidity Check
    if (result.turbidityStatus == SensorStatus.critical || result.turbidityStatus == SensorStatus.warning) {
      diagnostics.add(
        ParameterDiagnostic(
          name: 'Turbidity',
          currentValue: '${reading.turbidity.toStringAsFixed(1)} NTU',
          safeTargetValue: AppConstants.bisTurbidityStandard,
          status: result.turbidityStatus,
          issueDescription: 'Suspended particles & cloudiness exceed 1.0 NTU.',
          recommendedFiltration: '5-Micron PP Sediment & Activated Carbon Block',
          filterIcon: Icons.invert_colors_outlined,
        ),
      );
    }

    // 4. Salinity Check
    if (result.salinityStatus == SensorStatus.critical || result.salinityStatus == SensorStatus.warning) {
      diagnostics.add(
        ParameterDiagnostic(
          name: 'Salinity',
          currentValue: '${reading.salinity.toStringAsFixed(2)} ppt',
          safeTargetValue: AppConstants.bisSalinityStandard,
          status: result.salinityStatus,
          issueDescription: 'Elevated dissolved salt content detected.',
          recommendedFiltration: 'Nanofiltration / Desalination RO Stage',
          filterIcon: Icons.waves_outlined,
        ),
      );
    }

    // 5. Temperature Check
    if (result.tempStatus == SensorStatus.critical || result.tempStatus == SensorStatus.warning) {
      diagnostics.add(
        ParameterDiagnostic(
          name: 'Temperature',
          currentValue: '${reading.temperature.toStringAsFixed(1)} °C',
          safeTargetValue: AppConstants.bisTempStandard,
          status: result.tempStatus,
          issueDescription: 'Water temperature outside optimal 15-30 °C range.',
          recommendedFiltration: 'Thermal Heat Exchanger & UV Sterilization',
          filterIcon: Icons.thermostat_outlined,
        ),
      );
    }

    return diagnostics;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final diagnostics = _getDiagnostics();
    final hasIssues = diagnostics.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasIssues ? AppColors.moderate.withOpacity(0.5) : AppColors.excellent.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (hasIssues ? AppColors.moderate : AppColors.excellent).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasIssues ? Icons.healing_rounded : Icons.verified_user_rounded,
                    color: hasIssues ? AppColors.moderate : AppColors.excellent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WATER SAFETY DIAGNOSTIC & SOLUTION',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasIssues
                            ? '${diagnostics.length} parameter(s) require targeted filtration solution'
                            : 'All parameters match Indian BIS IS 10500 safe standards',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!hasIssues) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.excellent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.excellent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '🟢 Safe Water: No unsafe or warning levels detected. Water is pure and suitable for direct consumption.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.excellent),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // List each parameter needing attention
              Column(
                children: diagnostics.map((diag) {
                  final isCritical = diag.status == SensorStatus.critical;
                  final statusColor = isCritical ? AppColors.poor : AppColors.moderate;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Parameter Name + Status Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(diag.filterIcon, size: 18, color: statusColor),
                                const SizedBox(width: 8),
                                Text(
                                  diag.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isCritical ? '🔴 UNSAFE' : '🟡 WARNING',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Value Comparison
                        Row(
                          children: [
                            Text(
                              'Current Value: ',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              diag.currentValue,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Target Safe Limit: ',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              diag.safeTargetValue,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.excellent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Solution / Filtration Stage Recommendation
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.settings_suggest_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'RECOMMENDED SOLUTION / FILTRATION STAGE:',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      diag.recommendedFiltration,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),

              // Button to execute recommended filtration
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(filtrationProvider.notifier).startFiltrationSimulation();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Targeted filtration cycle initiated based on safety diagnostics!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                  label: const Text('Apply Targeted Filtration Solution'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
