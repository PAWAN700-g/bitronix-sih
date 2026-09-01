import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/filtration_session.dart';
import '../../../providers/filtration_provider.dart';

class FiltrationProcessCard extends ConsumerWidget {
  const FiltrationProcessCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(filtrationProvider);
    final currentStep = session.state.currentStepIndex;

    final steps = [
      'Water Detected',
      'Quality Analysis',
      'Filtration',
      'Final Quality Check',
      'Clean Water',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FILTRATION PROCESS',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.state.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: session.state == FiltrationState.inProgress
                            ? AppColors.primary
                            : (session.state == FiltrationState.complete
                                ? AppColors.excellent
                                : theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(session.progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: session.progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),

            // Steps Process Visualizer Timeline
            Column(
              children: List.generate(steps.length, (index) {
                final isDone = index < currentStep;
                final isCurrent = index == currentStep && session.state != FiltrationState.complete;
                final isCompleteAll = session.state == FiltrationState.complete;

                Widget iconWidget;
                if (isCompleteAll || isDone) {
                  iconWidget = const Icon(Icons.check_circle, size: 20, color: AppColors.excellent);
                } else if (isCurrent) {
                  iconWidget = const Icon(Icons.radio_button_checked, size: 20, color: AppColors.primary);
                } else {
                  iconWidget = Icon(Icons.radio_button_unchecked, size: 20, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4));
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      iconWidget,
                      const SizedBox(width: 12),
                      Text(
                        'Step ${index + 1}: ${steps[index]}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: (isCurrent || isCompleteAll) ? FontWeight.bold : FontWeight.normal,
                          color: (isDone || isCompleteAll)
                              ? theme.colorScheme.onSurface
                              : (isCurrent ? AppColors.primary : theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Live Simulation Control Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: session.state == FiltrationState.inProgress
                    ? null
                    : () {
                        ref.read(filtrationProvider.notifier).startFiltrationSimulation();
                      },
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: Text(
                  session.state == FiltrationState.inProgress
                      ? 'Simulating Filtration...'
                      : 'Start Live Filtration Demo',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
