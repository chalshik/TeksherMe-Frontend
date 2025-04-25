import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import 'results_analysis_screen.dart';
import 'test_preview_screen.dart';

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
  
  // Timer variables
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isTimeLimited = false;
  
  @override
  void initState() {
    super.initState();
    _initPack();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  Future<void> _initPack() async {
    final dataService = Provider.of<FirebaseDataService>(context, listen: false);
    pack = dataService.getPackById(widget.packId)!;
    
    if (widget.startFromBeginning) {
      currentIndex = 0;
      await dataService.startPack(widget.packId);
      
      // Initialize timer when starting from beginning
      if (pack.timeEstimate > 0) {
        _isTimeLimited = true;
        _secondsRemaining = pack.timeEstimate * 60; // Convert minutes to seconds
        _startTimer();
      }
    } else {
      currentIndex = pack.lastQuestionIndex;
      await dataService.continuePack(widget.packId);
      
      // For continued tests, we scale the remaining time based on the remaining questions
      if (pack.timeEstimate > 0) {
        _isTimeLimited = true;
        final questionsRemaining = pack.questions.length - currentIndex;
        final percentRemaining = questionsRemaining / pack.questions.length;
        _secondsRemaining = (pack.timeEstimate * 60 * percentRemaining).round();
        _startTimer();
      }
    }
    
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _showTimeUpDialog();
      }
    });
  }
  
  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time\'s Up!'),
        content: const Text('Your time for this test has ended.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submitTest();
            },
            child: const Text('View Results'),
          ),
        ],
      ),
    );
  }
  
  void _submitTest() async {
    final dataService = Provider.of<FirebaseDataService>(context, listen: false);
    
    // Mark remaining questions as unanswered
    for (int i = currentIndex; i < pack.questions.length; i++) {
      if (!pack.questions[i].isAnswered) {
        // We use -1 to indicate that the question was not answered
        await dataService.answerQuestion(pack.id, pack.questions[i].id, -1);
      }
    }
    
    await dataService.updatePackProgress(pack.id, pack.questions.length);
    
    if (mounted) {
      _showCompletionDialog();
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
    // Cancel timer when showing completion dialog
    _timer?.cancel();
    
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
                        builder: (context) => TestPreviewScreen(
                          packId: pack.id,
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
  
  String _formatTimeRemaining() {
    final minutes = (_secondsRemaining / 60).floor();
    final seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
          if (_isTimeLimited) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _secondsRemaining < 60 ? Colors.red[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimeRemaining(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _secondsRemaining < 60 ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
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