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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showQuitConfirmation(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                
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
                
                _isTimeLimited 
                    ? _buildTimer()
                    : PopupMenuButton<int>(
                        tooltip: 'Jump to question',
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: _buildJumpToQuestionMenu,
            onSelected: (index) => _navigateToQuestion(index),
          ),
              ],
            ),
            
            if (_isTimeLimited) 
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<int>(
                      tooltip: 'Jump to question',
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: _buildJumpToQuestionMenu,
                      onSelected: (index) => _navigateToQuestion(index),
                    ),
                  ],
                ),
              ),
              
            const SizedBox(height: 8),
            
            LinearProgressIndicator(
              value: (currentIndex + 1) / pack.questions.length,
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade800 
                  : Colors.blue.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primary
                    : Colors.blue,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
              question.text,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    question.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: question.isBookmarked ? Colors.amber : null,
                  ),
                  onPressed: _toggleBookmark,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
              ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final option = question.options[index];
                  final bool isSelected = question.selectedOptionIndex == index;
                  
                  Color? cardColor;
                  if (isSelected) {
                    cardColor = Theme.of(context).brightness == Brightness.dark 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2) 
                        : Color(0xFFE3F2FD);
                  }
                  
                  return Card(
                    color: cardColor,
                    elevation: isSelected ? 2 : 1,
                    shadowColor: isSelected 
                        ? Colors.blue.withOpacity(0.3) 
                        : Colors.black.withOpacity(0.1),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected 
                          ? BorderSide(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              width: 1.5,
                            ) 
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]
                                : Colors.grey[300]),
                        foregroundColor: isSelected || Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                        child: Text(String.fromCharCode(65 + index)),
                      ),
                      title: Text(option.toString()),
                      onTap: () => _answerQuestion(index),
                      trailing: null,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentIndex > 0 
                      ? () => _navigateToQuestion(currentIndex - 1) 
                      : null,
                  child: const Text(
                    '<<',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                
                if (currentIndex == pack.questions.length - 1)
                  ElevatedButton.icon(
                    onPressed: () => _submitTest(),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Finish Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                
                ElevatedButton(
                  onPressed: currentIndex < pack.questions.length - 1
                      ? () => _navigateToQuestion(currentIndex + 1)
                      : null,
                  child: const Text(
                    '>>',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
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
  
  // Add method for building the timer widget
  Widget _buildTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _secondsRemaining < 60 
            ? Theme.of(context).brightness == Brightness.dark 
                ? Colors.red.withOpacity(0.3) 
                : const Color(0xFFFFEBEE) // Light red background
            : Theme.of(context).brightness == Brightness.dark 
                ? Theme.of(context).colorScheme.surface
                : const Color(0xFFE3F2FD), // Light blue background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _secondsRemaining < 60 
              ? Colors.red.withOpacity(0.3) 
              : Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer, 
            size: 16,
            color: _secondsRemaining < 60 ? Colors.red : null,
          ),
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
    );
}

  // Add method for building the jump to question menu
  List<PopupMenuEntry<int>> _buildJumpToQuestionMenu(BuildContext context) {
    return [
      // Add jump to question heading
      const PopupMenuItem(
        enabled: false,
        child: Text(
          'Jump to Question',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      // Add a divider
      const PopupMenuDivider(),
      // Add items for each question
      for (int i = 0; i < pack.questions.length; i++)
        PopupMenuItem(
          value: i,
          child: Row(
            children: [
              // Show check mark for answered questions
              if (pack.questions[i].isAnswered)
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.green[300]
                      : Colors.green,
                ),
              // Show current question indicator
              if (i == currentIndex && !pack.questions[i].isAnswered)
                Icon(
                  Icons.radio_button_checked,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              // Show empty circle for unanswered, non-current questions
              if (i != currentIndex && !pack.questions[i].isAnswered)
                Icon(
                  Icons.radio_button_unchecked,
                  size: 16,
                  color: Colors.grey,
                ),
              const SizedBox(width: 8),
              Text('Question ${i + 1}'),
            ],
          ),
        ),
    ];
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