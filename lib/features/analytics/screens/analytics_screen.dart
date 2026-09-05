import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/sensor_provider.dart';
import '../../../services/share_service.dart';
import '../widgets/before_after_comparison_card.dart';
import '../widgets/sensor_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDays = ref.watch(selectedTimeFilterProvider);
    final historyAsync = ref.watch(historicalSensorReadingsProvider(selectedDays));
    final liveReadingAsync = ref.watch(liveSensorStreamProvider(AppConstants.defaultDeviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Water Quality Analytics'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Export & Share Live Report',
            onPressed: () {
              liveReadingAsync.whenData((reading) {
                final result = ref.read(currentWaterQualityResultProvider(reading));
                ShareService().shareWaterQualityReport(reading, result);
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Real-Time Live Sensor Telemetry Report Summary Card
              liveReadingAsync.when(
                data: (liveReading) {
                  final result = ref.watch(currentWaterQualityResultProvider(liveReading));
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sensors_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Live Telemetry Feed (${liveReading.deviceId})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.excellent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${result.overallScore.round()}% Purity',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.excellent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Grid of Live Parameters
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLiveParamBadge('pH Level', liveReading.ph.toStringAsFixed(1), AppColors.phColor),
                            _buildLiveParamBadge('Turbidity', '${liveReading.turbidity.toStringAsFixed(1)} NTU', AppColors.turbidityColor),
                            _buildLiveParamBadge('TDS', '${liveReading.tds.toStringAsFixed(0)} ppm', AppColors.tdsColor),
                            _buildLiveParamBadge('Salinity', '${liveReading.salinity.toStringAsFixed(2)} ppt', AppColors.salinityColor),
                            _buildLiveParamBadge('Temp', '${liveReading.temperature.toStringAsFixed(1)} °C', AppColors.tempColor),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Action button to export formal report
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ShareService().shareWaterQualityReport(liveReading, result);
                            },
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                            label: const Text('Export & Share Full Inspection Analytics Report'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, st) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.poor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Live sensor stream notice: $err', style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Real-Time Performance Monitoring Card ───
              _buildLatencyCard(context, ref),
              const SizedBox(height: 16),

              // Time Filter Controls (Today / 7 Days)
              Row(
                children: [
                  _buildTimeFilterChip(context, ref, label: 'Today', days: 1, currentDays: selectedDays),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip(context, ref, label: '7 Days', days: 7, currentDays: selectedDays),
                ],
              ),
              const SizedBox(height: 16),

              // Filtration Performance (Inflow vs Outflow)
              const BeforeAfterComparisonCard(),
              const SizedBox(height: 20),

              // Section Header
              Text(
                'Sensor Telemetry Trends',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Continuous 4-parameter historical monitoring',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),

              historyAsync.when(
                data: (readings) {
                  if (readings.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('No readings recorded for this duration')),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // 1. pH Sensor Graph
                      SensorChart(
                        title: 'pH Level',
                        unit: '',
                        readings: readings,
                        extractor: (r) => r.ph,
                        lineColors: AppColors.phColor,
                      ),
                      const SizedBox(height: 16),

                      // 2. TDS Sensor Graph
                      SensorChart(
                        title: 'Total Dissolved Solids (TDS)',
                        unit: 'ppm',
                        readings: readings,
                        extractor: (r) => r.tds,
                        lineColors: AppColors.tdsColor,
                      ),
                      const SizedBox(height: 16),

                      // 3. Turbidity Sensor Graph
                      SensorChart(
                        title: 'Turbidity',
                        unit: 'NTU',
                        readings: readings,
                        extractor: (r) => r.turbidity,
                        lineColors: AppColors.turbidityColor,
                      ),
                      const SizedBox(height: 16),

                      // 4. Temperature Sensor Graph
                      SensorChart(
                        title: 'Water Temperature',
                        unit: '°C',
                        readings: readings,
                        extractor: (r) => r.temperature,
                        lineColors: AppColors.tempColor,
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Error loading historical data: $err'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveParamBadge(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTimeFilterChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required int days,
    required int currentDays,
  }) {
    final isSelected = days == currentDays;
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          ref.read(selectedTimeFilterProvider.notifier).state = days;
        }
      },
    );
  }

  /// Builds the Real-Time Performance monitoring card showing latency
  /// and adaptive sampling metrics.
  Widget _buildLatencyCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tracker = ref.watch(latencyTrackerProvider);
    final adaptiveState = ref.watch(adaptiveSamplingStateProvider);
    final latest = tracker.latestSample;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'REAL-TIME PERFORMANCE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
              ),
              const Spacer(),
              if (adaptiveState != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (adaptiveState.isStable ? AppColors.excellent : AppColors.moderate)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    adaptiveState.isStable ? '● Stable' : '◐ Changing',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: adaptiveState.isStable ? AppColors.excellent : AppColors.moderate,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Latency metrics row
          Row(
            children: [
              _buildLatencyMetric(
                'End-to-End',
                latest?.endToEndMs != null ? '${latest!.endToEndMs}ms' : '—',
                Icons.swap_horiz_rounded,
              ),
              const SizedBox(width: 12),
              _buildLatencyMetric(
                'FB → App',
                latest?.firebaseToAppMs != null ? '${latest!.firebaseToAppMs}ms' : '—',
                Icons.cloud_download_rounded,
              ),
              const SizedBox(width: 12),
              _buildLatencyMetric(
                'Avg E2E',
                tracker.averageEndToEndMs > 0
                    ? '${tracker.averageEndToEndMs.round()}ms'
                    : '—',
                Icons.analytics_outlined,
              ),
            ],
          ),

          if (adaptiveState != null && !adaptiveState.isStable) ...[
            const SizedBox(height: 10),
            Text(
              'Active changes: ${adaptiveState.changedParameters.join(", ")}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.moderate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLatencyMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
