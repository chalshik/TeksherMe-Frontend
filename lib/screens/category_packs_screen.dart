import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import 'test_preview_screen.dart';
import '../widgets/pack_card.dart';

class CategoryPacksScreen extends StatelessWidget {
  final String category;
  
  const CategoryPacksScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context);
    final packs = dataService.getPacksByCategory(category);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          category,
          style: const TextStyle(fontSize: 22),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: packs.isEmpty
            ? const Center(
                child: Text('No packs available in this category'),
              )
            : ListView.builder(
                itemCount: packs.length,
                itemBuilder: (context, index) {
                  final pack = packs[index];
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
    );
  }
} 