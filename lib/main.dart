import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/data_service.dart';

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  static const List<Widget> _screens = [
    HomeScreen(),
    ExploreScreen(),
    BookmarksScreen(),
    SettingsScreen(),
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Home Screen Widget
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final inProgressPacks = dataService.inProgressPacks;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeksherMe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to TeksherMe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Continue Where You Left Off',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: inProgressPacks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No packs in progress'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to Explore screen
                              _HomePageState? parent = context
                                  .findAncestorStateOfType<_HomePageState>();
                              parent?._onItemTapped(1);
                            },
                            child: const Text('Explore Packs'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: inProgressPacks.length,
                      itemBuilder: (context, index) {
                        final pack = inProgressPacks[index];
                        return PackCard(
                          pack: pack,
                          onTap: () => _showContinueOptions(context, pack),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showContinueOptions(BuildContext context, QuestionPack pack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pack.title),
        content: const Text('Would you like to continue where you left off or restart?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QuestionScreen(
                    packId: pack.id,
                    startFromBeginning: true,
                  ),
                ),
              );
            },
            child: const Text('Restart'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QuestionScreen(
                    packId: pack.id,
                    startFromBeginning: false,
                  ),
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

// Explore Screen Widget
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final allPacks = dataService.allQuestionPacks;
    
    // Get unique categories
    final categories = allPacks
        .map((pack) => pack.category)
        .toSet()
        .toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search packs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                // Implement search functionality later
              },
            ),
            const SizedBox(height: 16),
            
            // Categories
            Text(
              'Categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                    child: ActionChip(
                      label: Text(categories[index]),
                      onPressed: () {
                        // Show packs in this category
                        _showPacksByCategory(context, categories[index]);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // All packs
            Text(
              'All Packs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: allPacks.length,
                itemBuilder: (context, index) {
                  final pack = allPacks[index];
                  return PackCard(
                    pack: pack,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => QuestionScreen(
                            packId: pack.id, 
                            startFromBeginning: pack.lastQuestionIndex == 0,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPacksByCategory(BuildContext context, String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryPacksScreen(category: category),
      ),
    );
  }
}

// Category Packs Screen
class CategoryPacksScreen extends StatelessWidget {
  final String category;
  
  const CategoryPacksScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final packs = dataService.getPacksByCategory(category);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: packs.length,
          itemBuilder: (context, index) {
            final pack = packs[index];
            return PackCard(
              pack: pack,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuestionScreen(
                      packId: pack.id, 
                      startFromBeginning: pack.lastQuestionIndex == 0,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Bookmarks Screen Widget
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookmarks'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Packs'),
              Tab(text: 'Questions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BookmarkedPacksTab(),
            BookmarkedQuestionsTab(),
          ],
        ),
      ),
    );
  }
}

class BookmarkedPacksTab extends StatelessWidget {
  const BookmarkedPacksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final bookmarkedPacks = dataService.bookmarkedPacks;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: bookmarkedPacks.isEmpty
          ? const Center(
              child: Text('No bookmarked packs yet'),
            )
          : ListView.builder(
              itemCount: bookmarkedPacks.length,
              itemBuilder: (context, index) {
                final pack = bookmarkedPacks[index];
                return PackCard(
                  pack: pack,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QuestionScreen(
                          packId: pack.id, 
                          startFromBeginning: pack.lastQuestionIndex == 0,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class BookmarkedQuestionsTab extends StatelessWidget {
  const BookmarkedQuestionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final bookmarkedQuestions = dataService.bookmarkedQuestions;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: bookmarkedQuestions.isEmpty
          ? const Center(
              child: Text('No bookmarked questions yet'),
            )
          : ListView.builder(
              itemCount: bookmarkedQuestions.length,
              itemBuilder: (context, index) {
                final question = bookmarkedQuestions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(
                          question.options.length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: question.isAnswered
                                        ? (i == question.correctOptionIndex
                                            ? Colors.green
                                            : (i == question.selectedOptionIndex
                                                ? Colors.red
                                                : Colors.grey[200]))
                                        : Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + i),
                                      style: TextStyle(
                                        color: question.isAnswered &&
                                                (i == question.correctOptionIndex ||
                                                    i == question.selectedOptionIndex)
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(question.options[i])),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Settings Screen Widget
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(_getThemeModeName(dataService.themeMode)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showThemeOptions(context),
            ),
            const Divider(),
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Log Out'),
              leading: const Icon(Icons.logout),
              onTap: () => dataService.logout(),
            ),
            const Divider(),
            const Text(
              'Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Reset Progress'),
              leading: const Icon(Icons.refresh),
              onTap: () => _showResetConfirmation(context),
            ),
            const Divider(),
            const Spacer(),
            Center(
              child: Text(
                'Version 1.0.0',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }
  
  void _showThemeOptions(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              dataService.setThemeMode(ThemeMode.system);
              Navigator.pop(context);
            },
            child: const Text('System Default'),
          ),
          SimpleDialogOption(
            onPressed: () {
              dataService.setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
            child: const Text('Light'),
          ),
          SimpleDialogOption(
            onPressed: () {
              dataService.setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
            child: const Text('Dark'),
          ),
        ],
      ),
    );
  }
  
  void _showResetConfirmation(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text('This will reset all your progress and bookmarks. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              dataService.resetAllProgress();
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Question Screen
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
  
  @override
  void initState() {
    super.initState();
    final dataService = Provider.of<DataService>(context, listen: false);
    pack = dataService.getPackById(widget.packId)!;
    
    if (widget.startFromBeginning) {
      currentIndex = 0;
      dataService.startPack(widget.packId);
    } else {
      currentIndex = pack.lastQuestionIndex;
      dataService.continuePack(widget.packId);
    }
  }
  
  void _answerQuestion(int optionIndex) {
    final dataService = Provider.of<DataService>(context, listen: false);
    final question = pack.questions[currentIndex];
    
    dataService.answerQuestion(pack.id, question.id, optionIndex);
    
    // Wait a moment to show the result before moving to next question
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (currentIndex < pack.questions.length - 1) {
            currentIndex++;
            dataService.updatePackProgress(pack.id, currentIndex);
          } else {
            // End of pack
            dataService.updatePackProgress(pack.id, pack.questions.length);
            _showCompletionDialog();
          }
        });
      }
    });
  }
  
  void _toggleBookmark() {
    final dataService = Provider.of<DataService>(context, listen: false);
    final question = pack.questions[currentIndex];
    
    dataService.toggleQuestionBookmark(pack.id, question.id);
    setState(() {});
  }
  
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pack Completed'),
        content: Text('You have completed the "${pack.title}" pack!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Return Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentIndex >= pack.questions.length) {
      return Scaffold(
        appBar: AppBar(title: Text(pack.title)),
        body: const Center(child: Text('All questions completed!')),
      );
    }
    
    final question = pack.questions[currentIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(pack.title),
        actions: [
          IconButton(
            icon: Icon(
              question.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (currentIndex + 1) / pack.questions.length,
              backgroundColor: Colors.grey[200],
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
            Text(
              question.text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            // Answer options
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final option = question.options[index];
                  final bool isSelected = question.isAnswered && 
                      question.selectedOptionIndex == index;
                  final bool isCorrect = question.isAnswered && 
                      index == question.correctOptionIndex;
                  
                  Color? cardColor;
                  if (question.isAnswered) {
                    if (isCorrect) {
                      cardColor = Colors.green[100];
                    } else if (isSelected) {
                      cardColor = Colors.red[100];
                    }
                  }
                  
                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(String.fromCharCode(65 + index)),
                      ),
                      title: Text(option),
                      onTap: question.isAnswered 
                          ? null 
                          : () => _answerQuestion(index),
                      trailing: question.isAnswered
                          ? Icon(
                              isCorrect 
                                  ? Icons.check_circle 
                                  : (isSelected ? Icons.cancel : null),
                              color: isCorrect ? Colors.green : Colors.red,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Question Pack Card
class PackCard extends StatelessWidget {
  final QuestionPack pack;
  final VoidCallback onTap;
  
  const PackCard({
    super.key,
    required this.pack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pack.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      pack.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    onPressed: () {
                      dataService.togglePackBookmark(pack.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(pack.difficulty),
                    backgroundColor: _getDifficultyColor(pack.difficulty),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(pack.category),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(pack.description),
              const SizedBox(height: 8),
              if (pack.lastQuestionIndex > 0 && !pack.isCompleted) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: pack.progressPercentage,
                ),
                const SizedBox(height: 4),
                Text(
                  'Progress: ${(pack.progressPercentage * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (pack.isCompleted)
                const Text(
                  'COMPLETED',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer, size: 16),
                  const SizedBox(width: 4),
                  Text('${pack.timeEstimate} min'),
                  const SizedBox(width: 16),
                  const Icon(Icons.question_answer, size: 16),
                  const SizedBox(width: 4),
                  Text('${pack.questions.length} questions'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green[100]!;
      case 'medium':
        return Colors.orange[100]!;
      case 'hard':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}
