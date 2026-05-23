import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Appearance'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              context,
              children: [
                _buildSettingsTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  subtitle: 'Enable dark theme',
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(darkModeProvider.notifier).toggle();
                    },
                    activeTrackColor: AppColors.primary,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            _buildSectionTitle('Notifications'),
            const SizedBox(height: 12),
            _buildSettingsCard(
                  context,
                  children: [
                    _buildSettingsTile(
                      icon: Icons.notifications_rounded,
                      title: 'Test Reminders',
                      subtitle: 'Get reminded to take regular tests',
                      trailing: Switch(
                        value: false,
                        onChanged: (value) {},
                        activeTrackColor: AppColors.primary,
                      ),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      icon: Icons.calendar_today_rounded,
                      title: 'Weekly Summary',
                      subtitle: 'Receive weekly health summaries',
                      trailing: Switch(
                        value: true,
                        onChanged: (value) {},
                        activeTrackColor: AppColors.primary,
                      ),
                    ),
                  ],
                )
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            _buildSectionTitle('Data & Privacy'),
            const SizedBox(height: 12),
            _buildSettingsCard(
                  context,
                  children: [
                    _buildSettingsTile(
                      icon: Icons.cloud_upload_rounded,
                      title: 'Cloud Backup',
                      subtitle: 'Sync your data securely',
                      trailing: Switch(
                        value: false,
                        onChanged: (value) {},
                        activeTrackColor: AppColors.primary,
                      ),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      icon: Icons.delete_outline_rounded,
                      title: 'Clear Local Data',
                      subtitle: 'Remove all locally stored data',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showClearDataDialog(context, ref),
                    ),
                  ],
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            _buildSectionTitle('About'),
            const SizedBox(height: 12),
            _buildSettingsCard(
                  context,
                  children: [
                    _buildSettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'App Version',
                      subtitle: '1.0.0',
                      trailing: const SizedBox.shrink(),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showTermsDialog(context),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showPrivacyDialog(context),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      icon: Icons.code_rounded,
                      title: 'Open Source Licenses',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showLicensePage(context: context),
                    ),
                  ],
                )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'GaitWatch',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Early Detection, Better Care',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2024 GaitWatch',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text(
          'This will delete all your locally stored data including test history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(testHistoryProvider.notifier).clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Local data cleared'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By using GaitWatch, you agree to the following terms:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Text(
                '• GaitWatch is intended for informational purposes only\n'
                '• This app does not provide medical advice\n'
                '• Always consult healthcare professionals for diagnosis\n'
                '• You are responsible for maintaining backup of your data\n'
                '• We reserve the right to update these terms',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Privacy Matters',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('GaitWatch is committed to protecting your privacy:'),
              SizedBox(height: 12),
              Text(
                '• All sensor data is processed locally on your device\n'
                '• No personal health data is shared without consent\n'
                '• AI predictions are encrypted during transmission\n'
                '• You can delete your data at any time\n'
                '• We do not sell your data to third parties',
              ),
              SizedBox(height: 12),
              Text(
                'For questions, contact: privacy@gaitwatch.com',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
