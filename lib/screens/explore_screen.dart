import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import 'category_packs_screen.dart';
import 'test_preview_screen.dart';
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
    final dataService = Provider.of<FirebaseDataService>(context);
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
                            pack.name.toLowerCase().contains(value.toLowerCase()) ||
                            pack.description.toLowerCase().contains(value.toLowerCase()) ||
                            pack.category.toLowerCase().contains(value.toLowerCase()))
                        .toList();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Conditional content based on search query
            Expanded(
              child: _searchQuery.isEmpty 
                ? _buildCategoriesList(categories, context)
                : _buildSearchResults(context),
            ),
          ],
        ),
      ),
    );
  }
  
  // Categories list builder
  Widget _buildCategoriesList(List<String> categories, BuildContext context) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            width: double.infinity,
            height: 80, // Increased height for more rectangular shape
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _showPacksByCategory(context, categories[index]);
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  categories[index],
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Search results builder
  Widget _buildSearchResults(BuildContext context) {
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
                            builder: (context) => TestPreviewScreen(
                              packId: pack.id, 
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
  
  void _showPacksByCategory(BuildContext context, String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryPacksScreen(category: category),
      ),
    );
  }
} 