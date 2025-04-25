import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import 'question_screen.dart';

class TestPreviewScreen extends StatelessWidget {
  final String packId;
  
  const TestPreviewScreen({
    super.key,
    required this.packId,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context);
    final pack = dataService.getPackById(packId);
    
    if (pack == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Question pack not found')),
      );
    }
    
    // Determine test status
    String status = 'Not Started';
    Color statusColor = Colors.grey;
    
    if (pack.isCompleted) {
      status = 'Completed';
      statusColor = Colors.green;
    } else if (pack.lastQuestionIndex > 0) {
      status = 'In Progress';
      statusColor = Colors.orange;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Preview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test title and bookmark
            Row(
              children: [
                Expanded(
                  child: Text(
                    pack.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    pack.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  onPressed: () {
                    dataService.togglePackBookmark(pack.id);
                  },
                ),
              ],
            ),
            
            // Category and difficulty chips
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  label: Text(pack.difficulty),
                  backgroundColor: _getDifficultyColor(pack.difficulty),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(pack.category),
                ),
              ],
            ),
            
            // Description
            const SizedBox(height: 16),
            Text(
              pack.description,
              style: const TextStyle(fontSize: 16),
            ),
            
            // Status
            const SizedBox(height: 24),
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    
                    if (pack.lastQuestionIndex > 0 && !pack.isCompleted) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: pack.progressPercentage,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Progress: ${(pack.progressPercentage * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Test details card
            const SizedBox(height: 16),
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Time Estimate: ${pack.timeEstimate} minutes',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.question_answer, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Questions: ${pack.questions.length}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Start button
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => QuestionScreen(
                        packId: pack.id,
                        startFromBeginning: pack.lastQuestionIndex == 0,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  pack.lastQuestionIndex > 0 && !pack.isCompleted
                      ? 'Continue Test'
                      : 'Start Test',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            
            // If test is in progress, add option to restart
            if (pack.lastQuestionIndex > 0) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Restart Test?'),
                        content: const Text(
                          'This will reset your progress on this test. Are you sure?'
                        ),
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
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => QuestionScreen(
                                    packId: pack.id,
                                    startFromBeginning: true,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Restart'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart Test'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green[100]!;
      case 'medium':
        return Colors.orange[100]!;
      case 'hard':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
} 