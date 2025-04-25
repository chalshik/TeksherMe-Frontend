import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  
  // Firebase services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Singleton pattern
  factory FirebaseService() => _instance;
  
  FirebaseService._internal();
  
  // Initialize Firebase
  static Future<FirebaseService> initialize() async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    return _instance;
  }

  // Firestore collection references
  CollectionReference get usersCollection => _firestore.collection('users');
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Get current user ID
  String getCurrentUserId() {
    return _auth.currentUser?.uid ?? 'anonymous';
  }
  
  // Get a document from any collection by ID
  Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      print('Error getting document: $e');
      rethrow;
    }
  }
  
  // Add a document to any collection
  Future<DocumentReference> addDocument(String collection, Map<String, dynamic> data) async {
    try {
      return await _firestore.collection(collection).add(data);
    } catch (e) {
      print('Error adding document: $e');
      rethrow;
    }
  }
  
  // Set a document in any collection with a specific ID
  Future<void> setDocument(String collection, String docId, Map<String, dynamic> data, {bool merge = true}) async {
    try {
      await _firestore.collection(collection).doc(docId).set(data, SetOptions(merge: merge));
    } catch (e) {
      print('Error setting document: $e');
      rethrow;
    }
  }
  
  // Update a document in any collection
  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      print('Error updating document: $e');
      rethrow;
    }
  }
  
  // Delete a document from any collection
  Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      print('Error deleting document: $e');
      rethrow;
    }
  }
  
  // Get a stream of a document
  Stream<DocumentSnapshot> streamDocument(String collection, String docId) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }
  
  // Get a stream of a collection
  Stream<QuerySnapshot> streamCollection(String collection, {
    String? orderBy,
    bool descending = false,
    int? limit,
    List<List<dynamic>>? whereConditions,
  }) {
    Query query = _firestore.collection(collection);
    
    // Apply where conditions if provided
    if (whereConditions != null) {
      for (var condition in whereConditions) {
        if (condition.length >= 3) {
          query = query.where(condition[0], isEqualTo: condition[1] == '==' ? condition[2] : null,
              isLessThan: condition[1] == '<' ? condition[2] : null,
              isLessThanOrEqualTo: condition[1] == '<=' ? condition[2] : null,
              isGreaterThan: condition[1] == '>' ? condition[2] : null,
              isGreaterThanOrEqualTo: condition[1] == '>=' ? condition[2] : null,
              arrayContains: condition[1] == 'array-contains' ? condition[2] : null);
        }
      }
    }
    
    // Apply orderBy if provided
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    // Apply limit if provided
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots();
  }
  
  // Get a collection with query (non-stream version)
  Future<QuerySnapshot> getCollection(String collection, {
    String? orderBy,
    bool descending = false,
    int? limit,
    List<List<dynamic>>? whereConditions,
  }) async {
    Query query = _firestore.collection(collection);
    
    // Apply where conditions if provided
    if (whereConditions != null) {
      for (var condition in whereConditions) {
        if (condition.length >= 3) {
          query = query.where(condition[0], isEqualTo: condition[1] == '==' ? condition[2] : null,
              isLessThan: condition[1] == '<' ? condition[2] : null,
              isLessThanOrEqualTo: condition[1] == '<=' ? condition[2] : null,
              isGreaterThan: condition[1] == '>' ? condition[2] : null,
              isGreaterThanOrEqualTo: condition[1] == '>=' ? condition[2] : null,
              arrayContains: condition[1] == 'array-contains' ? condition[2] : null);
        }
      }
    }
    
    // Apply orderBy if provided
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    // Apply limit if provided
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.get();
  }
  
  // Upload a file to Firebase Storage
  Future<String> uploadFile(List<int> fileBytes, String path, String filename) async {
    try {
      final Reference ref = _storage.ref().child(path).child(filename);
      final UploadTask uploadTask = ref.putData(Uint8List.fromList(fileBytes));
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }
  
  // Delete a file from Firebase Storage
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }
  
  // Get download URL for a file
  Future<String> getFileDownloadUrl(String path) async {
    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (e) {
      print('Error getting download URL: $e');
      rethrow;
    }
  }

  // Create user profile in Firestore after registration
  Future<void> createUserProfile(User user, {String? displayName, String? photoURL}) async {
    try {
      await usersCollection.doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName ?? user.displayName ?? '',
        'photoURL': photoURL ?? user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // Update user's last login timestamp
  Future<void> updateUserLastLogin(String userId) async {
    try {
      await usersCollection.doc(userId).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last login: $e');
      rethrow;
    }
  }
}