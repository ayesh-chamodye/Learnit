import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String? _downloadPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _downloadPath = prefs.getString('download_path');
    });
    _applyTheme(_isDarkMode);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    await prefs.setBool('notifications', _notificationsEnabled);
    if (_downloadPath != null) {
      await prefs.setString('download_path', _downloadPath!);
    }
  }

  void _applyTheme(bool isDark) {
    MyApp.of(context)?.setTheme(isDark);
  }

  Future<void> _pickDownloadFolder() async {
    try {
      // Use directory picker
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Download Folder',
        initialDirectory: _downloadPath,
      );

      if (selectedDirectory != null) {
        setState(() {
          _downloadPath = selectedDirectory;
        });
        await _saveSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download folder set to: $selectedDirectory'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            title: 'Notifications',
            subtitle: 'Enable push notifications',
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
          _buildSectionHeader('Downloads', onSurface),
          _buildSettingCard(
            icon: Icons.folder,
            title: 'Download Location',
            subtitle: _downloadPath != null
                ? _shortenPath(_downloadPath!)
                : 'Default (Downloads folder)',
            onTap: _pickDownloadFolder,
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

  String _shortenPath(String path) {
    // Show last 2-3 folder names to keep it readable
    final parts = path.split(Platform.pathSeparator);
    if (parts.length <= 2) return path;
    return '.../${parts[parts.length - 2]}/${parts[parts.length - 1]}';
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