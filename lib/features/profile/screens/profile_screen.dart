import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/share_service.dart';
import '../../auth/screens/signup_screen.dart';
import 'feedback_screen.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // User Info Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Researcher',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'pawan@sih.gov.in',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'PREFERENCES',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),

            // 1. Edit Profile
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile edit mode enabled.')),
                );
              },
            ),

            // 2. Notifications
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                );
              },
            ),

            // 3. Theme Toggle
            ListTile(
              leading: Icon(
                themeMode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              ),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: themeMode == ThemeMode.dark,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
            ),

            // 4. Device Settings
            ListTile(
              leading: const Icon(Icons.settings_input_component_outlined),
              title: const Text('Device Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sensor calibration & ESP32 baud rates configuration.')),
                );
              },
            ),

            const SizedBox(height: 16),
            Text(
              'SUPPORT & APP LOGISTICS',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),

            // 5. Rate App
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Rate App'),
              subtitle: const Text('Rate us out of 5 stars', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showRateAppDialog(context);
              },
            ),

            // 6. Share App
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share App'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ShareService().shareApp();
              },
            ),

            // 7. Feedback
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Feedback'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                );
              },
            ),

            // 8. About
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: '1.0.0 (SIH Prototype)',
                  applicationIcon: const Icon(Icons.water_drop, color: AppColors.primary, size: 40),
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      AppConstants.sihProjectTitle,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(AppConstants.medicalDisclaimer),
                  ],
                );
              },
            ),

            const Divider(height: 32),

            // 9. Logout Button
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.poor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showRateAppDialog(BuildContext context) {
    int selectedStars = 5;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            String getRatingLabel(int stars) {
              switch (stars) {
                case 1:
                  return 'Poor';
                case 2:
                  return 'Could be better';
                case 3:
                  return 'Good';
                case 4:
                  return 'Very Good!';
                case 5:
                  return 'Excellent! ⭐';
                default:
                  return '';
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.amber, size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Rate Your Experience',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How would you rate Smart Water Monitor?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        iconSize: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () {
                          setState(() {
                            selectedStars = starIndex;
                          });
                        },
                        icon: Icon(
                          starIndex <= selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getRatingLabel(selectedStars),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: feedbackController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Any comments or feedback? (Optional)',
                      hintStyle: const TextStyle(fontSize: 12),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Maybe Later'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Thank you for your $selectedStars-star rating!'),
                        backgroundColor: AppColors.excellent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
