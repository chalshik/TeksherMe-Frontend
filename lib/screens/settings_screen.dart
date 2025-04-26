import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import '../service/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_wrapper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile section
            if (user != null) _buildProfileSection(context, user),
            
            const SizedBox(height: 24),
            
            // Settings list
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    title: Text(_getThemeModeName(dataService.themeMode)),
                    leading: Icon(
                      dataService.themeMode == ThemeMode.light 
                        ? Icons.light_mode
                        : dataService.themeMode == ThemeMode.dark
                          ? Icons.dark_mode
                          : MediaQuery.of(context).platformBrightness == Brightness.light
                            ? Icons.light_mode
                            : Icons.dark_mode,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showThemeOptions(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    title: const Text('Reset Progress'),
                    leading: const Icon(Icons.refresh),
                    onTap: () => _showResetConfirmation(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    title: const Text('Log Out'),
                    leading: const Icon(Icons.logout),
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
            
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
  
  Widget _buildProfileSection(BuildContext context, User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null 
                ? Text(
                    user.displayName?.isNotEmpty == true 
                      ? user.displayName![0].toUpperCase() 
                      : (user.email?[0].toUpperCase() ?? 'U')
                  )
                : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'User',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleLogout(BuildContext context) async {
    final dataService = Provider.of<FirebaseDataService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authService.signOut();
              dataService.logout(); // Also clear data service cache if needed
              
              // Navigate back to the root context and rebuild from AuthWrapper
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
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
    final dataService = Provider.of<FirebaseDataService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              icon: MediaQuery.of(context).platformBrightness == Brightness.light
                  ? Icons.light_mode
                  : Icons.dark_mode,
              title: 'System Default',
              onTap: () {
                dataService.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
              isSelected: dataService.themeMode == ThemeMode.system,
            ),
            const Divider(height: 1),
            _buildThemeOption(
              context,
              icon: Icons.light_mode,
              title: 'Light',
              onTap: () {
                dataService.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
              isSelected: dataService.themeMode == ThemeMode.light,
            ),
            const Divider(height: 1),
            _buildThemeOption(
              context,
              icon: Icons.dark_mode,
              title: 'Dark',
              onTap: () {
                dataService.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
              isSelected: dataService.themeMode == ThemeMode.dark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
  
  void _showResetConfirmation(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context, listen: false);
    
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