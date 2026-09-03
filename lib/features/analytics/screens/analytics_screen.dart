import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/sensor_provider.dart';
import '../widgets/before_after_comparison_card.dart';
import '../widgets/sensor_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDays = ref.watch(selectedTimeFilterProvider);
    final historyAsync = ref.watch(historicalSensorReadingsProvider(selectedDays));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Quality Analytics'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
}

