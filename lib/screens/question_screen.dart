import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import 'results_analysis_screen.dart';
import 'test_preview_screen.dart';
import 'explore_screen.dart';
import 'home_page.dart';

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
        _secondsRemaining = (pack.timeEstimate * 60).round(); // Convert to int with round()
        _startTimer();
      }
    } else {
      currentIndex = pack.lastQuestionIndex;
      await dataService.continuePack(widget.packId);
      
      // For continued tests, use the saved remaining time if available
      if (pack.timeEstimate > 0) {
        _isTimeLimited = true;
        
        if (pack.remainingSeconds != null) {
          // Use the saved remaining time
          _secondsRemaining = pack.remainingSeconds!;
        } else {
          // Fallback to calculating based on remaining questions
          final questionsRemaining = pack.questions.length - currentIndex;
          final percentRemaining = questionsRemaining / pack.questions.length;
          _secondsRemaining = (pack.timeEstimate * 60 * percentRemaining).round();
        }
        
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
        // When time is up, directly submit the test and show completion dialog
        _submitTest();
      }
    });
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
    
    // Store the answer without evaluation
    await dataService.answerQuestion(pack.id, question.id, optionIndex);
    
    // Update UI to show selection without evaluation
    if (mounted) {
      setState(() {
        // Just refresh the UI to show the selected option
      });
    }
  }
  
  Future<void> _toggleBookmark() async {
    final dataService = Provider.of<FirebaseDataService>(context, listen: false);
    final question = pack.questions[currentIndex];
    
    if (question.isBookmarked) {
      // Show confirmation dialog for unbookmarking
      _showUnbookmarkConfirmation(
        context,
        'Remove Bookmark',
        'Are you sure you want to remove this question from your bookmarks?',
        () async {
          await dataService.toggleQuestionBookmark(pack.id, question.id);
          if (mounted) {
            setState(() {});
          }
        }
      );
    } else {
      // Bookmark directly without confirmation
      await dataService.toggleQuestionBookmark(pack.id, question.id);
      if (mounted) {
        setState(() {});
      }
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
  
  void _showCompletionDialog() {
    // Cancel timer when showing completion dialog
    _timer?.cancel();
    
    final correctAnswers = pack.questions.where((q) => q.isAnswered && q.isCorrect).length;
    final totalQuestions = pack.questions.length;
    final percentage = (correctAnswers / totalQuestions * 100).toInt();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,  // Prevent dismissing by tapping outside
      enableDrag: false,     // Prevent dismissing by dragging down
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WillPopScope(
        // Prevent back button from closing the bottom sheet
        onWillPop: () async => false,
        child: Padding(
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
                      
                      // Navigate to HomePage with explore tab selected
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const HomePage(initialIndex: 1),
                        ),
                        (route) => false, // Remove all previous screens
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.analytics,
                    label: 'Analyze',
                    onTap: () {
                      Navigator.of(context).pop(); // Close bottom sheet
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => ResultsAnalysisScreen(
                            pack: pack,
                            onFinish: () {
                              // Go to explore screen when finished with analysis
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(initialIndex: 1),
                                ),
                                (route) => false,
                              );
                            },
                          ),
                        ),
                        (route) => false, // Remove all previous screens
                      );
                    },
                    primary: true,
                  ),
                  _buildActionButton(
                    icon: Icons.replay,
                    label: 'Pass Again',
                    onTap: () {
                      // First close the bottom sheet
                      Navigator.pop(context);
                      
                      // First pop back to the question screen
                      Navigator.pop(context);
                      
                      // Get data service
                      final dataService = Provider.of<FirebaseDataService>(context, listen: false);
                      
                      // Complete reset of the test progress
                      dataService.resetTestProgress(pack.id).then((_) {
                        // Then create a brand new question screen
                        // Use pushReplacement to replace the current page entirely
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestartQuestionScreen(packId: pack.id),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primary 
                  ? Theme.of(context).colorScheme.primary
                  : isDark 
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primary 
                  ? Colors.white
                  : isDark
                      ? Colors.white
                      : Colors.black87,
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
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    if (currentIndex >= pack.questions.length) {
      return Scaffold(
        body: SafeArea(
          child: Center(child: Text('All questions completed!')),
        ),
      );
    }
    
    final question = pack.questions[currentIndex];
    
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Bar
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showQuitConfirmation(),
                ),
                
                // Quiz title
                Expanded(
                  child: Text(
                    pack.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Skip button
                TextButton(
                  onPressed: () {
                    if (currentIndex < pack.questions.length - 1) {
                      _navigateToQuestion(currentIndex + 1);
                    } else {
                      _submitTest();
                    }
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Progress bar and indicators
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              children: [
                // Progress indicator
                Container(
                  height: 4,
                  margin: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (currentIndex + 1) / pack.questions.length,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey.shade800 
                          : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.green
                            : Colors.green,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
                
                // Question count and timer
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Question count
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${currentIndex + 1}/${pack.questions.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      
                      // Timer
                      if (_isTimeLimited)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimeRemaining(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Question content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Question category/type
                
                
                // Question text
                Text(
                  question.text,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 32),
                
                // Answer options
                ...List.generate(
                  question.options.length,
                  (index) {
                    final option = question.options[index];
                    final bool isSelected = question.selectedOptionIndex == index;
                    final String optionLetter = String.fromCharCode(1040 + index); // А, Б, В, Г (Cyrillic)
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _answerQuestion(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? (isSelected 
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Colors.grey.shade800)
                                : (isSelected 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: Colors.green, width: 1)
                                : Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          child: Row(
                            children: [
                              // Option letter in circle
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.green
                                      : Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey.shade700
                                          : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.green
                                        : Colors.grey.shade400,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    optionLetter,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Option text
                              Expanded(
                                child: Text(
                                  option.toString(),
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Bottom button
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (currentIndex < pack.questions.length - 1) {
                  _navigateToQuestion(currentIndex + 1);
                } else {
                  _submitTest();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                currentIndex < pack.questions.length - 1 ? 'Next' : 'Finish',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _navigateToQuestion(int index) async {
    if (index < 0 || index >= pack.questions.length) return;
    
    final dataService = Provider.of<FirebaseDataService>(context, listen: false);
    await dataService.updatePackProgress(pack.id, index);
    
    if (mounted) {
      setState(() {
        currentIndex = index;
      });
    }
  }
  
  void _showFinishConfirmation() {
    final unansweredCount = pack.questions.where((q) => !q.isAnswered).length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Quiz?'),
        content: unansweredCount > 0
            ? Text('You have $unansweredCount unanswered ${unansweredCount == 1 ? "question" : "questions"}. Are you sure you want to finish?')
            : const Text('Are you sure you want to finish and submit your answers?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitTest();
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }
  
  void _showQuitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Quiz?'),
        content: const Text('Your progress will be saved. Are you sure you want to quit?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _quitQuiz();
            },
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }
  
  void _quitQuiz() async {
    final dataService = Provider.of<FirebaseDataService>(context, listen: false);
    
    await dataService.updatePackProgress(
      pack.id, 
      currentIndex,
      remainingSeconds: _secondsRemaining,
    );
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomePage(initialIndex: 1),
        ),
        (route) => false,
      );
    }
  }
}

class RestartQuestionScreen extends StatelessWidget {
  final String packId;
  
  const RestartQuestionScreen({
    super.key,
    required this.packId,
  });

  @override
  Widget build(BuildContext context) {
    return QuestionScreen(
      packId: packId,
      startFromBeginning: true,
    );
  }
} 