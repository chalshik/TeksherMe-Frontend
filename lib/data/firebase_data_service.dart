import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// For compatibility with existing code:
// - TestSet is used in place of QuestionPack 
// - Both names refer to the same underlying data structure
// - The FirebaseDataService provides compatibility methods that accept the old names

// Type alias for backward compatibility
typedef QuestionPack = TestSet;

class Question {
  final String id;
  final String text;
  final List<QuestionOption> options;
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

  // Compatibility method to access options as strings
  dynamic operator [](int index) {
    if (index >= 0 && index < options.length) {
      return options[index]; // Return the QuestionOption which will be converted to String when needed
    }
    return '';
  }
  
  // Compatibility property
  List<String> get optionsText => options.map((opt) => opt.text).toList();
}

class QuestionOption {
  final String id;
  final String text;

  QuestionOption({
    required this.id,
    required this.text,
  });
  
  // String conversion operations
  @override
  String toString() => text;
  
  // Makes the QuestionOption behave like a string in many contexts
  operator ==(Object other) => 
    other is QuestionOption ? other.text == text : 
    other is String ? other == text : false;
  
  @override
  int get hashCode => text.hashCode;
}

class TestSet {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String difficulty;
  final double timeEstimate; // Changed to double to preserve decimal values
  final List<Question> questions;
  bool isBookmarked;
  int lastQuestionIndex;
  bool isStarted;
  bool isCompleted;
  int? remainingSeconds; // Added to store the remaining time when user quits

  TestSet({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.difficulty,
    required this.timeEstimate,
    required this.questions,
    this.isBookmarked = false,
    this.lastQuestionIndex = 0,
    this.isStarted = false,
    this.isCompleted = false,
    this.remainingSeconds,
  });

  double get progressPercentage {
    if (questions.isEmpty) return 0.0;
    return lastQuestionIndex / questions.length;
  }
  
  // Compatibility properties to work with code expecting QuestionPack
  String get category {
    FirebaseDataService service = FirebaseDataService();
    return service.getCategoryName(categoryId);
  }
}

class Category {
  final String id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });
}

class FirebaseDataService extends ChangeNotifier {
  // Singleton pattern
  static final FirebaseDataService _instance = FirebaseDataService._internal();
  
  factory FirebaseDataService() => _instance;
  
  FirebaseDataService._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // App state
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Data collections
  final List<TestSet> _testSets = [];
  final List<Category> _categories = [];
  
  // Getters
  List<TestSet> get allTestSets => _testSets;
  List<Category> get allCategories => _categories;
  
  List<TestSet> get inProgressTestSets => _testSets
      .where((test) => test.isStarted && !test.isCompleted)
      .toList();

  List<TestSet> get bookmarkedTestSets => 
      _testSets.where((test) => test.isBookmarked).toList();

  List<Question> get bookmarkedQuestions => _testSets
      .expand((test) => test.questions)
      .where((question) => question.isBookmarked)
      .toList();
  
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;
  
  // Initialize with data from Firebase
  Future<void> initialize() async {
    // Don't try to sign in anonymously - this fails if not enabled in Firebase console
    // Just load public data first
    await _loadThemePreference();
    await _loadCategories();
    await _loadTestSets();
    
    // Only load user-specific data if actually signed in
    if (_auth.currentUser != null) {
    await _loadUserProgress();
    await _loadBookmarks();
    }
    
    notifyListeners();
  }
  
  // Authentication Methods
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      
      // Reload user data after login
      await _loadUserProgress();
      await _loadBookmarks();
      notifyListeners();
      
      return userCredential;
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }
  
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign in aborted');
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Create user document if it doesn't exist
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': userCredential.user!.email,
        'displayName': userCredential.user!.displayName,
        'photoURL': userCredential.user!.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Reload user data after login
      await _loadUserProgress();
      await _loadBookmarks();
      notifyListeners();
      
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }
  
  Future<UserCredential> registerWithEmail(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      
      // Update user profile
      await userCredential.user!.updateDisplayName(name);
      
      // Create user document
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'displayName': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
      return userCredential;
    } catch (e) {
      print('Error registering with email: $e');
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      // Clear user-specific data
      _clearUserData();
      
      // Reload test sets without user data
      await _loadTestSets();
      
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  void _clearUserData() {
    // Reset user-specific data in memory
    for (final testSet in _testSets) {
      testSet.isBookmarked = false;
      testSet.lastQuestionIndex = 0;
      testSet.isStarted = false;
      testSet.isCompleted = false;
      testSet.remainingSeconds = null;
      
      for (final question in testSet.questions) {
        question.isBookmarked = false;
        question.isAnswered = false;
        question.selectedOptionIndex = null;
      }
    }
  }
  
  // Load Data Methods
  Future<void> _loadThemePreference() async {
    try {
      if (_auth.currentUser == null) return;
      
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
        
        if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData['themeMode'] != null) {
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
    } catch (e) {
      print('Error loading theme preference: $e');
      _themeMode = ThemeMode.system;
    }
  }
  
  Future<void> _loadCategories() async {
    try {
      _categories.clear();
      
      final categorySnapshot = await _firestore.collection('categories').get();
      
      for (final doc in categorySnapshot.docs) {
        final data = doc.data();
        _categories.add(Category(
          id: doc.id,
          name: data['name'] ?? 'General',
        ));
      }
      
      
    } 
    //NO NEED TO LOAD DEFAULT CATEGORIES
    catch (e) {
      print('Error loading categories: $e');
    }
  }
  
  Future<void> _loadTestSets() async {
    try {
      _testSets.clear();
      
      final testSetSnapshot = await _firestore.collection('question_packs').get();
      
      print('Loaded ${testSetSnapshot.docs.length} test sets from Firestore');
      
      for (final testSetDoc in testSetSnapshot.docs) {
        try {
          // Load questions for this test set
          final questions = await _loadQuestionsForTestSet(testSetDoc.id);
          
          final data = testSetDoc.data();
          
          // Handle time field properly - preserve original double value
          double timeEstimate = 15.0; // Default
          if (data['time'] != null) {
            if (data['time'] is int) {
              timeEstimate = (data['time'] as int).toDouble();
            } else if (data['time'] is double) {
              timeEstimate = data['time'];
            }
          }
          
          final testSet = TestSet(
            id: testSetDoc.id,
            name: data['name'] ?? '',
            description: data['description'] ?? '',
            categoryId: data['categoryId'] ?? '',
            difficulty: data['difficulty'] ?? 'Medium',
            timeEstimate: timeEstimate,
            questions: questions,
          );
          
          _testSets.add(testSet);
        } catch (e) {
          print('Error loading test set ${testSetDoc.id}: $e');
          // Continue with next test set
        }
      }
    } catch (e) {
      print('Error loading test sets: $e');
    }
  }
  
  Future<List<Question>> _loadQuestionsForTestSet(String testSetId) async {
    final questions = <Question>[];
    
    try {
      final questionSnapshot = await _firestore
          .collection('question_packs')
          .doc(testSetId)
          .collection('questions')
          .get();
      
      for (final questionDoc in questionSnapshot.docs) {
        final data = questionDoc.data();
        
        // Check if this question uses the legacy structure with options array
        List<String>? legacyOptions;
        if (data['options'] != null && data['options'] is List) {
          legacyOptions = List<String>.from(data['options']);
        }
        
        List<QuestionOption> options;
        if (legacyOptions != null) {
          // Use legacy options array
          options = legacyOptions.asMap().entries
              .map((entry) => QuestionOption(
                id: entry.key.toString(), 
                text: entry.value,
              ))
            .toList();
        } else {
          // Load options from subcollection
          options = await _loadOptionsForQuestion(testSetId, questionDoc.id);
        }
        
        // Find the correct option index by checking which option has isCorrect=true
        int correctOptionIndex = 0;
        // If the question directly specifies correctOptionIndex, use it (legacy support)
        if (data['correctOptionIndex'] != null) {
          correctOptionIndex = data['correctOptionIndex'];
        } else {
          // Otherwise, we need to find which option is marked as correct
          final optionsSnapshot = await _firestore
              .collection('question_packs')
              .doc(testSetId)
              .collection('questions')
              .doc(questionDoc.id)
              .collection('options')
              .where('isCorrect', isEqualTo: true)
              .get();
          
          if (optionsSnapshot.docs.isNotEmpty) {
            // Get the order of the correct option
            final correctOption = optionsSnapshot.docs.first.data();
            correctOptionIndex = correctOption['order'] ?? 0;
          }
        }
        
        questions.add(Question(
          id: questionDoc.id,
          text: data['text'] ?? '',
          options: options,
          correctOptionIndex: correctOptionIndex,
        ));
      }
    } catch (e) {
      print('Error loading questions for test set $testSetId: $e');
    }
    
    return questions;
  }
  
  Future<List<QuestionOption>> _loadOptionsForQuestion(String testSetId, String questionId) async {
    final options = <QuestionOption>[];
    
    try {
      final optionSnapshot = await _firestore
          .collection('question_packs')
          .doc(testSetId)
          .collection('questions')
          .doc(questionId)
          .collection('options')
          .orderBy('order') // Fixed: removed second parameter
          .get();
      
      for (final optionDoc in optionSnapshot.docs) {
        final data = optionDoc.data();
        options.add(QuestionOption(
          id: optionDoc.id,
          text: data['text'] ?? '',
        ));
      }
    } catch (e) {
      print('Error loading options for question $questionId: $e');
    }
    
    return options;
  }
  
  Future<void> _loadUserProgress() async {
    try {
      if (_auth.currentUser == null) return;
      
      // Get progress documents for the current user
      final progressSnapshot = await _firestore
          .collection('test_progress')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${currentUserId}_')
          .where(FieldPath.documentId, isLessThan: '${currentUserId}_\uf8ff')
          .get();
      
      for (final progressDoc in progressSnapshot.docs) {
        final data = progressDoc.data();
        final testSetId = data['testSetId'] as String?;
        
        if (testSetId != null) {
          final testSet = getTestSetById(testSetId);
          if (testSet != null) {
            testSet.lastQuestionIndex = data['lastQuestionIndex'] ?? 0;
            testSet.isCompleted = data['isCompleted'] ?? false;
            testSet.isStarted = data['isStarted'] ?? false;
            
            // Load remaining seconds if available
            if (data['remainingSeconds'] != null) {
              testSet.remainingSeconds = data['remainingSeconds'] as int;
            }
            
            // Load user answers
            await _loadUserAnswers(testSet, data['attemptId'] as String?);
          }
        }
      }
    } catch (e) {
      print('Error loading user progress: $e');
    }
  }
  
  Future<void> _loadUserAnswers(TestSet testSet, String? attemptId) async {
    try {
      if (attemptId == null || _auth.currentUser == null) return;
      
      final answersSnapshot = await _firestore
          .collection('test_attempts')
          .doc(attemptId)
          .collection('answers')
          .get();
      
      for (final answerDoc in answersSnapshot.docs) {
        final data = answerDoc.data();
        final questionId = data['questionId'] as String?;
        
        if (questionId != null) {
          for (final question in testSet.questions) {
            if (question.id == questionId) {
              question.isAnswered = true;
              question.selectedOptionIndex = data['selectedOptionIndex'] as int?;
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error loading user answers: $e');
    }
  }
  
  Future<void> _loadBookmarks() async {
    try {
      if (_auth.currentUser == null) return;
      
      // Load test set bookmarks
      final testSetBookmarksSnapshot = await _firestore
          .collection('pack_bookmarks')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${currentUserId}_')
          .where(FieldPath.documentId, isLessThan: '${currentUserId}_\uf8ff')
          .get();
      
      for (final bookmarkDoc in testSetBookmarksSnapshot.docs) {
        final data = bookmarkDoc.data();
        final testSetId = data['testSetId'] as String?;
        
        if (testSetId != null) {
          final testSet = getTestSetById(testSetId);
          if (testSet != null) {
            testSet.isBookmarked = true;
          }
        }
      }
      
      // Load question bookmarks
      final questionBookmarksSnapshot = await _firestore
          .collection('question_bookmarks')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${currentUserId}_')
          .where(FieldPath.documentId, isLessThan: '${currentUserId}_\uf8ff')
          .get();
      
      for (final bookmarkDoc in questionBookmarksSnapshot.docs) {
        final data = bookmarkDoc.data();
        final testSetId = data['testSetId'] as String?;
        final questionId = data['questionId'] as String?;
        
        if (testSetId != null && questionId != null) {
          final testSet = getTestSetById(testSetId);
          if (testSet != null) {
            for (final question in testSet.questions) {
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
  
  // Theme Methods
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    try {
      if (_auth.currentUser != null) {
        String themeString = 'system';
        if (mode == ThemeMode.light) {
          themeString = 'light';
        } else if (mode == ThemeMode.dark) {
          themeString = 'dark';
        }
        
        await _firestore.collection('users').doc(currentUserId).update({
          'themeMode': themeString,
        });
      }
    } catch (e) {
      print('Error saving theme preference: $e');
    }
    
    notifyListeners();
  }
  
  // TestSet Methods
  TestSet? getTestSetById(String id) {
    try {
      return _testSets.firstWhere((testSet) => testSet.id == id);
    } catch (e) {
      return null;
    }
  }

  List<TestSet> getTestSetsByCategory(String categoryId) {
    return _testSets.where((testSet) => testSet.categoryId == categoryId).toList();
  }
  
  Future<void> startTestSet(String testSetId) async {
    final testSet = getTestSetById(testSetId);
    if (testSet != null) {
      testSet.lastQuestionIndex = 0;
      testSet.isStarted = true;
      testSet.isCompleted = false;
      
      // Create a new test attempt
      final attemptId = await _createTestAttempt(testSetId);
      
      // Update user progress
      await _updateTestProgress(testSetId, 0, false, attemptId);
      
      notifyListeners();
    }
  }
  
  Future<String> _createTestAttempt(String testSetId) async {
    if (_auth.currentUser == null) return '';
    
    try {
      final attemptRef = await _firestore.collection('test_attempts').add({
        'userId': currentUserId,
        'testSetId': testSetId,
        'startedAt': FieldValue.serverTimestamp(),
        'completed': false,
      });
      
      return attemptRef.id;
    } catch (e) {
      print('Error creating test attempt: $e');
      return '';
    }
  }
  
  Future<void> continueTestSet(String testSetId) async {
    final testSet = getTestSetById(testSetId);
    if (testSet != null) {
      testSet.isStarted = true;
      
      // No need to update Firestore since this is just continuing a test
      // that should already be marked as started
      
      notifyListeners();
    }
  }
  
  Future<void> updateTestProgress(String testSetId, int questionIndex, {int? remainingSeconds}) async {
    final testSet = getTestSetById(testSetId);
    if (testSet != null) {
      testSet.isStarted = true;
      testSet.lastQuestionIndex = questionIndex;
      final isCompleted = questionIndex >= testSet.questions.length;
      
      if (isCompleted) {
        testSet.isCompleted = true;
      }
      
      await _updateTestProgress(testSetId, questionIndex, isCompleted, null, remainingSeconds: remainingSeconds);
      notifyListeners();
    }
  }
  
  Future<void> _updateTestProgress(String testSetId, int questionIndex, bool isCompleted, String? attemptId, {int? remainingSeconds}) async {
    if (_auth.currentUser == null) return;
    
    try {
      // Get current progress doc
      final progressDoc = await _firestore
          .collection('test_progress')
          .doc('${currentUserId}_$testSetId')
          .get();
      
      // If attemptId is null, use the existing one
      final String effectiveAttemptId = attemptId ?? 
          (progressDoc.exists ? (progressDoc.data()?['attemptId'] as String? ?? '') : '');
      
      // Update testSet in memory
      final testSet = getTestSetById(testSetId);
      if (testSet != null && remainingSeconds != null) {
        testSet.remainingSeconds = remainingSeconds;
      }
      
      await _firestore.collection('test_progress').doc('${currentUserId}_$testSetId').set({
        'userId': currentUserId,
        'testSetId': testSetId,
        'lastQuestionIndex': questionIndex,
        'isStarted': true,
        'isCompleted': isCompleted,
        'remainingSeconds': remainingSeconds, // Store remaining time
        'attemptId': effectiveAttemptId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // If test is completed, update the attempt
      if (isCompleted && effectiveAttemptId.isNotEmpty) {
        await _firestore.collection('test_attempts').doc(effectiveAttemptId).update({
          'completed': true,
          'completedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Update in memory even if Firestore fails
      final testSet = getTestSetById(testSetId);
      if (testSet != null) {
        testSet.isStarted = true;
        if (remainingSeconds != null) {
          testSet.remainingSeconds = remainingSeconds;
        }
      }
      print('Error updating test progress: $e');
    }
  }
  
  Future<void> answerQuestion(String testSetId, String questionId, int selectedOptionIndex) async {
    final testSet = getTestSetById(testSetId);
    if (testSet == null) return;
    
    Question? targetQuestion;
    for (final question in testSet.questions) {
      if (question.id == questionId) {
        // If selectedOptionIndex is -1, that means the question was skipped
        if (selectedOptionIndex == -1) {
          question.isAnswered = true;
          question.selectedOptionIndex = null;
        } else {
          question.isAnswered = true;
          question.selectedOptionIndex = selectedOptionIndex;
        }
        targetQuestion = question;
        break;
      }
    }
    
    if (targetQuestion != null && _auth.currentUser != null) {
      try {
        // Get the attempt ID from test progress
        final progressDoc = await _firestore
            .collection('test_progress')
            .doc('${currentUserId}_$testSetId')
            .get();
        
        if (progressDoc.exists) {
          final attemptId = progressDoc.data()?['attemptId'] as String?;
          if (attemptId != null && attemptId.isNotEmpty) {
            // Save the answer
            await _firestore
                .collection('test_attempts')
                .doc(attemptId)
                .collection('answers')
                .doc(questionId)
                .set({
              'questionId': questionId,
              'selectedOptionIndex': targetQuestion.selectedOptionIndex,
              'isCorrect': targetQuestion.isCorrect,
              'answeredAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } catch (e) {
        print('Error saving question answer: $e');
      }
    }
    
    notifyListeners();
  }
  
  // Bookmark Methods
  Future<void> toggleTestSetBookmark(String testSetId) async {
    final testSet = getTestSetById(testSetId);
    if (testSet != null) {
      testSet.isBookmarked = !testSet.isBookmarked;
      
      if (_auth.currentUser != null) {
        try {
          final docId = '${currentUserId}_$testSetId';
          
          if (testSet.isBookmarked) {
          // Add bookmark
            await _firestore.collection('pack_bookmarks').doc(docId).set({
              'userId': currentUserId,
              'testSetId': testSetId,
              'createdAt': FieldValue.serverTimestamp(),
            });
        } else {
          // Remove bookmark
            await _firestore.collection('pack_bookmarks').doc(docId).delete();
        }
      } catch (e) {
          print('Error toggling test set bookmark: $e');
        // Revert the change if error
          testSet.isBookmarked = !testSet.isBookmarked;
        }
      }
      
      notifyListeners();
    }
  }
  
  Future<void> toggleQuestionBookmark(String testSetId, String questionId) async {
    final testSet = getTestSetById(testSetId);
    if (testSet == null) return;
    
      Question? targetQuestion;
    for (final question in testSet.questions) {
        if (question.id == questionId) {
          question.isBookmarked = !question.isBookmarked;
          targetQuestion = question;
          break;
        }
      }
      
    if (targetQuestion != null && _auth.currentUser != null) {
        try {
        final docId = '${currentUserId}_$questionId';
          
          if (targetQuestion.isBookmarked) {
            // Add bookmark
          await _firestore.collection('question_bookmarks').doc(docId).set({
            'userId': currentUserId,
            'testSetId': testSetId,
                'questionId': questionId,
                'createdAt': FieldValue.serverTimestamp(),
          });
          } else {
            // Remove bookmark
          await _firestore.collection('question_bookmarks').doc(docId).delete();
          }
        } catch (e) {
          print('Error toggling question bookmark: $e');
          // Revert the change if error
        for (final question in testSet.questions) {
            if (question.id == questionId) {
              question.isBookmarked = !question.isBookmarked;
              break;
            }
          }
        }
        
        notifyListeners();
    }
  }
  
  // Reset Methods
  Future<void> resetAllProgress() async {
    if (_auth.currentUser == null) return;
    
    try {
      // Reset progress in memory
      for (final testSet in _testSets) {
        testSet.lastQuestionIndex = 0;
        testSet.isCompleted = false;
        testSet.isBookmarked = false;
        testSet.isStarted = false;
        testSet.remainingSeconds = null;
        
        for (final question in testSet.questions) {
          question.isAnswered = false;
          question.isBookmarked = false;
          question.selectedOptionIndex = null;
        }
      }
      
      // Delete progress documents
      final progressSnapshot = await _firestore
          .collection('test_progress')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${currentUserId}_')
          .where(FieldPath.documentId, isLessThan: '${currentUserId}_\uf8ff')
          .get();
      
      for (final doc in progressSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete bookmarks
      final packBookmarksSnapshot = await _firestore
          .collection('pack_bookmarks')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${currentUserId}_')
          .where(FieldPath.documentId, isLessThan: '${currentUserId}_\uf8ff')
          .get();
      
      for (final doc in packBookmarksSnapshot.docs) {
        await doc.reference.delete();
      }
      
      final questionBookmarksSnapshot = await _firestore
          .collection('question_bookmarks')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${currentUserId}_')
          .where(FieldPath.documentId, isLessThan: '${currentUserId}_\uf8ff')
          .get();
      
      for (final doc in questionBookmarksSnapshot.docs) {
        await doc.reference.delete();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error resetting user progress: $e');
    }
  }
  
  // Reset progress for a single test
  Future<void> resetTestProgress(String testSetId) async {
    if (_auth.currentUser == null) return;
    
    try {
      final testSet = getTestSetById(testSetId);
      if (testSet != null) {
        // Reset progress in memory
        testSet.lastQuestionIndex = 0;
        testSet.isStarted = false;
        testSet.isCompleted = false;
        testSet.remainingSeconds = null;
        
        for (final question in testSet.questions) {
          question.isAnswered = false;
          question.selectedOptionIndex = null;
        }
        
        // Delete progress document for this test
        final progressDoc = _firestore
            .collection('test_progress')
            .doc('${currentUserId}_$testSetId');
        
        await progressDoc.delete();
        
        // Delete answer documents if they exist
        final progressSnapshot = await progressDoc.get();
        if (progressSnapshot.exists) {
          final attemptId = progressSnapshot.data()?['attemptId'] as String?;
          
          if (attemptId != null && attemptId.isNotEmpty) {
            final answersSnapshot = await _firestore
                .collection('test_attempts')
                .doc(attemptId)
                .collection('answers')
                .get();
                
            for (final doc in answersSnapshot.docs) {
              await doc.reference.delete();
            }
            
            // Update the attempt document
            await _firestore
                .collection('test_attempts')
                .doc(attemptId)
                .update({
              'completed': false,
              'resetAt': FieldValue.serverTimestamp(),
            });
          }
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Error resetting test progress: $e');
    }
    
    return Future.value();
  }
  
  // Helper to get category name by ID
  String getCategoryName(String categoryId) {
    try {
      final category = _categories.firstWhere((cat) => cat.id == categoryId);
      return category.name;
    } catch (e) {
      return 'General';
    }
  }

  // Add compatibility aliases to maintain backward compatibility with existing code
  
  // Type aliases - typedef doesn't work for classes, but we can create extension methods
  
  // QuestionPack compatibility methods
  Future<void> startPack(String packId) => startTestSet(packId);
  Future<void> continuePack(String packId) => continueTestSet(packId);
  Future<void> updatePackProgress(String packId, int questionIndex, {int? remainingSeconds}) => 
      updateTestProgress(packId, questionIndex, remainingSeconds: remainingSeconds);
  Future<void> togglePackBookmark(String packId) => toggleTestSetBookmark(packId);
  TestSet? getPackById(String id) => getTestSetById(id);
  
  List<TestSet> getPacksByCategory(String category) {
    // Find category ID by name
    String? categoryId;
    try {
      categoryId = _categories.firstWhere((cat) => cat.name.toLowerCase() == category.toLowerCase()).id;
    } catch (e) {
      // If category not found by name, try using the id directly
      categoryId = category;
    }
    return getTestSetsByCategory(categoryId);
  }
  
  // Legacy getter aliases
  List<TestSet> get allQuestionPacks => _testSets;
  List<TestSet> get inProgressPacks => inProgressTestSets;
  List<TestSet> get bookmarkedPacks => bookmarkedTestSets;
  
  // Alias signOut to maintain logout compatibility
  Future<void> logout() => signOut();
} 