import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import 'test_preview_screen.dart';
import '../widgets/pack_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context);
    final inProgressPacks = dataService.inProgressPacks;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeksherMe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to TeksherMe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Continue Where You Left Off',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: inProgressPacks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No packs in progress'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to Explore screen
                              // Find the parent HomePage to change index
                              final tabController = DefaultTabController.maybeOf(context);
                              if (tabController != null) {
                                tabController.animateTo(1); // Explore is at index 1
                              }
                            },
                            child: const Text('Explore Packs'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: inProgressPacks.length,
                      itemBuilder: (context, index) {
                        final pack = inProgressPacks[index];
                        return PackCard(
                          pack: pack,
                          onTap: () => _showContinueOptions(context, pack),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showContinueOptions(BuildContext context, QuestionPack pack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pack.name),
        content: const Text('Would you like to continue where you left off or restart?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TestPreviewScreen(
                    packId: pack.id,
                  ),
                ),
              );
            },
            child: const Text('Preview'),
          ),
        ],
      ),
    );
  }
} 