import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../main.dart';
import 'html_viewer_screen.dart';

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
             onTap: () => _navigateToHtml(
               context,
               'About LearnIt',
               '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      padding: 20px;
      margin: 0;
      background-color: #f5f5f5;
      color: #333;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      background: white;
      padding: 24px;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    h1 {
      color: #6750A4;
      font-size: 24px;
      margin-bottom: 16px;
      border-bottom: 2px solid #6750A4;
      padding-bottom: 8px;
    }
    p {
      line-height: 1.6;
      font-size: 16px;
      margin-bottom: 12px;
    }
    .app-info {
      text-align: center;
      margin-bottom: 24px;
    }
    .app-name {
      font-size: 28px;
      font-weight: bold;
      color: #6750A4;
      margin-bottom: 8px;
    }
    .version {
      color: #666;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="app-info">
      <div class="app-name">📚 LearnIt</div>
      <div class="version">Version 1.0.0</div>
    </div>
    <h1>About</h1>
    <p><strong>LearnIt</strong> is your comprehensive educational platform providing free access to Sri Lanka's e-Thaksalawa learning resources.</p>
    <p>Our mission is to make quality education accessible to every student across the nation by providing organized digital textbooks, past papers, video lessons, and teacher guides — all in one place.</p>
    <p>The app features:</p>
    <ul>
      <li>📖 Past Papers & Model Papers</li>
      <li>📚 Text Books & Teacher Guides</li>
      <li>🎥 Educational Video Content</li>
      <li>📊 Progress Tracking</li>
      <li>🌐 Sinhala, Tamil & English Support</li>
    </ul>
    <p>LearnIt is designed with a clean, modern interface and built using Flutter for a smooth experience on both mobile and web platforms.</p>
    <p><em>"Education is the passport to the future, for tomorrow belongs to those who prepare for it today."</em></p>
    <p style="text-align: right; color: #666;">— Malcolm X</p>
  </div>
</body>
</html>
''',
             ),
             onSurface: onSurface,
             primaryColor: theme.colorScheme.primary,
           ),
           _buildSettingCard(
             icon: Icons.privacy_tip,
             title: 'Privacy Policy',
             onTap: () => _navigateToHtml(
               context,
               'Privacy Policy',
               '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      padding: 20px;
      margin: 0;
      background-color: #f5f5f5;
      color: #333;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      background: white;
      padding: 24px;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    h1 {
      color: #6750A4;
      font-size: 24px;
      margin-bottom: 16px;
      border-bottom: 2px solid #6750A4;
      padding-bottom: 8px;
    }
    h2 {
      font-size: 18px;
      color: #444;
      margin-top: 24px;
      margin-bottom: 12px;
    }
    p {
      line-height: 1.6;
      font-size: 16px;
      margin-bottom: 12px;
    }
    ul {
      margin: 12px 0;
      padding-left: 24px;
      line-height: 1.8;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Privacy Policy</h1>
    <p><strong>Last updated:</strong> May 14, 2026</p>

    <h2>Information We Collect</h2>
    <p>LearnIt collects minimal information necessary to provide and improve our services:</p>
    <ul>
      <li><strong>Settings Preferences:</strong> Dark mode, notification preferences, and download location are stored locally on your device.</li>
      <li><strong>Usage Data:</strong> Anonymous analytics may be collected to improve app performance and user experience.</li>
      <li><strong>Advertisements:</strong> AdMob may collect device information and usage data to serve relevant ads (see Google's privacy policy).</li>
    </ul>

    <h2>How We Use Information</h2>
    <p>We use collected information solely for:</p>
    <ul>
      <li>Providing and maintaining the app's functionality</li>
      <li>Remembering your preferences</li>
      <li>Improving user experience</li>
      <li>Displaying relevant advertisements</li>
    </ul>

    <h2>Data Sharing</h2>
    <p>We do not sell, trade, or rent your personal information to third parties. We may share aggregated, anonymized data for analytics purposes.</p>

    <h2>Third-Party Services</h2>
    <p>The app uses the following third-party services:</p>
    <ul>
      <li><strong>e-Thaksalawa API:</strong> Provides educational content. Their privacy policy applies to data collected through their services.</li>
      <li><strong>Google AdMob:</strong> Serves advertisements. Google's privacy policy applies.</li>
      <li><strong>YouTube:</strong> Hosts video content. YouTube's privacy policy applies.</li>
    </ul>

    <h2>Your Rights</h2>
    <p>You have the right to:</p>
    <ul>
      <li>Access any personal data we store</li>
      <li>Request deletion of your data</li>
      <li>Opt out of personalized ads through device settings</li>
      <li>Uninstall the app at any time (all local data will be removed)</li>
    </ul>

    <h2>Children's Privacy</h2>
    <p>LearnIt is designed for educational use by students of all ages. We do not knowingly collect personal information from children. Parents or guardians may contact us regarding any concerns.</p>

    <h2>Contact Us</h2>
    <p>If you have questions about this Privacy Policy, please contact the app developer.</p>

    <h2>Changes to This Policy</h2>
    <p>We may update our Privacy Policy from time to time. Any changes will be posted within the app or on our website.</p>
  </div>
</body>
</html>
''',
             ),
             onSurface: onSurface,
             primaryColor: theme.colorScheme.primary,
           ),
           _buildSettingCard(
             icon: Icons.description,
             title: 'Terms of Service',
             onTap: () => _navigateToHtml(
               context,
               'Terms of Service',
               '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      padding: 20px;
      margin: 0;
      background-color: #f5f5f5;
      color: #333;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      background: white;
      padding: 24px;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    h1 {
      color: #6750A4;
      font-size: 24px;
      margin-bottom: 16px;
      border-bottom: 2px solid #6750A4;
      padding-bottom: 8px;
    }
    h2 {
      font-size: 18px;
      color: #444;
      margin-top: 24px;
      margin-bottom: 12px;
    }
    p {
      line-height: 1.6;
      font-size: 16px;
      margin-bottom: 12px;
    }
    ul {
      margin: 12px 0;
      padding-left: 24px;
      line-height: 1.8;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Terms of Service</h1>
    <p><strong>Last updated:</strong> May 14, 2026</p>

    <h2>1. Acceptance of Terms</h2>
    <p>By accessing and using the LearnIt app, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this app.</p>

    <h2>2. Description of Service</h2>
    <p>LearnIt provides free access to educational content sourced from Sri Lanka's e-Thaksalawa platform, including textbooks, past papers, video lessons, and other learning materials for academic purposes.</p>

    <h2>3. User Responsibilities</h2>
    <p>As a user, you agree to:</p>
    <ul>
      <li>Use the app only for lawful educational purposes</li>
      <li>Not attempt to modify, reverse engineer, or redistribute the app content</li>
      <li>Not use the app for commercial redistribution of content</li>
      <li>Respect intellectual property rights of content creators</li>
      <li>Provide accurate feedback if reporting issues</li>
    </ul>

    <h2>4. Intellectual Property</h2>
    <p>All content provided through LearnIt (text, images, videos) is copyrighted by their respective owners, primarily the Ministry of Education, Sri Lanka. The app and its design are the intellectual property of the developer. Content is used under educational fair use principles.</p>

    <h2>5. Advertisements</h2>
    <p>The app displays advertisements via Google AdMob to support development costs. By using the app, you agree to view these ads and comply with Google's terms. Ad content may be targeted based on general app usage patterns.</p>

    <h2>6. Limitation of Liability</h2>
    <p>LearnIt is provided "as is" without warranties of any kind. We do not guarantee:</p>
    <ul>
      <li>Uninterrupted or error-free service</li>
      <li>Accuracy or completeness of educational content</li>
      <li>Availability of servers or internet connectivity</li>
      <li>Fitness for a particular educational outcome</li>
    </ul>

    <h2>7. Third-Party Content & Links</h2>
    <p>The app links to external services (YouTube, e-Thaksalawa). We are not responsible for the availability, accuracy, or legality of third-party content. Each third-party service's terms apply to their content.</p>

    <h2>8. Modifications to Service</h2>
    <p>We reserve the right to modify, suspend, or discontinue any part of the app at any time without notice. We may also update these Terms of Service periodically; continued use constitutes acceptance of changes.</p>

    <h2>9. Termination</h2>
    <p>We may terminate or suspend access to the service immediately, without prior notice, for any violation of these terms or for any other reason we deem necessary.</p>

    <h2>10. Governing Law</h2>
    <p>These terms are governed by the laws of Sri Lanka. Any disputes shall be resolved in the courts of Sri Lanka.</p>

    <h2>11. Contact Information</h2>
    <p>Questions about these Terms of Service should be directed to the app developer.</p>

    <h2>12. Entire Agreement</h2>
    <p>These Terms of Service constitute the entire agreement between you and LearnIt regarding your use of the app, superseding any prior agreements.</p>
  </div>
</body>
</html>
''',
             ),
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

   void _navigateToHtml(BuildContext context, String title, String htmlContent) {
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => HtmlViewerScreen(
           title: title,
           htmlContent: htmlContent,
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