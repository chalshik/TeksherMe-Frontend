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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                isDarkMode
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with title and bookmark
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side badge with difficulty
                    Container(
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(context, pack.difficulty).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        pack.difficulty,
                        style: TextStyle(
                          color: _getDifficultyColor(context, pack.difficulty),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Title in the middle
                    Expanded(
                      child: Text(
                        pack.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Bookmark icon on the right
                    IconButton(
                      icon: Icon(
                        pack.isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                        color: pack.isBookmarked 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Content section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Question count icon
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.quiz_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pack.questions.length} Questions',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Estimated time: ${_formatTime(pack.timeEstimate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Progress section if in progress
              if (pack.lastQuestionIndex > 0 && !pack.isCompleted) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Progress: ${(pack.progressPercentage * 100).toInt()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pack.progressPercentage,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Completed tag
              if (pack.isCompleted)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'COMPLETED',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getDifficultyColor(BuildContext context, String difficulty) {
    final brightness = Theme.of(context).brightness;
    
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4CAF50); // Green
      case 'medium':
        return const Color(0xFFFFA726); // Orange
      case 'hard':
        return const Color(0xFFF44336); // Red
      case 'expert':
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  // Format time to show seconds if less than 1 minute
  String _formatTime(double time) {
    if (time < 1.0) {
      // For times less than 1 minute, convert to seconds
      final seconds = (time * 60).round();
      return '$seconds sec';
    } else if (time < 60) {
      // For times less than 1 hour
      final minutes = time.floor();
      final seconds = ((time - minutes) * 60).round();
      if (seconds > 0) {
        return '$minutes min $seconds sec';
      } else {
        return '$minutes min';
      }
    } else {
      // For times of 1 hour or more
      final hours = time ~/ 60;
      final minutes = (time % 60).round();
      if (minutes > 0) {
        return '$hours hr $minutes min';
      } else {
        return '$hours hr';
      }
    }
  }
} 