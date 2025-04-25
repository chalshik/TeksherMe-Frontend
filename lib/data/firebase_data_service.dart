import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/firebaseService.dart';
import '../service/firebase_auth.dart';

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

  // Factory constructor to create a QuestionPack from Firestore data
  factory QuestionPack.fromFirestore(DocumentSnapshot doc, List<Question> questions) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionPack(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      difficulty: data['difficulty'] ?? 'Medium',
      timeEstimate: data['timeEstimate'] ?? 15,
      questions: questions,
      isBookmarked: false, // Will be set separately based on user data
      lastQuestionIndex: 0, // Will be set separately based on user progress
      isCompleted: false, // Will be set separately based on user progress
    );
  }

  // Convert to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'timeEstimate': timeEstimate,
    };
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

  // Factory constructor to create a Question from Firestore data
  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Get options as a List<String>
    List<String> options = [];
    if (data['options'] != null && data['options'] is List) {
      options = List<String>.from(data['options']);
    }
    
    return Question(
      id: doc.id,
      text: data['text'] ?? '',
      options: options,
      correctOptionIndex: data['correctOptionIndex'] ?? 0,
      isBookmarked: false, // Will be set separately based on user data
      isAnswered: false, // Will be set based on user's answers
    );
  }

  // Convert to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
    };
  }
}

class FirebaseDataService extends ChangeNotifier {
  // Singleton pattern
  static final FirebaseDataService _instance = FirebaseDataService._internal();
  
  factory FirebaseDataService() => _instance;
  
  FirebaseDataService._internal();

  // Firebase service
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

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
  
  // Initialize with data from Firebase
  Future<void> initialize() async {
    await _loadThemePreference();
    await _loadQuestionPacks();
    await _loadUserProgress();
    await _loadBookmarks();
    notifyListeners();
  }
  
  // Load theme preference from user data
  Future<void> _loadThemePreference() async {
    try {
      final userId = _authService.getCurrentUserId();
      if (userId != 'anonymous') {
        final userDocRef = _firebaseService.usersCollection.doc(userId);
        final userDoc = await userDocRef.get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          if (userData['themeMode'] != null) {
            final themeString = userData['themeMode'] as String;
            if (themeString == 'light') {
              _themeMode = ThemeMode.light;
            } else if (themeString == 'dark') {
              _themeMode = ThemeMode.dark;
            } else {
              _themeMode = ThemeMode.system;
            }
          }
        }
      }
    } catch (e) {
      print('Error loading theme preference: $e');
      // Default to system theme if error occurs
      _themeMode = ThemeMode.system;
    }
  }
  
  // Theme functions
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    try {
      final userId = _authService.getCurrentUserId();
      if (userId != 'anonymous') {
        // Save theme preference to user's document in Firestore
        String themeString = 'system';
        if (mode == ThemeMode.light) {
          themeString = 'light';
        } else if (mode == ThemeMode.dark) {
          themeString = 'dark';
        }
        
        await _firebaseService.updateDocument(
          'users', 
          userId, 
          {'themeMode': themeString}
        );
      }
    } catch (e) {
      print('Error saving theme preference: $e');
    }
    
    notifyListeners();
  }
  
  // Load all question packs from Firestore
  Future<void> _loadQuestionPacks() async {
    try {
      _questionPacks.clear();
      
      // Get all question packs
      final packSnapshot = await _firebaseService.getCollection('question_packs');
      
      for (final packDoc in packSnapshot.docs) {
        // Get questions for this pack
        final questionsSnapshot = await _firebaseService.getCollection(
          'question_packs/${packDoc.id}/questions'
        );
        
        final questions = questionsSnapshot.docs
            .map((doc) => Question.fromFirestore(doc))
            .toList();
        
        // Create the question pack with its questions
        final pack = QuestionPack.fromFirestore(packDoc, questions);
        _questionPacks.add(pack);
      }
    } catch (e) {
      print('Error loading question packs: $e');
    }
  }
  
  // Load user progress from Firestore
  Future<void> _loadUserProgress() async {
    try {
      final userId = _authService.getCurrentUserId();
      if (userId == 'anonymous') return;
      
      // Get user progress documents
      final progressSnapshot = await _firebaseService.getCollection(
        'user_progress',
        whereConditions: [['userId', '==', userId]]
      );
      
      for (final progressDoc in progressSnapshot.docs) {
        final progressData = progressDoc.data() as Map<String, dynamic>;
        final packId = progressData['packId'] as String?;
        
        if (packId != null) {
          final pack = getPackById(packId);
          if (pack != null) {
            pack.lastQuestionIndex = progressData['lastQuestionIndex'] ?? 0;
            pack.isCompleted = progressData['isCompleted'] ?? false;
            
            // If this document has answer data, update question states
            if (progressData['answers'] != null && progressData['answers'] is Map) {
              final answers = progressData['answers'] as Map;
              
              for (final questionId in answers.keys) {
                for (final question in pack.questions) {
                  if (question.id == questionId) {
                    final answerData = answers[questionId] as Map?;
                    if (answerData != null) {
                      question.isAnswered = true;
                      question.selectedOptionIndex = answerData['selectedOptionIndex'] as int?;
                    }
                    break;
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error loading user progress: $e');
    }
  }
  
  // Load bookmarks from Firestore
  Future<void> _loadBookmarks() async {
    try {
      final userId = _authService.getCurrentUserId();
      if (userId == 'anonymous') return;
      
      // Get pack bookmarks
      final packBookmarksSnapshot = await _firebaseService.getCollection(
        'pack_bookmarks',
        whereConditions: [['userId', '==', userId]]
      );
      
      for (final bookmarkDoc in packBookmarksSnapshot.docs) {
        final bookmarkData = bookmarkDoc.data() as Map<String, dynamic>;
        final packId = bookmarkData['packId'] as String?;
        
        if (packId != null) {
          final pack = getPackById(packId);
          if (pack != null) {
            pack.isBookmarked = true;
          }
        }
      }
      
      // Get question bookmarks
      final questionBookmarksSnapshot = await _firebaseService.getCollection(
        'question_bookmarks',
        whereConditions: [['userId', '==', userId]]
      );
      
      for (final bookmarkDoc in questionBookmarksSnapshot.docs) {
        final bookmarkData = bookmarkDoc.data() as Map<String, dynamic>;
        final packId = bookmarkData['packId'] as String?;
        final questionId = bookmarkData['questionId'] as String?;
        
        if (packId != null && questionId != null) {
          final pack = getPackById(packId);
          if (pack != null) {
            for (final question in pack.questions) {
              if (question.id == questionId) {
                question.isBookmarked = true;
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error loading bookmarks: $e');
    }
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
  
  Future<void> startPack(String packId) async {
    final pack = getPackById(packId);
    if (pack != null) {
      pack.lastQuestionIndex = 0;
      pack.isCompleted = false;
      
      await _saveUserProgress(packId);
      notifyListeners();
    }
  }
  
  Future<void> continuePack(String packId) async {
    // Just trigger UI update
    notifyListeners();
  }
  
  Future<void> updatePackProgress(String packId, int questionIndex) async {
    final pack = getPackById(packId);
    if (pack != null) {
      pack.lastQuestionIndex = questionIndex;
      if (questionIndex >= pack.questions.length) {
        pack.isCompleted = true;
      }
      
      await _saveUserProgress(packId);
      notifyListeners();
    }
  }
  
  Future<void> _saveUserProgress(String packId) async {
    try {
      final userId = _authService.getCurrentUserId();
      if (userId == 'anonymous') return;
      
      final pack = getPackById(packId);
      if (pack == null) return;
      
      // Build answers map
      final answersMap = <String, dynamic>{};
      for (final question in pack.questions) {
        if (question.isAnswered) {
          answersMap[question.id] = {
            'selectedOptionIndex': question.selectedOptionIndex,
            'isCorrect': question.isCorrect,
          };
        }
      }
      
      // Create or update progress document
      final docId = '$userId-$packId';
      await _firebaseService.setDocument(
        'user_progress',
        docId,
        {
          'userId': userId,
          'packId': packId,
          'lastQuestionIndex': pack.lastQuestionIndex,
          'isCompleted': pack.isCompleted,
          'answers': answersMap,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      print('Error saving user progress: $e');
    }
  }
  
  Future<void> togglePackBookmark(String packId) async {
    final pack = getPackById(packId);
    if (pack != null) {
      pack.isBookmarked = !pack.isBookmarked;
      
      try {
        final userId = _authService.getCurrentUserId();
        if (userId == 'anonymous') return;
        
        final docId = '$userId-$packId';
        
        if (pack.isBookmarked) {
          // Add bookmark
          await _firebaseService.setDocument(
            'pack_bookmarks',
            docId,
            {
              'userId': userId,
              'packId': packId,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
        } else {
          // Remove bookmark
          await _firebaseService.deleteDocument('pack_bookmarks', docId);
        }
      } catch (e) {
        print('Error toggling pack bookmark: $e');
        // Revert the change if error
        pack.isBookmarked = !pack.isBookmarked;
      }
      
      notifyListeners();
    }
  }
  
  // Question functions
  Future<void> answerQuestion(String packId, String questionId, int selectedOption) async {
    final pack = getPackById(packId);
    if (pack != null) {
      for (final question in pack.questions) {
        if (question.id == questionId) {
          question.isAnswered = true;
          question.selectedOptionIndex = selectedOption;
          
          // Save the progress
          await _saveUserProgress(packId);
          notifyListeners();
          break;
        }
      }
    }
  }
  
  Future<void> toggleQuestionBookmark(String packId, String questionId) async {
    final pack = getPackById(packId);
    if (pack != null) {
      Question? targetQuestion;
      
      for (final question in pack.questions) {
        if (question.id == questionId) {
          question.isBookmarked = !question.isBookmarked;
          targetQuestion = question;
          break;
        }
      }
      
      if (targetQuestion != null) {
        try {
          final userId = _authService.getCurrentUserId();
          if (userId == 'anonymous') return;
          
          final docId = '$userId-$questionId';
          
          if (targetQuestion.isBookmarked) {
            // Add bookmark
            await _firebaseService.setDocument(
              'question_bookmarks',
              docId,
              {
                'userId': userId,
                'packId': packId,
                'questionId': questionId,
                'createdAt': FieldValue.serverTimestamp(),
              },
            );
          } else {
            // Remove bookmark
            await _firebaseService.deleteDocument('question_bookmarks', docId);
          }
        } catch (e) {
          print('Error toggling question bookmark: $e');
          // Revert the change if error
          for (final question in pack.questions) {
            if (question.id == questionId) {
              question.isBookmarked = !question.isBookmarked;
              break;
            }
          }
        }
        
        notifyListeners();
      }
    }
  }
  
  // Reset all progress
  Future<void> resetAllProgress() async {
    try {
      final userId = _authService.getCurrentUserId();
      if (userId == 'anonymous') return;
      
      // Reset progress in memory
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
      
      // Delete progress documents from Firestore
      final progressSnapshot = await _firebaseService.getCollection(
        'user_progress',
        whereConditions: [['userId', '==', userId]]
      );
      
      for (final doc in progressSnapshot.docs) {
        await _firebaseService.deleteDocument('user_progress', doc.id);
      }
      
      // Delete bookmark documents from Firestore
      final packBookmarksSnapshot = await _firebaseService.getCollection(
        'pack_bookmarks',
        whereConditions: [['userId', '==', userId]]
      );
      
      for (final doc in packBookmarksSnapshot.docs) {
        await _firebaseService.deleteDocument('pack_bookmarks', doc.id);
      }
      
      final questionBookmarksSnapshot = await _firebaseService.getCollection(
        'question_bookmarks',
        whereConditions: [['userId', '==', userId]]
      );
      
      for (final doc in questionBookmarksSnapshot.docs) {
        await _firebaseService.deleteDocument('question_bookmarks', doc.id);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error resetting user progress: $e');
    }
  }
} 