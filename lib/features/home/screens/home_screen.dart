import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
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
            });

            final qualityResult = ref.watch(currentWaterQualityResultProvider(reading));

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & System Status Header
                  const GreetingHeader(isOnline: true),
                  const SizedBox(height: 20),

                  // Overall Purity Card
                  PurityCard(result: qualityResult),
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
}
