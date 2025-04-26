import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import 'category_packs_screen.dart';
import 'test_preview_screen.dart';
import '../widgets/pack_card.dart';
import 'package:flutter/rendering.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add padding to account for status bar
            SizedBox(height: MediaQuery.of(context).padding.top),
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
    return ListView.separated(
      itemCount: categories.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            _showPacksByCategory(context, categories[index]);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  categories[index],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
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