import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import 'test_preview_screen.dart';
import 'explore_screen.dart';
import 'home_page.dart';

class ResultsAnalysisScreen extends StatefulWidget {
  final QuestionPack pack;
  final VoidCallback? onFinish;

  const ResultsAnalysisScreen({
    super.key,
    required this.pack,
    this.onFinish,
  });

  @override
  State<ResultsAnalysisScreen> createState() => _ResultsAnalysisScreenState();
}

class _ResultsAnalysisScreenState extends State<ResultsAnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    final correctAnswers = widget.pack.questions.where((q) => q.isAnswered && q.isCorrect).length;
    final totalQuestions = widget.pack.questions.length;
    final percentage = (correctAnswers / totalQuestions * 100).toInt();
    final dataService = Provider.of<FirebaseDataService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onFinish != null) {
              widget.onFinish!();
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const HomePage(initialIndex: 1),
                ),
                (route) => false,
              );
            }
          },
        ),
        actions: [
          // Add bookmark toggle for the entire pack
          IconButton(
            icon: Icon(
              widget.pack.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: widget.pack.isBookmarked ? Colors.amber : null,
            ),
            onPressed: () async {
              await dataService.togglePackBookmark(widget.pack.id);
              setState(() {}); // Refresh UI
            },
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => TestPreviewScreen(
                    packId: widget.pack.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.replay),
            label: const Text('Pass Again'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Results summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).primaryColor.withOpacity(0.15)
                : Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? (percentage >= 70 
                          ? Colors.green.withOpacity(0.2) 
                          : percentage >= 40 
                              ? Colors.orange.withOpacity(0.2) 
                              : Colors.red.withOpacity(0.2))
                      : (percentage >= 70 
                          ? Colors.green.shade100 
                          : percentage >= 40 
                              ? Colors.orange.shade100 
                              : Colors.red.shade100),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                        ? (percentage >= 70 
                            ? Colors.green[300]! 
                            : percentage >= 40 
                                ? Colors.orange[300]! 
                                : Colors.red[300]!)
                        : (percentage >= 70 
                            ? Colors.green 
                            : percentage >= 40 
                                ? Colors.orange 
                                : Colors.red),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$correctAnswers/$totalQuestions',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildResultStat(
                        context: context,
                        label: 'Correct',
                        value: correctAnswers,
                        color: Colors.green,
                      ),
                      _buildResultStat(
                        context: context,
                        label: 'Wrong',
                        value: widget.pack.questions.where((q) => q.isAnswered && !q.isCorrect).length,
                        color: Colors.red,
                      ),
                      _buildResultStat(
                        context: context,
                        label: 'Not Answered',
                        value: widget.pack.questions.where((q) => !q.isAnswered).length,
                        color: Colors.grey,
                      ),
                      _buildResultStat(
                        context: context,
                        label: 'Total',
                        value: totalQuestions,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Question list
          Expanded(
            child: ListView.builder(
              itemCount: widget.pack.questions.length,
              itemBuilder: (context, index) {
                final question = widget.pack.questions[index];
                final isAnswered = question.isAnswered;
                final selectedIndex = question.selectedOptionIndex;
                final correctIndex = question.correctOptionIndex;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question number and bookmark indicator
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Q${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Bookmark toggle for this question
                            IconButton(
                              icon: Icon(
                                question.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                color: question.isBookmarked ? Colors.amber : null,
                              ),
                              onPressed: () async {
                                await dataService.toggleQuestionBookmark(widget.pack.id, question.id);
                                setState(() {}); // Refresh UI
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Question text
                        Text(
                          question.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Options
                        ...List.generate(
                          question.options.length,
                          (i) {
                            final isSelected = isAnswered && selectedIndex == i;
                            final isCorrect = correctIndex == i;
                            
                            Color? bgColor;
                            if (isAnswered) {
                              if (isCorrect) {
                                bgColor = Theme.of(context).brightness == Brightness.dark
                                    ? Colors.green.withOpacity(0.15)
                                    : Colors.green.shade50;
                              } else if (isSelected) {
                                bgColor = Theme.of(context).brightness == Brightness.dark
                                    ? Colors.red.withOpacity(0.15)
                                    : Colors.red.shade50;
                              }
                            }
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border.all(
                                  color: isCorrect 
                                      ? Theme.of(context).brightness == Brightness.dark
                                          ? Colors.green[300]!
                                          : Colors.green
                                      : isSelected
                                          ? Theme.of(context).brightness == Brightness.dark
                                              ? Colors.red[300]!
                                              : Colors.red
                                          : Theme.of(context).brightness == Brightness.dark
                                              ? Colors.grey[700]!
                                              : Colors.grey.shade300,
                                  width: isCorrect || isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCorrect 
                                          ? Theme.of(context).brightness == Brightness.dark
                                              ? Colors.green[600]
                                              : Colors.green
                                          : isSelected 
                                              ? Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.red[600]
                                                  : Colors.red
                                              : Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.grey[700]
                                                  : Colors.grey.shade200,
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + i),
                                        style: TextStyle(
                                          color: (isCorrect || isSelected) 
                                              ? Colors.white 
                                              : Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      question.options[i].toString(),
                                      style: TextStyle(
                                        fontWeight: isCorrect || isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isCorrect)
                                    Icon(Icons.check_circle, 
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.green[300]
                                          : Colors.green)
                                  else if (isSelected && !isCorrect)
                                    Icon(Icons.cancel, 
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.red[300]
                                          : Colors.red)
                                ],
                              ),
                            );
                          },
                        ),
                        
                        // Result indicator
                        if (isAnswered) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                selectedIndex == correctIndex ? Icons.check_circle : Icons.cancel,
                                color: selectedIndex == correctIndex ? 
                                    (Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.green) : 
                                    (Theme.of(context).brightness == Brightness.dark ? Colors.red[300] : Colors.red),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedIndex == correctIndex ? 'Correct Answer' : 'Wrong Answer',
                                style: TextStyle(
                                  color: selectedIndex == correctIndex ? 
                                      (Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.green) : 
                                      (Theme.of(context).brightness == Brightness.dark ? Colors.red[300] : Colors.red),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.help_outline,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Not Answered',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultStat({
    required BuildContext context,
    required String label,
    required int value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color displayColor = isDark ? color.withOpacity(0.85) : color;
    
    if (isDark) {
      if (color == Colors.green) displayColor = Colors.green[300]!;
      if (color == Colors.red) displayColor = Colors.red[300]!;
      if (color == Colors.blue) displayColor = Colors.blue[300]!;
      if (color == Colors.grey) displayColor = Colors.grey[300]!;
    }
    
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: displayColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
} 