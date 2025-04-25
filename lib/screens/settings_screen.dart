import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/data_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(_getThemeModeName(dataService.themeMode)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showThemeOptions(context),
            ),
            const Divider(),
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Log Out'),
              leading: const Icon(Icons.logout),
              onTap: () => dataService.logout(),
            ),
            const Divider(),
            const Text(
              'Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Reset Progress'),
              leading: const Icon(Icons.refresh),
              onTap: () => _showResetConfirmation(context),
            ),
            const Divider(),
            const Spacer(),
            Center(
              child: Text(
                'Version 1.0.0',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }
  
  void _showThemeOptions(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              dataService.setThemeMode(ThemeMode.system);
              Navigator.pop(context);
            },
            child: const Text('System Default'),
          ),
          SimpleDialogOption(
            onPressed: () {
              dataService.setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
            child: const Text('Light'),
          ),
          SimpleDialogOption(
            onPressed: () {
              dataService.setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
            child: const Text('Dark'),
          ),
        ],
      ),
    );
  }
  
  void _showResetConfirmation(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text('This will reset all your progress and bookmarks. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              dataService.resetAllProgress();
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 