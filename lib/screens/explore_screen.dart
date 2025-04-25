import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/data_service.dart';
import 'category_packs_screen.dart';
import 'question_screen.dart';
import '../widgets/pack_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _searchQuery = '';
  List<QuestionPack> _searchResults = [];
  
  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final allPacks = dataService.allQuestionPacks;
    
    // Get unique categories
    final categories = allPacks
        .map((pack) => pack.category)
        .toSet()
        .toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search packs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  if (value.isEmpty) {
                    _searchResults = [];
                  } else {
                    _searchResults = allPacks
                        .where((pack) => 
                            pack.title.toLowerCase().contains(value.toLowerCase()) ||
                            pack.description.toLowerCase().contains(value.toLowerCase()) ||
                            pack.category.toLowerCase().contains(value.toLowerCase()))
                        .toList();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Categories - Now displayed vertically with full width
            Expanded(
              child: _searchQuery.isNotEmpty 
                ? _buildSearchResults()
                : _buildCategoriesAndInstructions(categories),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _searchResults.isEmpty
              ? const Center(
                  child: Text('No matching packs found'),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final pack = _searchResults[index];
                    return PackCard(
                      pack: pack,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => QuestionScreen(
                              packId: pack.id, 
                              startFromBeginning: pack.lastQuestionIndex == 0,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildCategoriesAndInstructions(List<String> categories) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories available'));
    }
    
    return Column(
      children: [
        // Categories in vertical list with full width cards
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              // Different colors for different categories based on theme
              final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
              
              final List<Color> lightThemeColors = [
                Colors.blue.shade100,
                Colors.green.shade100,
                Colors.orange.shade100,
                Colors.purple.shade100,
                Colors.red.shade100,
                Colors.teal.shade100,
              ];
              
              final List<Color> darkThemeColors = [
                Colors.blue.shade900,
                Colors.green.shade900,
                Colors.orange.shade900,
                Colors.purple.shade900,
                Colors.red.shade900,
                Colors.teal.shade900,
              ];
              
              // Use modulo to cycle through colors
              final cardColors = isDarkTheme ? darkThemeColors : lightThemeColors;
              final cardColor = cardColors[index % cardColors.length];
              
              // Text color based on theme
              final textColor = isDarkTheme ? Colors.white : Colors.black;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                elevation: 2,
                color: cardColor,
                child: InkWell(
                  onTap: () => _showPacksByCategory(context, categories[index]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            categories[index],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 18, color: textColor),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      
      ],
    );
  }
  
  void _showPacksByCategory(BuildContext context, String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryPacksScreen(category: category),
      ),
    );
  }
} 