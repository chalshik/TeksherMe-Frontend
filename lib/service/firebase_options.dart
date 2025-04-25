// File generated based on firebase configuration
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Replace these placeholder values with your actual Firebase configuration
  // You can get these values by running the FlutterFire CLI:
  // flutter pub global activate flutterfire_cli
  // flutterfire configure
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDrcPh2R80-ZAYRip7w2cNpyBu8wbzUnYs',
    appId: '1:520480110917:android:fccc2b60a4919e6ea9662c',
    messagingSenderId: '520480110917',
    projectId: 'teksherme-3a2fe',
    authDomain: 'teksherme-3a2fe.firebaseapp.com',
    storageBucket: 'teksherme-3a2fe.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDrcPh2R80-ZAYRip7w2cNpyBu8wbzUnYs',
    appId: '1:520480110917:android:fccc2b60a4919e6ea9662c',
    messagingSenderId: '520480110917',
    projectId: 'teksherme-3a2fe',
    storageBucket: 'teksherme-3a2fe.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDrcPh2R80-ZAYRip7w2cNpyBu8wbzUnYs',
    appId: '1:520480110917:android:fccc2b60a4919e6ea9662c',
    messagingSenderId: '520480110917',
    projectId: 'teksherme-3a2fe',
    storageBucket: 'teksherme-3a2fe.firebasestorage.app',
  );
}