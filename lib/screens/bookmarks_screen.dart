import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import 'question_screen.dart';
import '../widgets/pack_card.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookmarks'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Packs'),
              Tab(text: 'Questions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BookmarkedPacksTab(),
            BookmarkedQuestionsTab(),
          ],
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
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: bookmarkedPacks.isEmpty
          ? const Center(
              child: Text('No bookmarked packs yet'),
            )
          : ListView.builder(
              itemCount: bookmarkedPacks.length,
              itemBuilder: (context, index) {
                final pack = bookmarkedPacks[index];
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
    );
  }
}

class BookmarkedQuestionsTab extends StatelessWidget {
  const BookmarkedQuestionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context);
    final bookmarkedQuestions = dataService.bookmarkedQuestions;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: bookmarkedQuestions.isEmpty
          ? const Center(
              child: Text('No bookmarked questions yet'),
            )
          : ListView.builder(
              itemCount: bookmarkedQuestions.length,
              itemBuilder: (context, index) {
                final question = bookmarkedQuestions[index];
                final packId = dataService.getPackIdForQuestion(question.id);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                question.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.bookmark, color: Colors.amber),
                              onPressed: () {
                                _showUnbookmarkConfirmation(context, dataService, packId, question.id);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(
                          question.options.length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: question.isAnswered
                                        ? (i == question.correctOptionIndex
                                            ? Colors.green
                                            : (i == question.selectedOptionIndex
                                                ? Colors.red
                                                : Theme.of(context).brightness == Brightness.dark 
                                                  ? Colors.grey[800] 
                                                  : Colors.grey[200]))
                                        : Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.grey[800] 
                                          : Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + i),
                                      style: TextStyle(
                                        color: question.isAnswered &&
                                                (i == question.correctOptionIndex ||
                                                    i == question.selectedOptionIndex)
                                            ? Colors.white
                                            : Theme.of(context).brightness == Brightness.dark 
                                              ? Colors.white 
                                              : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(question.options[i])),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
  
  void _showUnbookmarkConfirmation(BuildContext context, DataService dataService, String packId, String questionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Bookmark'),
        content: const Text('Are you sure you want to remove this question from your bookmarks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              dataService.toggleQuestionBookmark(packId, questionId);
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
} 