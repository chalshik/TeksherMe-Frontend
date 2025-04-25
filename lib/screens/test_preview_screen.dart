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
    Color statusColor = Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey[300]! 
        : Colors.grey;
    
    if (pack.isCompleted) {
      status = 'Completed';
      statusColor = Theme.of(context).brightness == Brightness.dark 
          ? Colors.green[300]! 
          : Colors.green;
    } else if (pack.lastQuestionIndex > 0) {
      status = 'In Progress';
      statusColor = Theme.of(context).brightness == Brightness.dark 
          ? Colors.orange[300]! 
          : Colors.orange;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(pack.name),
        actions: [
          IconButton(
            icon: Icon(
              pack.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: pack.isBookmarked ? Theme.of(context).primaryColor : null,
            ),
            onPressed: () {
              if (pack.isBookmarked) {
                _showUnbookmarkConfirmation(
                  context,
                  'Remove Bookmark',
                  'Are you sure you want to remove this pack from your bookmarks?',
                  () => dataService.togglePackBookmark(pack.id)
                );
              } else {
                dataService.togglePackBookmark(pack.id);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title, difficulty
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[850] 
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Test title
                  Text(
                    pack.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    pack.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick info row
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.timer,
                    title: 'Time',
                    value: _formatTime(pack.timeEstimate),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.question_answer,
                    title: 'Questions',
                    value: pack.questions.length.toString(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.stacked_line_chart,
                    title: 'Difficulty',
                    value: pack.difficulty,
                    valueColor: _getDifficultyTextColor(context, pack.difficulty),
                  ),
                ),
              ],
            ),
            
            // Status card
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 18,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    
                    if (pack.lastQuestionIndex > 0 && !pack.isCompleted) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: pack.progressPercentage,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Progress: ${(pack.progressPercentage * 100).toInt()}% (${pack.lastQuestionIndex}/${pack.questions.length} questions)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Action buttons
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (pack.isCompleted) {
                    // Restart completed test 
                    dataService.resetTestProgress(pack.id).then((_) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => QuestionScreen(
                            packId: pack.id,
                            startFromBeginning: true,
                          ),
                        ),
                      );
                    });
                  } else {
                    // Continue or start new test
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QuestionScreen(
                          packId: pack.id,
                          startFromBeginning: pack.lastQuestionIndex == 0,
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(
                  pack.isCompleted
                      ? Icons.refresh
                      : (pack.lastQuestionIndex > 0 ? Icons.play_circle_filled : Icons.play_arrow)
                ),
                label: Text(
                  pack.isCompleted
                      ? 'Restart Test'
                      : (pack.lastQuestionIndex > 0 && !pack.isCompleted ? 'Continue Test' : 'Start Test'),
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getDifficultyColor(BuildContext context, String difficulty) {
    final brightness = Theme.of(context).brightness;
    
    if (brightness == Brightness.dark) {
      switch (difficulty.toLowerCase()) {
        case 'easy':
          return Colors.green.withOpacity(0.3);
        case 'medium':
          return Colors.orange.withOpacity(0.3);
        case 'hard':
          return Colors.red.withOpacity(0.3);
        default:
          return Colors.grey.withOpacity(0.3);
      }
    } else {
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
  
  Color _getDifficultyTextColor(BuildContext context, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'In Progress':
        return Icons.timelapse;
      default:
        return Icons.circle_outlined;
    }
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

  // Format time to show seconds if less than 1 minute
  String _formatTime(double time) {
    if (time < 1.0) {
      // For times less than 1 minute, convert to seconds
      int seconds = (time * 60).round();
      return '$seconds sec';
    } else if (time == time.roundToDouble()) {
      // For whole minute values (1.0, 2.0, etc.)
      return '${time.toInt()} min';
    } else {
      // For other decimal values (1.5, 2.3, etc.)
      return '${time.toStringAsFixed(1)} min';
    }
  }
}

// Small info card widget
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;
  
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[850] 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
} 