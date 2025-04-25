import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/data_service.dart';
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
    final dataService = Provider.of<DataService>(context);
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
    final dataService = Provider.of<DataService>(context);
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                                                : Colors.grey[200]))
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
} 