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
            // Header with title and description
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[850] 
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                gradient: Theme.of(context).brightness == Brightness.dark 
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue[50]!,
                          Colors.blue[100]!.withOpacity(0.5),
                        ],
                      ),
                boxShadow: Theme.of(context).brightness == Brightness.dark 
                    ? null 
                    : [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
            
            // Status card (only show if in progress or completed)
            if (pack.isStarted || pack.isCompleted) ...[
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? null 
                    : Colors.white,
                shadowColor: Theme.of(context).brightness == Brightness.dark 
                    ? null 
                    : Colors.blue.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          backgroundColor: Theme.of(context).brightness == Brightness.dark 
                              ? null 
                              : Colors.blue.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).brightness == Brightness.dark 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.blue,
                          ),
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
            ],
            
            // Action button
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
                  } else if (pack.lastQuestionIndex > 0) {
                    // For in-progress tests, show a continue/restart dialog
                    _showContinueRestartDialog(context, dataService, pack);
                  } else {
                    // Start new test
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QuestionScreen(
                          packId: pack.id,
                          startFromBeginning: true,
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(
                  pack.isCompleted
                      ? Icons.refresh
                      : Icons.play_arrow
                ),
                label: Text(
                  pack.isCompleted
                      ? 'Restart Test'
                      : 'Start Test',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? null 
                      : Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: Theme.of(context).brightness == Brightness.dark 
                      ? null 
                      : Colors.blue.withOpacity(0.4),
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

  void _showContinueRestartDialog(
    BuildContext context,
    FirebaseDataService dataService,
    TestSet pack
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Continue or Restart Test'),
        content: Text('Do you want to continue from where you left off or restart the test?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
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
            },
            child: const Text('Restart'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QuestionScreen(
                    packId: pack.id,
                    startFromBeginning: false,
                  ),
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
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
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[850] 
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        gradient: isLightMode ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.blue.shade50,
          ],
          stops: const [0.6, 1.0],
        ) : null,
        boxShadow: isLightMode ? [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
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