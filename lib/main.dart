import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'service/firebase_options.dart';
import 'service/firebaseService.dart';
import 'service/firebase_auth.dart';
import 'data/firebase_data_service.dart';
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9E77ED),
          secondary: Color(0xFF626EEF),
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
          error: Color(0xFFCF6679),
        ),
        cardTheme: const CardTheme(
          color: Color(0xFF2C2C2C),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFF3A3A3A),
          selectedColor: Color(0xFF9E77ED),
          labelStyle: TextStyle(color: Colors.white),
          secondaryLabelStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
