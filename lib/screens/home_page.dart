import 'package:flutter/material.dart';
import '../data/theme.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'bookmarks_screen.dart';
import 'settings_screen.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  
  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  static const List<Widget> _screens = [
    HomeScreen(),
    ExploreScreen(),
    BookmarksScreen(),
    SettingsScreen(),
  ];
  
  void _onItemTapped(int index) {
    // Reset animation and play it again
    _animationController.reset();
    _animationController.forward();
    
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    
    return Scaffold(
      body: _screens[_selectedIndex],
      extendBody: true, // Important for bottom nav bar transparency
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            backgroundColor: isLightMode 
                ? Colors.white 
                : TeksherTheme.surfaceDark,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: isLightMode ? Colors.black45 : Colors.white60,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 0,
            items: [
              _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Home', 0),
              _buildNavItem(Icons.explore_rounded, Icons.explore_outlined, 'Explore', 1),
              _buildNavItem(Icons.bookmark_rounded, Icons.bookmark_border_rounded, 'Bookmarks', 2),
              _buildNavItem(Icons.settings_rounded, Icons.settings_outlined, 'Settings', 3),
            ],
          ),
        ),
      ),
    );
  }
  
  BottomNavigationBarItem _buildNavItem(
    IconData selectedIcon, 
    IconData unselectedIcon, 
    String label,
    int index,
  ) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          border: index == _selectedIndex
              ? Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3.0,
                  ),
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: index == _selectedIndex
                  ? ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: Icon(
                        selectedIcon,
                        key: ValueKey('selected-$index'),
                      ),
                    )
                  : Icon(
                      unselectedIcon,
                      key: ValueKey('unselected-$index'),
                    ),
            ),
          ],
        ),
      ),
      label: label,
    );
  }
} 