import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';

class PackCard extends StatelessWidget {
  final QuestionPack pack;
  final VoidCallback onTap;
  final VoidCallback? onBookmarkTap;
  
  const PackCard({
    super.key,
    required this.pack,
    required this.onTap,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with bookmark
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pack.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Description directly under title
                        Text(
                          pack.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      pack.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: pack.isBookmarked ? Theme.of(context).primaryColor : null,
                    ),
                    onPressed: () {
                      if (pack.isBookmarked && onBookmarkTap != null) {
                        // Use the provided callback for unbookmarking with confirmation
                        onBookmarkTap!();
                      } else {
                        // Just bookmark directly without confirmation
                        dataService.togglePackBookmark(pack.id);
                      }
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Difficulty chip and progress indicator
              Row(
                children: [
                  Chip(
                    label: Text(pack.difficulty),
                    backgroundColor: _getDifficultyColor(context, pack.difficulty),
                    visualDensity: VisualDensity.compact,
                  ),
                  
                  const Spacer(),
                  
                  // Stats: time and questions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, size: 16),
                      const SizedBox(width: 4),
                      Text(_formatTime(pack.timeEstimate)),
                      const SizedBox(width: 12),
                      const Icon(Icons.question_answer, size: 16),
                      const SizedBox(width: 4),
                      Text('${pack.questions.length} Q'),
                    ],
                  ),
                ],
              ),
              
              // Progress indicator if in progress
              if (pack.lastQuestionIndex > 0 && !pack.isCompleted) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: pack.progressPercentage,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 4),
                Text(
                  'Progress: ${(pack.progressPercentage * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              
              // Completed tag
              if (pack.isCompleted) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.green[300] 
                          : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'COMPLETED',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.green[300] 
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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