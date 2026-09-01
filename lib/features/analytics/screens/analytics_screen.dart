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
              // Time Filter Segment Buttons
              Row(
                children: [
                  _buildFilterChip(context, ref, label: 'Today', days: 1, currentDays: selectedDays),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, ref, label: '7 Days', days: 7, currentDays: selectedDays),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, ref, label: '30 Days', days: 30, currentDays: selectedDays),
                ],
              ),
              const SizedBox(height: 20),

              // Major Feature: Before vs After Filtration Comparison Card
              const BeforeAfterComparisonCard(),
              const SizedBox(height: 24),

              Text(
                'HISTORICAL PARAMETER TRENDS',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),

              historyAsync.when(
                data: (readings) {
                  final qualityService = ref.watch(waterQualityServiceProvider);

                  return Column(
                    children: [
                      // 1. Overall Purity Chart
                      SensorChart(
                        title: 'Overall Purity Score',
                        unit: '/ 100',
                        readings: readings,
                        extractor: (r) => qualityService.evaluate(r).overallScore.toDouble(),
                        lineColors: AppColors.primary,
                      ),
                      const SizedBox(height: 16),

                      // 2. pH Chart
                      SensorChart(
                        title: 'pH Trend',
                        unit: '',
                        readings: readings,
                        extractor: (r) => r.ph,
                        lineColors: AppColors.phColor,
                      ),
                      const SizedBox(height: 16),

                      // 3. TDS Chart
                      SensorChart(
                        title: 'TDS Trend',
                        unit: 'ppm',
                        readings: readings,
                        extractor: (r) => r.tds,
                        lineColors: AppColors.tdsColor,
                      ),
                      const SizedBox(height: 16),

                      // 4. Turbidity Chart
                      SensorChart(
                        title: 'Turbidity Trend',
                        unit: 'NTU',
                        readings: readings,
                        extractor: (r) => r.turbidity,
                        lineColors: AppColors.turbidityColor,
                      ),
                      const SizedBox(height: 16),

                      // 5. Temperature Chart
                      SensorChart(
                        title: 'Temperature Trend',
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
                  child: Text('Error loading historical analytics: $err'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required int days,
    required int currentDays,
  }) {
    final isSelected = days == currentDays;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          ref.read(selectedTimeFilterProvider.notifier).state = days;
        }
      },
    );
  }
}
