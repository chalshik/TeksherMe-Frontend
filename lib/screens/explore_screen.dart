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
            
            // Categories
            Text(
              'Categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                    child: ActionChip(
                      label: Text(categories[index]),
                      onPressed: () {
                        // Show packs in this category
                        _showPacksByCategory(context, categories[index]);
                      },
                    ),
                  );
                },
              ),
            ),
            
            // Show search results if there's a search query
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
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
            ] else ...[
              // Show instructions when no search or category is selected
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Search for packs or select a category',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Discover question packs by using the search bar\nor tapping on a category above',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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