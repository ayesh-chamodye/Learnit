import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _downloadPath = '';
  bool _isDarkMode = false;
  bool _autoDownload = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _downloadPath = prefs.getString('download_path') ?? '';
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      _autoDownload = prefs.getBool('auto_download') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
    _applyTheme(_isDarkMode);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('download_path', _downloadPath);
    await prefs.setBool('dark_mode', _isDarkMode);
    await prefs.setBool('auto_download', _autoDownload);
    await prefs.setBool('notifications', _notificationsEnabled);
  }

  Future<void> _selectDownloadPath() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Download Folder',
      );

      if (selectedDirectory != null) {
        setState(() {
          _downloadPath = selectedDirectory;
        });
        await _saveSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download path set to: $selectedDirectory'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyTheme(bool isDark) {
    MyApp.of(context)?.setTheme(isDark);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Downloads', onSurface),
          _buildSettingCard(
            icon: Icons.folder,
            title: 'Download Path',
            subtitle: _downloadPath.isEmpty ? 'Not set (default Downloads)' : _downloadPath,
            onTap: _selectDownloadPath,
            onSurface: onSurface,
            primaryColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          _buildSwitchSetting(
            icon: Icons.download,
            title: 'Auto Download',
            subtitle: 'Automatically download PDFs for offline access',
            value: _autoDownload,
            onChanged: (value) {
              setState(() {
                _autoDownload = value;
              });
              _saveSettings();
            },
            onSurface: onSurface,
            primaryColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Appearance', onSurface),
          _buildSwitchSetting(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Use dark theme',
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
              _saveSettings();
              _applyTheme(value);
            },
            onSurface: onSurface,
            primaryColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Notifications', onSurface),
          _buildSwitchSetting(
            icon: Icons.notifications,
            title: 'Enable Notifications',
            subtitle: 'Get notified about new content',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveSettings();
            },
            onSurface: onSurface,
            primaryColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('About', onSurface),
          _buildSettingCard(
            icon: Icons.info,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: () {},
            onSurface: onSurface,
            primaryColor: theme.colorScheme.primary,
          ),
          _buildSettingCard(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () {},
            onSurface: onSurface,
            primaryColor: theme.colorScheme.primary,
          ),
          _buildSettingCard(
            icon: Icons.description,
            title: 'Terms of Service',
            onTap: () {},
            onSurface: onSurface,
            primaryColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final dialogContext = context;
                final scaffoldContext = context;
                final confirmed = await showDialog<bool>(
                  context: dialogContext,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cache'),
                    content: const Text('This will clear all cached PDF thumbnails. Continue?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                if (!mounted) return;
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              },
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Clear Cache'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurface.withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required Color onSurface,
    required Color primaryColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color onSurface,
    required Color primaryColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
