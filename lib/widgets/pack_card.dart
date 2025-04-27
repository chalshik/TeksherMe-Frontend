import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import '../data/theme.dart';

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
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: TeksherTheme.getShadow(isLightMode ? false : true),
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: isLightMode 
                  ? BoxDecoration(
                      color: Colors.white,
                    )
                  : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with bookmark
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            pack.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: IconButton(
                            icon: Icon(
                              pack.isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded,
                              color: pack.isBookmarked 
                                  ? Theme.of(context).colorScheme.primary
                                  : isLightMode ? Colors.black45 : Colors.white60,
                              size: 26,
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
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Difficulty chip and stats
                    Row(
                      children: [
                        // Difficulty chip with proper styling
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(context, pack.difficulty).withOpacity(isLightMode ? 0.15 : 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pack.difficulty,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _getDifficultyColor(context, pack.difficulty),
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Stats with nicer styling
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: isLightMode ? Colors.black54 : Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(pack.timeEstimate),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isLightMode ? Colors.black54 : Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.quiz_outlined,
                              size: 18,
                              color: isLightMode ? Colors.black54 : Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${pack.questions.length} Q',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isLightMode ? Colors.black54 : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Progress indicator if in progress
                    if (pack.lastQuestionIndex > 0 && !pack.isCompleted) ...[
                      const SizedBox(height: 16),
                      Stack(
                        children: [
                          // Background track
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isLightMode 
                                ? Colors.grey.withOpacity(0.15) 
                                : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          // Progress fill
                          Container(
                            height: 8,
                            width: MediaQuery.of(context).size.width * pack.progressPercentage * 0.8, // Adjust for card padding
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Progress: ${(pack.progressPercentage * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    
                    // Completed tag with nicer styling
                    if (pack.isCompleted) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: TeksherTheme.successLight.withOpacity(isLightMode ? 0.1 : 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: isLightMode ? TeksherTheme.successLight : TeksherTheme.successDark,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'COMPLETED',
                              style: TextStyle(
                                color: isLightMode ? TeksherTheme.successLight : TeksherTheme.successDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getDifficultyColor(BuildContext context, String difficulty) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final colors = isLightMode 
      ? TeksherTheme.difficultyColorsLight 
      : TeksherTheme.difficultyColorsDark;
    
    return colors[difficulty.toLowerCase()] ?? Colors.grey;
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