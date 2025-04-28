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

class BookmarkedQuestionsTab extends StatefulWidget {
  const BookmarkedQuestionsTab({super.key});

  @override
  State<BookmarkedQuestionsTab> createState() => _BookmarkedQuestionsTabState();
}

class _BookmarkedQuestionsTabState extends State<BookmarkedQuestionsTab> {
  Set<String> expandedQuestionIds = {};

  void _toggleExpanded(String questionId) {
    setState(() {
      if (expandedQuestionIds.contains(questionId)) {
        expandedQuestionIds.remove(questionId);
      } else {
        expandedQuestionIds.add(questionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context);
    final bookmarkedQuestions = dataService.bookmarkedQuestions;
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    
    return bookmarkedQuestions.isEmpty
        ? const Center(
            child: Text('No bookmarked questions yet'),
          )
        : ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: bookmarkedQuestions.length,
            itemBuilder: (context, index) {
              final question = bookmarkedQuestions[index];
              final isExpanded = expandedQuestionIds.contains(question.id);
              
              // Find the pack this question belongs to
              String? packId;
              String packName = "Unknown test";
              for (final pack in dataService.allTestSets) {
                for (final q in pack.questions) {
                  if (q.id == question.id) {
                    packId = pack.id;
                    packName = pack.name;
                    break;
                  }
                }
                if (packId != null) break;
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Main card content
                      InkWell(
                        onTap: () => _toggleExpanded(question.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question information
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      question.text,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    // Pack info
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.folder_outlined,
                                          size: 14,
                                          color: isLightMode ? Colors.black54 : Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            packName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isLightMode ? Colors.black54 : Colors.white70,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Right side icons
                              Column(
                                children: [
                                  // Bookmark icon
                                  if (packId != null)
                                    IconButton(
                                      icon: const Icon(Icons.bookmark, color: Colors.blue, size: 20),
                                      onPressed: () {
                                        _showUnbookmarkConfirmation(
                                          context, 
                                          'Remove Bookmark', 
                                          'Are you sure you want to remove this question from your bookmarks?',
                                          () => dataService.toggleQuestionBookmark(packId!, question.id)
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  
                                  // Status indicator - find the original question
                                  Builder(
                                    builder: (context) {
                                      Question? originalQuestion;
                                      if (packId != null) {
                                        final pack = dataService.getPackById(packId!);
                                        if (pack != null) {
                                          for (final q in pack.questions) {
                                            if (q.id == question.id) {
                                              originalQuestion = q;
                                              break;
                                            }
                                          }
                                        }
                                      }
                                      
                                      if (originalQuestion != null && originalQuestion.isAnswered) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                          child: Icon(
                                            originalQuestion.isCorrect ? Icons.check_circle : Icons.cancel,
                                            color: originalQuestion.isCorrect 
                                                ? Colors.green 
                                                : Colors.red,
                                            size: 16,
                                          ),
                                        );
                                      }
                                      
                                      return const SizedBox(height: 24); // Empty space to maintain layout
                                    }
                                  ),
                                  
                                  // Expand/collapse icon
                                  Icon(
                                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    color: Colors.grey[600],
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Expanded options section
                      if (isExpanded)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isLightMode 
                                ? Colors.grey.shade50 
                                : Colors.grey.shade800,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Builder(
                            builder: (context) {
                              // Find the original question data that includes answers
                              Question? originalQuestion;
                              if (packId != null) {
                                final pack = dataService.getPackById(packId);
                                if (pack != null) {
                                  for (final q in pack.questions) {
                                    if (q.id == question.id) {
                                      originalQuestion = q;
                                      break;
                                    }
                                  }
                                }
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    ...List.generate(
                                      question.options.length,
                                      (i) {
                                        final bool isCorrect = i == question.correctOptionIndex;
                                        final bool isSelected = originalQuestion?.isAnswered == true && 
                                            originalQuestion?.selectedOptionIndex == i;
                                        final bool isWrongAnswer = isSelected && !isCorrect;
                                        
                                        Color circleColor = Colors.grey[200]!;
                                        if (isCorrect) {
                                          circleColor = Colors.green;
                                        } else if (isWrongAnswer) {
                                          circleColor = Colors.red;
                                        }
                                        
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: circleColor,
                                                  shape: BoxShape.circle,
                                                  border: isWrongAnswer
                                                      ? Border.all(color: Colors.red, width: 2)
                                                      : null,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    String.fromCharCode(65 + i),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: (isCorrect || isWrongAnswer) ? Colors.white : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              
                                              // Option text with indicator icons
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        question.options[i].toString(),
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                                                        ),
                                                      ),
                                                    ),
                                                    if (originalQuestion?.isAnswered == true) ...[
                                                      if (isCorrect)
                                                        const Icon(
                                                          Icons.check_circle,
                                                          color: Colors.green,
                                                          size: 18,
                                                        ),
                                                      if (isWrongAnswer)
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.cancel,
                                                              color: Colors.red,
                                                              size: 18,
                                                            ),
                                                            const SizedBox(width: 4),
                                                            const Text(
                                                              "Your answer",
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.red,
                                                                fontStyle: FontStyle.italic,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
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