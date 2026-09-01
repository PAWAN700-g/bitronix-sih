import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/alert_model.dart';
import '../../../providers/alert_provider.dart';
import '../widgets/alert_card.dart';

final alertFilterProvider = StateProvider<AlertSeverity?>((ref) => null);

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsNotifierProvider);
    final selectedFilter = ref.watch(alertFilterProvider);

    final filteredAlerts = selectedFilter == null
        ? alerts
        : alerts.where((a) => a.severity == selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Alerts'),
        centerTitle: false,
        actions: [
          if (alerts.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(alertsNotifierProvider.notifier).clearAll();
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Alerts'),
                      selected: selectedFilter == null,
                      onSelected: (_) => ref.read(alertFilterProvider.notifier).state = null,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Critical'),
                      selected: selectedFilter == AlertSeverity.critical,
                      onSelected: (_) => ref.read(alertFilterProvider.notifier).state = AlertSeverity.critical,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Warning'),
                      selected: selectedFilter == AlertSeverity.warning,
                      onSelected: (_) => ref.read(alertFilterProvider.notifier).state = AlertSeverity.warning,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Info'),
                      selected: selectedFilter == AlertSeverity.info,
                      onSelected: (_) => ref.read(alertFilterProvider.notifier).state = AlertSeverity.info,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Alert List View
            Expanded(
              child: filteredAlerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No Alerts Recorded',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Water quality and IoT device parameters are safe.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredAlerts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final alert = filteredAlerts[index];
                        return AlertCard(
                          alert: alert,
                          onMarkAsRead: () {
                            ref.read(alertsNotifierProvider.notifier).markAsRead(alert.id);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
