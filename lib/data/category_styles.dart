import 'package:flutter/material.dart';

/// Provides default styling for category display
class CategoryStyles {
  /// Get a default icon for a category based on its name
  static IconData getIconForCategory(String categoryName) {
    final lowerCaseName = categoryName.toLowerCase();
    
    if (lowerCaseName.contains('math')) return Icons.calculate;
    if (lowerCaseName.contains('science')) return Icons.science;
    if (lowerCaseName.contains('physics')) return Icons.bolt;
    if (lowerCaseName.contains('chemistry')) return Icons.biotech;
    if (lowerCaseName.contains('biology')) return Icons.spa;
    if (lowerCaseName.contains('history')) return Icons.history_edu;
    if (lowerCaseName.contains('language')) return Icons.translate;
    if (lowerCaseName.contains('english')) return Icons.menu_book;
    if (lowerCaseName.contains('computer') || lowerCaseName.contains('programming')) return Icons.code;
    if (lowerCaseName.contains('economics')) return Icons.attach_money;
    if (lowerCaseName.contains('art')) return Icons.palette;
    if (lowerCaseName.contains('music')) return Icons.music_note;
    if (lowerCaseName.contains('test') || lowerCaseName.contains('exam')) return Icons.assignment;
    if (lowerCaseName.contains('general')) return Icons.lightbulb;
    
    // Default icon for other categories
    return Icons.school;
  }

  /// Get a default background color for a category based on its name
  static Color getColorForCategory(String categoryName) {
    final lowerCaseName = categoryName.toLowerCase();
    
    if (lowerCaseName.contains('math')) return Colors.orange;
    if (lowerCaseName.contains('science')) return Colors.green;
    if (lowerCaseName.contains('physics')) return Colors.blue;
    if (lowerCaseName.contains('chemistry')) return Colors.deepPurple;
    if (lowerCaseName.contains('biology')) return Colors.lightGreen;
    if (lowerCaseName.contains('history')) return Colors.brown;
    if (lowerCaseName.contains('language')) return Colors.indigo;
    if (lowerCaseName.contains('english')) return Colors.teal;
    if (lowerCaseName.contains('computer') || lowerCaseName.contains('programming')) return Colors.red;
    if (lowerCaseName.contains('economics')) return Colors.green.shade600;
    if (lowerCaseName.contains('art')) return Colors.purple;
    if (lowerCaseName.contains('music')) return Colors.pink;
    if (lowerCaseName.contains('test') || lowerCaseName.contains('exam')) return Colors.amber;
    if (lowerCaseName.contains('general')) return Colors.blueGrey;
    
    // Generate a color based on the first character of the category name
    // This ensures the same category always gets the same color
    final colors = [
      Colors.blue, 
      Colors.red, 
      Colors.green, 
      Colors.orange, 
      Colors.purple, 
      Colors.teal, 
      Colors.pink, 
      Colors.indigo
    ];
    
    final charCode = categoryName.isNotEmpty ? categoryName.codeUnitAt(0) : 0;
    return colors[charCode % colors.length];
  }
  
  /// Build a category icon widget with consistent styling
  static Widget buildCategoryIcon(String categoryName, {double size = 50.0}) {
    final color = getColorForCategory(categoryName);
    final icon = getIconForCategory(categoryName);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
} 