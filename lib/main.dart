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
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _searchQuery = '';
  List<QuestionPack> _searchResults = [];
  
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
                setState(() {
                  _searchQuery = value;
                  if (value.isEmpty) {
                    _searchResults = [];
                  } else {
                    _searchResults = allPacks
                        .where((pack) => 
                            pack.title.toLowerCase().contains(value.toLowerCase()) ||
                            pack.description.toLowerCase().contains(value.toLowerCase()) ||
                            pack.category.toLowerCase().contains(value.toLowerCase()))
                        .toList();
                  }
                });
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
            
            // Show search results if there's a search query
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Search Results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _searchResults.isEmpty
                    ? const Center(
                        child: Text('No matching packs found'),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final pack = _searchResults[index];
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
            ] else ...[
              // Show instructions when no search or category is selected
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Search for packs or select a category',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Discover question packs by using the search bar\nor tapping on a category above',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
      // Defer state update to after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dataService.startPack(widget.packId);
      });
    } else {
      currentIndex = pack.lastQuestionIndex;
      // Defer state update to after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dataService.continuePack(widget.packId);
      });
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
    final correctAnswers = pack.questions.where((q) => q.isAnswered && q.isCorrect).length;
    final totalQuestions = pack.questions.length;
    final percentage = (correctAnswers / totalQuestions * 100).toInt();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quiz Completed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: percentage >= 70 ? Colors.green.shade100 : 
                       percentage >= 40 ? Colors.orange.shade100 : Colors.red.shade100,
                border: Border.all(
                  color: percentage >= 70 ? Colors.green : 
                         percentage >= 40 ? Colors.orange : Colors.red,
                  width: 4,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$correctAnswers / $totalQuestions',
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.exit_to_app,
                  label: 'Quit',
                  onTap: () {
                    Navigator.of(context).pop(); // Close bottom sheet
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                ),
                _buildActionButton(
                  icon: Icons.analytics,
                  label: 'Analyze',
                  onTap: () {
                    Navigator.of(context).pop(); // Close bottom sheet
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ResultsAnalysisScreen(
                          pack: pack,
                        ),
                      ),
                    );
                  },
                  primary: true,
                ),
                _buildActionButton(
                  icon: Icons.replay,
                  label: 'Pass Again',
                  onTap: () {
                    Navigator.of(context).pop(); // Close bottom sheet
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => QuestionScreen(
                          packId: pack.id,
                          startFromBeginning: true,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primary ? Theme.of(context).primaryColor : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primary ? Colors.white : Colors.black87,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: primary ? FontWeight.bold : FontWeight.normal,
            ),
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

// Results Analysis Screen
class ResultsAnalysisScreen extends StatelessWidget {
  final QuestionPack pack;

  const ResultsAnalysisScreen({
    super.key,
    required this.pack,
  });

  @override
  Widget build(BuildContext context) {
    final correctAnswers = pack.questions.where((q) => q.isAnswered && q.isCorrect).length;
    final totalQuestions = pack.questions.length;
    final percentage = (correctAnswers / totalQuestions * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => QuestionScreen(
                    packId: pack.id,
                    startFromBeginning: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.replay),
            label: const Text('Pass Again'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Results summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: percentage >= 70 ? Colors.green.shade100 : 
                           percentage >= 40 ? Colors.orange.shade100 : Colors.red.shade100,
                    border: Border.all(
                      color: percentage >= 70 ? Colors.green : 
                             percentage >= 40 ? Colors.orange : Colors.red,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$correctAnswers/$totalQuestions',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pack.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildResultStat(
                            label: 'Correct',
                            value: correctAnswers,
                            color: Colors.green,
                          ),
                          _buildResultStat(
                            label: 'Wrong',
                            value: totalQuestions - correctAnswers,
                            color: Colors.red,
                          ),
                          _buildResultStat(
                            label: 'Total',
                            value: totalQuestions,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Question list
          Expanded(
            child: ListView.builder(
              itemCount: pack.questions.length,
              itemBuilder: (context, index) {
                final question = pack.questions[index];
                final isAnswered = question.isAnswered;
                final selectedIndex = question.selectedOptionIndex;
                final correctIndex = question.correctOptionIndex;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question number and bookmark indicator
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Q${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (question.isBookmarked)
                              const Icon(Icons.bookmark, color: Colors.amber),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Question text
                        Text(
                          question.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Options
                        ...List.generate(
                          question.options.length,
                          (i) {
                            final isSelected = isAnswered && selectedIndex == i;
                            final isCorrect = correctIndex == i;
                            
                            Color? bgColor;
                            if (isAnswered) {
                              if (isCorrect) {
                                bgColor = Colors.green.shade50;
                              } else if (isSelected) {
                                bgColor = Colors.red.shade50;
                              }
                            }
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border.all(
                                  color: isCorrect ? Colors.green : 
                                         (isSelected ? Colors.red : Colors.grey.shade300),
                                  width: isCorrect || isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCorrect ? Colors.green : 
                                             (isSelected ? Colors.red : Colors.grey.shade200),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + i),
                                        style: TextStyle(
                                          color: isCorrect || isSelected ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      question.options[i],
                                      style: TextStyle(
                                        fontWeight: isCorrect || isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isCorrect)
                                    const Icon(Icons.check_circle, color: Colors.green)
                                  else if (isSelected && !isCorrect)
                                    const Icon(Icons.cancel, color: Colors.red)
                                ],
                              ),
                            );
                          },
                        ),
                        
                        // Result indicator
                        if (isAnswered) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                selectedIndex == correctIndex ? Icons.check_circle : Icons.cancel,
                                color: selectedIndex == correctIndex ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedIndex == correctIndex ? 'Correct Answer' : 'Wrong Answer',
                                style: TextStyle(
                                  color: selectedIndex == correctIndex ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultStat({
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
