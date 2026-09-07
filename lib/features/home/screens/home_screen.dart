import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sensor_reading.dart';
import '../../../providers/alert_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/sensor_provider.dart';
import '../widgets/greeting_header.dart';
import '../widgets/purity_card.dart';
import '../widgets/sensor_grid.dart';
import '../widgets/water_safety_recommendation_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDeviceId = ref.watch(selectedDeviceProvider);
    final liveReadingAsync = ref.watch(liveSensorStreamProvider(activeDeviceId));

    // Retrieve live reading or fallback placeholder so the Home Screen and its
    // embedded ESP32 WebView card are ALWAYS displayed and interactive.
    final reading = liveReadingAsync.valueOrNull ??
        SensorReading(
          deviceId: activeDeviceId,
          timestamp: DateTime.now(),
          ph: 7.0,
          tds: 150.0,
          turbidity: 0.8,
          temperature: 24.0,
          status: 'ESP32 DIRECT',
        );

    // Trigger automatic alert checking & telemetry tracking when live data arrives
    if (liveReadingAsync.hasValue) {
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
    }

    final qualityResult = ref.watch(currentWaterQualityResultProvider(reading));
    final isEsp32Connected = ref.watch(esp32SensorDataSourceProvider).isConnected;
    final isSensorOnline = isEsp32Connected ||
        (liveReadingAsync.hasValue &&
            DateTime.now().difference(reading.timestamp).inSeconds.abs() < 15);
    final latencyText = ref.watch(latencyDisplayProvider);
    final adaptiveState = ref.watch(adaptiveSamplingStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Water Monitor'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Sensor Data',
            onPressed: () {
              ref.read(esp32SensorDataSourceProvider).manualRefresh();
              ref.invalidate(liveSensorStreamProvider(activeDeviceId));
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
              // Greeting & System Status Header
              GreetingHeader(
                isOnline: isSensorOnline,
                deviceId: activeDeviceId,
                onRetry: () {
                  ref.read(esp32SensorDataSourceProvider).manualRefresh();
                  ref.invalidate(liveSensorStreamProvider(activeDeviceId));
                },
              ),
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
              const SizedBox(height: 20),

              // ESP32 Live Embedded Web Dashboard
              const Esp32WebViewCard(),
              const SizedBox(height: 16),
            ],
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

        // ESP32 Direct Link indicator
        _buildStatusChip(
          icon: Icons.wifi_tethering_rounded,
          label: 'ESP32 AP: 192.168.4.1',
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

/// A large interactive container displaying the live ESP32 web dashboard directly.
/// Loads http://192.168.4.1/ inside an in-app WebView without requiring internet.
class Esp32WebViewCard extends StatefulWidget {
  const Esp32WebViewCard({super.key});

  @override
  State<Esp32WebViewCard> createState() => _Esp32WebViewCardState();
}

class _Esp32WebViewCardState extends State<Esp32WebViewCard> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  static const String esp32Url = 'http://192.168.4.1/';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(esp32Url));
  }

  void _reloadPage() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _controller.loadRequest(Uri.parse(esp32Url));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.devices_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ESP32 Live Web Dashboard',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '192.168.4.1',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Reload ESP32 Webpage',
                      onPressed: _reloadPage,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // WebView Container
          SizedBox(
            height: 480,
            child: Stack(
              children: [
                WebViewWidget(
                  controller: _controller,
                  gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      EagerGestureRecognizer.new,
                    ),
                  },
                ),

                // Loading Indicator Overlay
                if (_isLoading)
                  Container(
                    color: theme.colorScheme.surface.withValues(alpha: 0.8),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2.5),
                          SizedBox(height: 12),
                          Text(
                            'Loading ESP32 Web Dashboard...',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Error Overlay
                if (_errorMessage != null && !_isLoading)
                  Container(
                    color: theme.colorScheme.surface,
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.critical),
                          const SizedBox(height: 12),
                          const Text(
                            'Could not load ESP32 Webpage',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Make sure your phone is connected to WaterMonitor Wi-Fi hotspot.\n$_errorMessage',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry Webpage'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            onPressed: _reloadPage,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

