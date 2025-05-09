import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'service/firebase_options.dart';
import 'service/firebaseService.dart';
import 'service/firebase_auth.dart';
import 'data/firebase_data_service.dart';
import 'data/theme.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase service
  await FirebaseService.initialize();
  
  // Initialize Firebase data service
  final dataService = FirebaseDataService();
  await dataService.initialize();
  
  // Get authentication service
  final authService = AuthService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dataService),
        ChangeNotifierProvider.value(value: authService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<FirebaseDataService>(context).themeMode;
    
    return MaterialApp(
      title: 'TeksherMe',
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      theme: TeksherTheme.lightTheme(),
      darkTheme: TeksherTheme.darkTheme(),
      home: const AuthWrapper(),
    );
  }
}
