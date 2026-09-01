import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/demo_mode_provider.dart';

class GreetingHeader extends ConsumerWidget {
  final bool isOnline;

  const GreetingHeader({
    super.key,
    this.isOnline = true,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final userName = user?.name ?? 'Researcher';
    final isDemoMode = ref.watch(demoModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, $userName 👋',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? AppColors.excellent : AppColors.critical,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Smart Water System Activated' : 'System Offline',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isOnline ? AppColors.excellent : AppColors.critical,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Demo Mode Pill Switch
            InkWell(
              onTap: () {
                ref.read(demoModeProvider.notifier).toggleDemoMode();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDemoMode
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDemoMode ? AppColors.primary : AppColors.lightBorder,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDemoMode ? Icons.bolt_rounded : Icons.flash_off_rounded,
                      size: 16,
                      color: isDemoMode ? AppColors.primary : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDemoMode ? 'DEMO ON' : 'DEMO OFF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDemoMode ? AppColors.primary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
