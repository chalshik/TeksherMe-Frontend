import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/data_service.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize data service
  final dataService = DataService();
  await dataService.initialize();
  
  runApp(
    ChangeNotifierProvider.value(
      value: dataService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<DataService>(context).themeMode;
    
    return MaterialApp(
      title: 'TeksherMe',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const HomePage(),
    );
  }
}
