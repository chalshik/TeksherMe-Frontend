import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import '../data/category_styles.dart';
import 'test_preview_screen.dart';
import '../widgets/compact_pack_card.dart';

class CategoryPacksScreen extends StatelessWidget {
  final String category;
  
  const CategoryPacksScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context);
    final packs = dataService.getPacksByCategory(category);
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                // Category icon
                CategoryStyles.buildCategoryIcon(category, size: 42),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: packs.isEmpty
                  ? const Center(
                      child: Text('No packs available in this category'),
                    )
                  : ListView.builder(
                      itemCount: packs.length,
                      itemBuilder: (context, index) {
                        final pack = packs[index];
                        return CompactPackCard(
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
        ),
      ),
    );
  }
} 