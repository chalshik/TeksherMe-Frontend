import 'package:flutter/material.dart';

class QuestionPack {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int timeEstimate; // in minutes
  final List<Question> questions;
  bool isBookmarked;
  int lastQuestionIndex;
  bool isCompleted;

  QuestionPack({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.timeEstimate,
    required this.questions,
    this.isBookmarked = false,
    this.lastQuestionIndex = 0,
    this.isCompleted = false,
  });

  double get progressPercentage {
    if (questions.isEmpty) return 0.0;
    return lastQuestionIndex / questions.length;
  }
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctOptionIndex;
  bool isBookmarked;
  bool isAnswered;
  int? selectedOptionIndex;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    this.isBookmarked = false,
    this.isAnswered = false,
    this.selectedOptionIndex,
  });

  bool get isCorrect => 
    isAnswered && selectedOptionIndex == correctOptionIndex;
}

class DataService extends ChangeNotifier {
  // Singleton pattern
  static final DataService _instance = DataService._internal();
  
  factory DataService() => _instance;
  
  DataService._internal();

  // User data
  String? _username;
  String? get username => _username;

  // App state
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Data collections
  final List<QuestionPack> _questionPacks = [];
  List<QuestionPack> get allQuestionPacks => _questionPacks;
  
  List<QuestionPack> get inProgressPacks => _questionPacks
      .where((pack) => pack.lastQuestionIndex > 0 && !pack.isCompleted)
      .toList();

  List<QuestionPack> get bookmarkedPacks => 
      _questionPacks.where((pack) => pack.isBookmarked).toList();

  List<Question> get bookmarkedQuestions => _questionPacks
      .expand((pack) => pack.questions)
      .where((question) => question.isBookmarked)
      .toList();
  
  // Initialize with mock data for now
  Future<void> initialize() async {
    // Mock data - will be replaced with Firebase fetch later
    _initializeMockData();
    notifyListeners();
  }
  
  // Auth functions (will connect to Firebase later)
  Future<bool> login(String username, String password) async {
    // Mock login for now
    _username = username;
    notifyListeners();
    return true;
  }
  
  Future<void> logout() async {
    _username = null;
    notifyListeners();
  }
  
  // Theme functions
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
  
  // Question pack functions
  QuestionPack? getPackById(String id) {
    try {
      return _questionPacks.firstWhere((pack) => pack.id == id);
    } catch (e) {
      return null;
    }
  }

  List<QuestionPack> getPacksByCategory(String category) {
    return _questionPacks
        .where((pack) => pack.category == category)
        .toList();
  }
  
  void startPack(String packId) {
    final pack = getPackById(packId);
    if (pack != null) {
      pack.lastQuestionIndex = 0;
      pack.isCompleted = false;
      notifyListeners();
    }
  }
  
  void continuePack(String packId) {
    // No action needed, just access lastQuestionIndex
    notifyListeners();
  }
  
  void updatePackProgress(String packId, int questionIndex) {
    final pack = getPackById(packId);
    if (pack != null) {
      pack.lastQuestionIndex = questionIndex;
      if (questionIndex >= pack.questions.length) {
        pack.isCompleted = true;
      }
      notifyListeners();
    }
  }
  
  void togglePackBookmark(String packId) {
    final pack = getPackById(packId);
    if (pack != null) {
      pack.isBookmarked = !pack.isBookmarked;
      notifyListeners();
    }
  }
  
  // Question functions
  void answerQuestion(String packId, String questionId, int selectedOption) {
    final pack = getPackById(packId);
    if (pack != null) {
      final question = pack.questions.firstWhere((q) => q.id == questionId);
      question.isAnswered = true;
      question.selectedOptionIndex = selectedOption;
      notifyListeners();
    }
  }
  
  void toggleQuestionBookmark(String packId, String questionId) {
    final pack = getPackById(packId);
    if (pack != null) {
      final question = pack.questions.firstWhere((q) => q.id == questionId);
      question.isBookmarked = !question.isBookmarked;
      notifyListeners();
    }
  }
  
  // Find the pack ID for a question with the given ID
  String getPackIdForQuestion(String questionId) {
    for (final pack in _questionPacks) {
      for (final question in pack.questions) {
        if (question.id == questionId) {
          return pack.id;
        }
      }
    }
    return ''; // Return empty string if not found
  }
  
  // Reset all progress
  void resetAllProgress() {
    for (final pack in _questionPacks) {
      pack.lastQuestionIndex = 0;
      pack.isCompleted = false;
      pack.isBookmarked = false;
      
      for (final question in pack.questions) {
        question.isAnswered = false;
        question.isBookmarked = false;
        question.selectedOptionIndex = null;
      }
    }
    notifyListeners();
  }
  
  // Reset answers for a specific pack
  void resetPackAnswers(String packId) {
    final pack = getPackById(packId);
    if (pack != null) {
      pack.lastQuestionIndex = 0;
      pack.isCompleted = false;
      
      for (final question in pack.questions) {
        question.isAnswered = false;
        question.selectedOptionIndex = null;
      }
      notifyListeners();
    }
  }
  
  // Mock data initialization
  void _initializeMockData() {
    _questionPacks.clear();
    
    // Add some sample question packs
    _questionPacks.addAll([
      QuestionPack(
        id: '1',
        title: 'Flutter Basics',
        description: 'Learn the fundamentals of Flutter development',
        category: 'Programming',
        difficulty: 'Easy',
        timeEstimate: 15,
        questions: [
          Question(
            id: '1-1',
            text: 'What language is Flutter built with?',
            options: ['JavaScript', 'Dart', 'Kotlin', 'Swift'],
            correctOptionIndex: 1,
          ),
          Question(
            id: '1-2',
            text: 'Which widget is used to create a button in Flutter?',
            options: ['ButtonWidget', 'FlatButton', 'PressableWidget', 'ElevatedButton'],
            correctOptionIndex: 3,
          ),
          Question(
            id: '1-3',
            text: 'What is the purpose of setState() in Flutter?',
            options: [
              'To navigate to a new screen',
              'To update the UI after changing variables',
              'To declare new variables',
              'To handle API calls'
            ],
            correctOptionIndex: 1,
          ),
        ],
      ),
      QuestionPack(
        id: '2',
        title: 'Math Fundamentals',
        description: 'Review basic mathematical concepts',
        category: 'Mathematics',
        difficulty: 'Medium',
        timeEstimate: 20,
        questions: [
          Question(
            id: '2-1',
            text: 'What is the value of π (pi) to two decimal places?',
            options: ['3.14', '3.41', '3.12', '3.45'],
            correctOptionIndex: 0,
          ),
          Question(
            id: '2-2',
            text: 'What is the square root of 144?',
            options: ['12', '14', '10', '16'],
            correctOptionIndex: 0,
          ),
          Question(
            id: '2-3',
            text: 'What is the result of 7 × 8?',
            options: ['54', '56', '48', '64'],
            correctOptionIndex: 1,
          ),
        ],
      ),
      QuestionPack(
        id: '3',
        title: 'World Geography',
        description: 'Test your knowledge of global geography',
        category: 'Geography',
        difficulty: 'Hard',
        timeEstimate: 25,
        questions: [
          Question(
            id: '3-1',
            text: 'What is the capital of Australia?',
            options: ['Sydney', 'Melbourne', 'Canberra', 'Perth'],
            correctOptionIndex: 2,
          ),
          Question(
            id: '3-2',
            text: 'Which country has the largest land area?',
            options: ['Canada', 'China', 'United States', 'Russia'],
            correctOptionIndex: 3,
          ),
          Question(
            id: '3-3',
            text: 'Which of these is not a continent?',
            options: ['Europe', 'Africa', 'Asia', 'Greenland'],
            correctOptionIndex: 3,
          ),
        ],
      ),
    ]);
  }
} 