import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import 'results_analysis_screen.dart';

class QuestionScreen extends StatefulWidget {
  final String packId;
  final bool startFromBeginning;
  
  const QuestionScreen({
    super.key,
    required this.packId,
    required this.startFromBeginning,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  late QuestionPack pack;
  late int currentIndex;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initPack();
  }
  
  Future<void> _initPack() async {
    final dataService = Provider.of<FirebaseDataService>(context, listen: false);
    pack = dataService.getPackById(widget.packId)!;
    
    if (widget.startFromBeginning) {
      currentIndex = 0;
      await dataService.startPack(widget.packId);
    } else {
      currentIndex = pack.lastQuestionIndex;
      await dataService.continuePack(widget.packId);
    }
    
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> _answerQuestion(int optionIndex) async {
    final dataService = Provider.of<FirebaseDataService>(context, listen: false);
    final question = pack.questions[currentIndex];
    
    await dataService.answerQuestion(pack.id, question.id, optionIndex);
    
    // Wait a moment to show the result before moving to next question
    Future.delayed(const Duration(seconds: 1), () async {
      if (mounted) {
        if (currentIndex < pack.questions.length - 1) {
          setState(() {
            currentIndex++;
          });
          await dataService.updatePackProgress(pack.id, currentIndex);
        } else {
          // End of pack
          await dataService.updatePackProgress(pack.id, pack.questions.length);
          if (mounted) {
            _showCompletionDialog();
          }
        }
      }
    });
  }
  
  Future<void> _toggleBookmark() async {
    final dataService = Provider.of<FirebaseDataService>(context, listen: false);
    final question = pack.questions[currentIndex];
    
    await dataService.toggleQuestionBookmark(pack.id, question.id);
    if (mounted) {
      setState(() {});
    }
  }
  
  void _showCompletionDialog() {
    final correctAnswers = pack.questions.where((q) => q.isAnswered && q.isCorrect).length;
    final totalQuestions = pack.questions.length;
    final percentage = (correctAnswers / totalQuestions * 100).toInt();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quiz Completed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: percentage >= 70 ? Colors.green.shade100 : 
                       percentage >= 40 ? Colors.orange.shade100 : Colors.red.shade100,
                border: Border.all(
                  color: percentage >= 70 ? Colors.green : 
                         percentage >= 40 ? Colors.orange : Colors.red,
                  width: 4,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$correctAnswers / $totalQuestions',
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.exit_to_app,
                  label: 'Quit',
                  onTap: () {
                    Navigator.of(context).pop(); // Close bottom sheet
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                ),
                _buildActionButton(
                  icon: Icons.analytics,
                  label: 'Analyze',
                  onTap: () {
                    Navigator.of(context).pop(); // Close bottom sheet
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ResultsAnalysisScreen(
                          pack: pack,
                        ),
                      ),
                    );
                  },
                  primary: true,
                ),
                _buildActionButton(
                  icon: Icons.replay,
                  label: 'Pass Again',
                  onTap: () {
                    Navigator.of(context).pop(); // Close bottom sheet
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => QuestionScreen(
                          packId: pack.id,
                          startFromBeginning: true,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primary ? Theme.of(context).primaryColor : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primary ? Colors.white : Colors.black87,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: primary ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (currentIndex >= pack.questions.length) {
      return Scaffold(
        appBar: AppBar(title: Text(pack.title)),
        body: const Center(child: Text('All questions completed!')),
      );
    }
    
    final question = pack.questions[currentIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(pack.title),
        actions: [
          IconButton(
            icon: Icon(
              question.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (currentIndex + 1) / pack.questions.length,
              backgroundColor: Colors.grey[200],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Question ${currentIndex + 1} of ${pack.questions.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            
            // Question text
            Text(
              question.text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            // Answer options
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final option = question.options[index];
                  final bool isSelected = question.isAnswered && 
                      question.selectedOptionIndex == index;
                  final bool isCorrect = question.isAnswered && 
                      index == question.correctOptionIndex;
                  
                  Color? cardColor;
                  if (question.isAnswered) {
                    if (isCorrect) {
                      cardColor = Colors.green[100];
                    } else if (isSelected) {
                      cardColor = Colors.red[100];
                    }
                  }
                  
                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(String.fromCharCode(65 + index)),
                      ),
                      title: Text(option),
                      onTap: question.isAnswered 
                          ? null 
                          : () => _answerQuestion(index),
                      trailing: question.isAnswered
                          ? Icon(
                              isCorrect 
                                  ? Icons.check_circle 
                                  : (isSelected ? Icons.cancel : null),
                              color: isCorrect ? Colors.green : Colors.red,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 