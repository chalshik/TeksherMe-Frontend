import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import '../data/theme.dart';

class CompactPackCard extends StatelessWidget {
  final QuestionPack pack;
  final VoidCallback onTap;
  final VoidCallback? onBookmarkTap;
  
  const CompactPackCard({
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
      margin: const EdgeInsets.only(bottom: 12),
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
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Main content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            pack.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          
                          // Info row
                          Row(
                            children: [
                              // Difficulty chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(context, pack.difficulty).withOpacity(isLightMode ? 0.15 : 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  pack.difficulty,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _getDifficultyColor(context, pack.difficulty),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // Time
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: isLightMode ? Colors.black54 : Colors.white70,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _formatTime(pack.timeEstimate),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isLightMode ? Colors.black54 : Colors.white70,
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Questions count
                              Icon(
                                Icons.quiz_outlined,
                                size: 14,
                                color: isLightMode ? Colors.black54 : Colors.white70,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${pack.questions.length} Q',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isLightMode ? Colors.black54 : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Status indicator
                    _buildStatusIndicator(context),
                    
                    // Bookmark button
                    IconButton(
                      icon: Icon(
                        pack.isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded,
                        color: pack.isBookmarked 
                            ? Theme.of(context).colorScheme.primary
                            : isLightMode ? Colors.black45 : Colors.white60,
                        size: 22,
                      ),
                      onPressed: () {
                        if (pack.isBookmarked && onBookmarkTap != null) {
                          onBookmarkTap!();
                        } else {
                          dataService.togglePackBookmark(pack.id);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper to build a status indicator for the pack
  Widget _buildStatusIndicator(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    
    if (pack.isCompleted) {
      // Completed indicator
      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: Icon(
          Icons.check_circle,
          color: isLightMode ? TeksherTheme.successLight : TeksherTheme.successDark,
          size: 20,
        ),
      );
    } else if (pack.lastQuestionIndex > 0) {
      // In progress indicator
      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: pack.progressPercentage,
                strokeWidth: 2,
                backgroundColor: isLightMode ? Colors.grey.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Text(
              '${(pack.progressPercentage * 100).toInt()}',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    // No indicator for new packs
    return const SizedBox(width: 8);
  }
  
  Color _getDifficultyColor(BuildContext context, String difficulty) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final colors = isLightMode 
      ? TeksherTheme.difficultyColorsLight 
      : TeksherTheme.difficultyColorsDark;
    
    return colors[difficulty.toLowerCase()] ?? Colors.grey;
  }

  String _formatTime(double time) {
    if (time < 1.0) {
      int seconds = (time * 60).round();
      return '$seconds sec';
    } else if (time == time.roundToDouble()) {
      return '${time.toInt()} min';
    } else {
      return '${time.toStringAsFixed(1)} min';
    }
  }
} 