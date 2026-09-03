import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/alert_provider.dart';
import '../widgets/alert_card.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final alerts = ref.watch(alertsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Alerts'),
        centerTitle: false,
        actions: [
          if (alerts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 22),
              tooltip: 'Clear All Alerts',
              onPressed: () {
                ref.read(alertsNotifierProvider.notifier).clearAll();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // All Alerts Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'All Alerts',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${alerts.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (alerts.isNotEmpty)
                    Text(
                      'Swipe to dismiss',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Alert List View with Dismissible
            Expanded(
              child: alerts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Active Alerts',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Water quality sensors are within safe configured limits.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: alerts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return Dismissible(
                          key: Key(alert.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            decoration: BoxDecoration(
                              color: AppColors.poor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                                SizedBox(width: 6),
                                Text(
                                  'Dismiss',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (direction) {
                            ref.read(alertsNotifierProvider.notifier).removeAlert(alert.id);
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Dismissed: ${alert.title}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: AlertCard(
                            alert: alert,
                            onMarkAsRead: () {
                              ref.read(alertsNotifierProvider.notifier).markAsRead(alert.id);
                            },
                          ),
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
