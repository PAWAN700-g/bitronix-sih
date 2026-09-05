import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/alert_provider.dart';
import '../../../providers/sensor_provider.dart';
import '../widgets/greeting_header.dart';
import '../widgets/purity_card.dart';
import '../widgets/sensor_grid.dart';
import '../widgets/water_safety_recommendation_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveReadingAsync = ref.watch(liveSensorStreamProvider(AppConstants.defaultDeviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Sensor Data',
            onPressed: () {
              ref.invalidate(liveSensorStreamProvider(AppConstants.defaultDeviceId));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: liveReadingAsync.when(
          data: (reading) {
            // Trigger automatic alert checking
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(alertsNotifierProvider.notifier).checkAndAddAlerts(reading);

              // Track latency & adaptive sampling
              final tracker = ref.read(latencyTrackerProvider);
              tracker.addSample(
                reading.sensorTimestamp,
                reading.firebaseTimestamp,
                reading.appReceivedTimestamp ?? DateTime.now(),
              );
              ref.read(latencyDisplayProvider.notifier).state = tracker.formattedLatency;

              final adaptive = ref.read(adaptiveSamplingServiceProvider);
              adaptive.addReading(reading);
              ref.read(adaptiveSamplingStateProvider.notifier).state = adaptive.evaluate();
            });

            final qualityResult = ref.watch(currentWaterQualityResultProvider(reading));
            final isSensorOnline = DateTime.now().difference(reading.timestamp).inMinutes.abs() < 5;
            final latencyText = ref.watch(latencyDisplayProvider);
            final adaptiveState = ref.watch(adaptiveSamplingStateProvider);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & System Status Header
                  GreetingHeader(isOnline: isSensorOnline),
                  const SizedBox(height: 20),

                  // Overall Water Quality Screening Score
                  PurityCard(result: qualityResult),
                  const SizedBox(height: 12),

                  // ─── Last Updated + Latency + Stability Row ───
                  _buildStatusRow(
                    context,
                    reading: reading,
                    latencyText: latencyText,
                    isStable: adaptiveState?.isStable ?? false,
                  ),
                  const SizedBox(height: 20),

                  // Section Title
                  Text(
                    'LIVE SENSOR READINGS',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // 2x2 Sensor Grid
                  SensorGrid(
                    reading: reading,
                    result: qualityResult,
                  ),
                  const SizedBox(height: 20),

                  // Water Safety Diagnostic & Solution Card
                  WaterSafetyRecommendationCard(
                    reading: reading,
                    result: qualityResult,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('Sensor Connection Error: $err'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(liveSensorStreamProvider(AppConstants.defaultDeviceId));
                    },
                    child: const Text('Retry Connection'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a compact status row showing last update time, latency, and stability.
  Widget _buildStatusRow(
    BuildContext context, {
    required dynamic reading,
    required String latencyText,
    required bool isStable,
  }) {
    final theme = Theme.of(context);
    final timestamp = reading.timestamp as DateTime;
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        // Last updated timestamp
        _buildStatusChip(
          icon: Icons.access_time_rounded,
          label: 'Last: $timeStr',
          color: theme.colorScheme.onSurfaceVariant,
          bgColor: theme.colorScheme.surfaceContainerHighest,
        ),

        // Latency indicator
        if (latencyText.isNotEmpty)
          _buildStatusChip(
            icon: Icons.speed_rounded,
            label: latencyText,
            color: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.1),
          ),

        // Stability indicator
        _buildStatusChip(
          icon: isStable ? Icons.check_circle_rounded : Icons.change_circle_rounded,
          label: isStable ? 'Stable ✓' : 'Changing ↕',
          color: isStable ? AppColors.excellent : AppColors.moderate,
          bgColor: (isStable ? AppColors.excellent : AppColors.moderate)
              .withValues(alpha: 0.1),
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
