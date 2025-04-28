import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import 'test_preview_screen.dart';
import '../widgets/compact_pack_card.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              const Text(
                'Bookmarks',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const TabBar(
                tabs: [
                  Tab(text: 'Packs'),
                  Tab(text: 'Questions'),
                ],
              ),
              const SizedBox(height: 8),
              const Expanded(
                child: TabBarView(
                  children: [
                    BookmarkedPacksTab(),
                    BookmarkedQuestionsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookmarkedPacksTab extends StatelessWidget {
  const BookmarkedPacksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context);
    final bookmarkedPacks = dataService.bookmarkedPacks;
    
    return bookmarkedPacks.isEmpty
        ? const Center(
            child: Text('No bookmarked packs yet'),
          )
        : ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: bookmarkedPacks.length,
            itemBuilder: (context, index) {
              final pack = bookmarkedPacks[index];
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
                onBookmarkTap: () {
                  _showUnbookmarkConfirmation(
                    context, 
                    'Remove Bookmark', 
                    'Are you sure you want to remove this pack from your bookmarks?',
                    () => dataService.togglePackBookmark(pack.id)
                  );
                },
              );
            },
          );
  }
  
  void _showUnbookmarkConfirmation(
    BuildContext context, 
    String title, 
    String message, 
    VoidCallback onConfirm
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class BookmarkedQuestionsTab extends StatelessWidget {
  const BookmarkedQuestionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context);
    final bookmarkedQuestions = dataService.bookmarkedQuestions;
    
    return bookmarkedQuestions.isEmpty
        ? const Center(
            child: Text('No bookmarked questions yet'),
          )
        : ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: bookmarkedQuestions.length,
            itemBuilder: (context, index) {
              final question = bookmarkedQuestions[index];
              
              // Find the pack this question belongs to
              String? packId;
              for (final pack in dataService.allTestSets) {
                for (final q in pack.questions) {
                  if (q.id == question.id) {
                    packId = pack.id;
                    break;
                  }
                }
                if (packId != null) break;
              }
              
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question text with bookmark button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              question.text,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (packId != null)
                            IconButton(
                              icon: const Icon(Icons.bookmark, color: Colors.blue, size: 24),
                              onPressed: () {
                                _showUnbookmarkConfirmation(
                                  context, 
                                  'Remove Bookmark', 
                                  'Are you sure you want to remove this question from your bookmarks?',
                                  () => dataService.toggleQuestionBookmark(packId!, question.id)
                                );
                              },
                              tooltip: 'Remove bookmark',
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(
                        question.options.length,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: question.isAnswered
                                      ? (i == question.correctOptionIndex
                                          ? Colors.green
                                          : (i == question.selectedOptionIndex
                                              ? Colors.red
                                              : Colors.grey[200]))
                                      : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + i),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: question.isAnswered &&
                                              (i == question.correctOptionIndex ||
                                                  i == question.selectedOptionIndex)
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  question.options[i].toString(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
  
  void _showUnbookmarkConfirmation(
    BuildContext context, 
    String title, 
    String message, 
    VoidCallback onConfirm
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
} 