import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/data_service.dart';

class PackCard extends StatelessWidget {
  final QuestionPack pack;
  final VoidCallback onTap;
  
  const PackCard({
    super.key,
    required this.pack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pack.title,
                      style: const TextStyle(
                        fontSize: 18,
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
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              Text(pack.description),
              const SizedBox(height: 8),
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
              if (pack.isCompleted)
                const Text(
                  'COMPLETED',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer, size: 16),
                  const SizedBox(width: 4),
                  Text('${pack.timeEstimate} min'),
                  const SizedBox(width: 16),
                  const Icon(Icons.question_answer, size: 16),
                  const SizedBox(width: 4),
                  Text('${pack.questions.length} questions'),
                ],
              ),
            ],
          ),
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