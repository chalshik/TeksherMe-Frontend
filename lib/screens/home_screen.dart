import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_data_service.dart';
import 'test_preview_screen.dart';
import '../widgets/pack_card.dart';
import '../widgets/commercial_card.dart';
import '../screens/home_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load commercials when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FirebaseDataService>(context, listen: false).loadCommercials();
    });
  }
  
  // Track the current page
  int _currentAnnouncementPage = 0;

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<FirebaseDataService>(context);
    final inProgressPacks = dataService.inProgressPacks;
    
    // Get commercials with a fallback for empty results
    final commercials = dataService.commercials.isNotEmpty 
        ? dataService.commercials 
        : _getDummyCommercials();
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add padding to account for status bar
            SizedBox(height: MediaQuery.of(context).padding.top),
            // Add extra spacing to push announcements down
            const SizedBox(height: 40),
            
            // Commercials Section at the top
            if (commercials.isNotEmpty) ...[
              // Height for the carousel
              SizedBox(
                height: 158, // Increased height slightly to prevent overflow
                child: PageView.builder(
                  controller: PageController(
                    viewportFraction: 0.92, // Show more of current item (was 0.85)
                    initialPage: 0,
                  ),
                  onPageChanged: (index) {
                    setState(() {
                      _currentAnnouncementPage = index;
                    });
                  },
                  itemCount: commercials.length,
                  itemBuilder: (context, index) {
                    // Scale and opacity effect
                    final isCurrentPage = index == _currentAnnouncementPage;
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutQuint,
                      margin: EdgeInsets.symmetric(
                        vertical: isCurrentPage ? 0 : 10.0,
                        horizontal: 6.0, // Reduced from 8.0
                      ),
                      child: Opacity(
                        opacity: isCurrentPage ? 1.0 : 0.8,
                        child: CommercialCard(commercial: commercials[index]),
                      ),
                    );
                  },
                ),
              ),
              // Add page indicators
              const SizedBox(height: 8),
              commercials.length > 1 
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      commercials.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentAnnouncementPage
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.withOpacity(0.5),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
              const SizedBox(height: 24),
            ],
            
            // Continue Section
            const Text(
              'Continue Where You Left Off',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
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
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(initialIndex: 1),
                                ),
                              );
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
    // Navigate directly to test preview without showing a dialog
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TestPreviewScreen(
          packId: pack.id,
        ),
      ),
    );
  }
  
  // Fallback method to generate dummy commercials if none are returned from the API
  List<Commercial> _getDummyCommercials() {
    return [
      Commercial(
        id: 'dummy1',
        title: 'Premium Subscription',
        description: 'Unlock all test packs and analytics',
        imageUrl: null,
        url: '',
        ctaText: 'Learn More',
        date: DateTime.now(),
      ),
      Commercial(
        id: 'dummy2',
        title: 'New Expert Packs',
        description: 'Challenge yourself with advanced questions',
        imageUrl: null,
        url: '',
        ctaText: 'Explore',
        date: DateTime.now(),
      ),
    ];
  }
} 