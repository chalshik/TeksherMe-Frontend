import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Singleton pattern
  factory AuthService() => _instance;
  
  AuthService._internal() {
    // Subscribe to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  // Current user variable
  User? _currentUser;
  
  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String getCurrentUserId() {
    return _auth.currentUser?.uid ?? 'anonymous';
  }

  // Subscribe to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
    } catch (error) {
      print('Error signing in: $error');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
    } catch (error) {
      print('Error signing up: $error');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // For mobile platforms
      if (!kIsWeb) {
        // Start the Google sign-in flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          print('Sign-in canceled by user');
          return null;
        }
        
        // Get authentication tokens
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        // Create and return credential
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        return await _auth.signInWithCredential(credential);
      } 
      // For web platform
      else {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      }
    } catch (error) {
      print('Error signing in with Google: $error');
      rethrow;
    }
  }

  // Sign in with Google using ID token (useful for platform-specific implementations)
  Future<UserCredential> signInWithGoogleIdToken(String idToken) async {
    try {
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );
      
      return await _auth.signInWithCredential(credential);
    } catch (error) {
      print('Error signing in with Google ID token: $error');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (error) {
      print('Error sending password reset email: $error');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Sign out from Google
      await _auth.signOut(); // Sign out from Firebase
    } catch (error) {
      print('Error signing out: $error');
      rethrow;
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  // Get authentication error message
  String getAuthErrorMessage(FirebaseAuthException error) {
    String errorCode = error.code;
    
    switch (errorCode) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already in use by another account.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'invalid-credential':
        return 'The credential is invalid or has expired.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      case 'too-many-requests':
        return 'Too many unsuccessful login attempts. Please try again later.';
      default:
        return 'An error occurred during authentication. Please try again.';
    }
  }
}