import 'package:flutter/material.dart';
import '../data/data_service.dart';
import 'question_screen.dart';
import 'package:provider/provider.dart';

class ResultsAnalysisScreen extends StatelessWidget {
  final QuestionPack pack;

  const ResultsAnalysisScreen({
    super.key,
    required this.pack,
  });

  @override
  Widget build(BuildContext context) {
    final correctAnswers = pack.questions.where((q) => q.isAnswered && q.isCorrect).length;
    final totalQuestions = pack.questions.length;
    final percentage = (correctAnswers / totalQuestions * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        actions: [
          TextButton.icon(
            onPressed: () {
              final dataService = Provider.of<DataService>(context, listen: false);
              dataService.resetPackAnswers(pack.id);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => QuestionScreen(
                    packId: pack.id,
                    startFromBeginning: true,
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
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: percentage >= 70 ? Colors.green.shade100 : 
                           percentage >= 40 ? Colors.orange.shade100 : Colors.red.shade100,
                    border: Border.all(
                      color: percentage >= 70 ? Colors.green : 
                             percentage >= 40 ? Colors.orange : Colors.red,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pack.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildResultStat(
                            label: 'Correct',
                            value: correctAnswers,
                            color: Colors.green,
                          ),
                          _buildResultStat(
                            label: 'Wrong',
                            value: totalQuestions - correctAnswers,
                            color: Colors.red,
                          ),
                          _buildResultStat(
                            label: 'Total',
                            value: totalQuestions,
                            color: Colors.blue,
                          ),
                        ],
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
              itemCount: pack.questions.length,
              itemBuilder: (context, index) {
                final question = pack.questions[index];
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
                            if (question.isBookmarked)
                              const Icon(Icons.bookmark, color: Colors.amber),
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
                                bgColor = Colors.green.shade50;
                              } else if (isSelected) {
                                bgColor = Colors.red.shade50;
                              }
                            }
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border.all(
                                  color: isCorrect ? Colors.green : 
                                         (isSelected ? Colors.red : Colors.grey.shade300),
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
                                      color: isCorrect ? Colors.green : 
                                             (isSelected ? Colors.red : Colors.grey.shade200),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + i),
                                        style: TextStyle(
                                          color: isCorrect || isSelected ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      question.options[i],
                                      style: TextStyle(
                                        fontWeight: isCorrect || isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isCorrect)
                                    const Icon(Icons.check_circle, color: Colors.green)
                                  else if (isSelected && !isCorrect)
                                    const Icon(Icons.cancel, color: Colors.red)
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
                                color: selectedIndex == correctIndex ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedIndex == correctIndex ? 'Correct Answer' : 'Wrong Answer',
                                style: TextStyle(
                                  color: selectedIndex == correctIndex ? Colors.green : Colors.red,
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
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
} 