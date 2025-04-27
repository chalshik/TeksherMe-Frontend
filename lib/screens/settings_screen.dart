import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import '../data/theme_service.dart';
import '../service/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_wrapper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
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
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  // Appearance section
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'APPEARANCE',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Theme toggle
                  ListTile(
                    title: const Text('Theme Mode'),
                    subtitle: Text(_getThemeModeName(themeService.themeMode)),
                    leading: Icon(
                      themeService.themeMode == ThemeMode.light 
                        ? Icons.light_mode
                        : themeService.themeMode == ThemeMode.dark
                          ? Icons.dark_mode
                          : MediaQuery.of(context).platformBrightness == Brightness.light
                            ? Icons.light_mode
                            : Icons.dark_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showThemeOptions(context),
                  ),
                  
                  // Color scheme
                  ListTile(
                    title: const Text('Color Scheme'),
                    subtitle: const Text('Customize app colors'),
                    leading: Icon(
                      Icons.palette_outlined,
                      color: themeService.primaryColor,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showColorOptions(context),
                  ),
                  
                  const Divider(),
                  
                  // Application section
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'APPLICATION',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Reset progress
                  ListTile(
                    title: const Text('Reset Progress'),
                    subtitle: const Text('Clear all saved test progress'),
                    leading: Icon(
                      Icons.refresh,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () => _showResetConfirmation(context),
                  ),
                  
                  // Logout
                  ListTile(
                    title: const Text('Log Out'),
                    subtitle: const Text('Sign out from your account'),
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null 
                ? Text(
                    user.displayName?.isNotEmpty == true 
                      ? user.displayName![0].toUpperCase() 
                      : (user.email?[0].toUpperCase() ?? 'U'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                // Show edit profile dialog or navigate to edit profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit profile not implemented yet')),
                );
              },
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
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Choose Theme',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _buildThemeOption(
              context,
              icon: Icons.brightness_auto,
              title: 'System Default',
              subtitle: 'Follows your device theme setting',
              onTap: () {
                themeService.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
              isSelected: themeService.themeMode == ThemeMode.system,
            ),
            _buildThemeOption(
              context,
              icon: Icons.light_mode,
              title: 'Light',
              subtitle: 'Light theme will be used',
              onTap: () {
                themeService.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
              isSelected: themeService.themeMode == ThemeMode.light,
            ),
            _buildThemeOption(
              context,
              icon: Icons.dark_mode,
              title: 'Dark',
              subtitle: 'Dark theme will be used',
              onTap: () {
                themeService.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
              isSelected: themeService.themeMode == ThemeMode.dark,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showColorOptions(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Select Color Scheme',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: themeService.availableColorSchemes.map((color) {
                return InkWell(
                  onTap: () {
                    themeService.setPrimaryColor(color);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeService.primaryColor == color 
                            ? Theme.of(context).colorScheme.onPrimary 
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: themeService.primaryColor == color 
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: isSelected 
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
  
  void _showResetConfirmation(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text(
          'This will reset all your progress on questions and reset all scores. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              dataService.resetAllProgress();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All progress has been reset'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
} 