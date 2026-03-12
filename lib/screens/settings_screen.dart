import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/bookmark_store.dart';
import '../data/premium_store.dart';
import '../data/progress_store.dart';
import 'premium_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _versionLabel = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    loadPremiumStore().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionLabel = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _confirmResetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This will clear learning progress across all categories on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await resetProgressStore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress reset successfully.')),
    );
  }

  Future<void> _confirmClearBookmarks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear bookmarks?'),
        content: const Text(
          'This will remove all bookmarked words across every category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await clearAllBookmarks(progressCategories);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All bookmarks cleared.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Premium',
            children: [
              _SettingsTile(
                icon: Icons.workspace_premium_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: premiumUnlocked ? 'Premium Active' : 'Unlock Premium',
                subtitle: premiumUnlocked
                    ? 'Unlimited practice and revision unlocked'
                    : 'See premium features and upcoming payment access',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PremiumScreen(),
                    ),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: 'Data',
            children: [
              _SettingsTile(
                icon: Icons.restart_alt_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'Reset progress',
                subtitle: 'Start learning progress from zero',
                onTap: _confirmResetProgress,
              ),
              _SettingsTile(
                icon: Icons.bookmarks_outlined,
                iconColor: const Color(0xFF0F766E),
                title: 'Clear bookmarks',
                subtitle: 'Remove all saved words from Revise',
                onTap: _confirmClearBookmarks,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            title: 'App',
            children: [
              _SettingsInfoTile(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: 'Version',
                value: _versionLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _SettingsInfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _SettingsInfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
