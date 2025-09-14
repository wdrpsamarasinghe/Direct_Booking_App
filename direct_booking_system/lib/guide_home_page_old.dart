import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'signin_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_page.dart';
import 'create_profile_page.dart';
import 'guide_trips_page.dart';
import 'theme/app_theme.dart';

class GuideHomePage extends StatefulWidget {
  const GuideHomePage({Key? key}) : super(key: key);

  @override
  State<GuideHomePage> createState() => _GuideHomePageState();
}

class _GuideHomePageState extends State<GuideHomePage> {
  int _currentIndex = 0;
  
  List<Widget> get _pages => [
    HomeContent(parentContext: context),
    const GuideTripsPage(),
    const GuideOngoingPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surfaceLight,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trip_origin_outlined),
              activeIcon: Icon(Icons.trip_origin),
              label: 'Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_run_outlined),
              activeIcon: Icon(Icons.directions_run),
              label: 'Ongoing',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final BuildContext parentContext;
  
  const HomeContent({Key? key, required this.parentContext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(),
              const SizedBox(height: 30),
              
              // Create Guide Profile Section
              _buildCreateProfileSection(),
              const SizedBox(height: 30),
              
              // Ratings & Reviews Section
              _buildRatingsReviewsSection(),
              const SizedBox(height: 30),
              
              // Quick Stats
              _buildQuickStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final FirebaseService _firebaseService = FirebaseService();
    final String? _uid = _firebaseService.currentUser?.uid;

    return Row(
      children: [
        // Profile Avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.secondaryOrange],
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 30,
          ),
        ),
        
        const SizedBox(width: 15),
        
        // Welcome Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              (_uid == null)
                  ? const Text(
                      'Guest',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    )
                  : FutureBuilder<DocumentSnapshot>(
                      future: _firebaseService.getUserData(_uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          );
                        }
                        final data = snapshot.data?.data() as Map<String, dynamic>?;
                        final String name = (data?['name'] as String?) ?? 'Guide';
                        return Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 4),
              (_uid == null)
                  ? const Text(
                      'Professional Tour Guide',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : FutureBuilder<DocumentSnapshot>(
                      future: _firebaseService.getUserData(_uid),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data() as Map<String, dynamic>?;
                        final String role = (data?['role'] as String?) ?? 'Professional Tour Guide';
                        return Text(
                          role,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
        
        // Notification + Overflow Menu
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  _showNotifications(parentContext);
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'settings') {
                    // Navigate to Settings tab
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  } else if (value == 'logout') {
                    try {
                      await FirebaseService().signOut();
                      if (parentContext.mounted) {
                        Navigator.pushAndRemoveUntil(
                          parentContext,
                          MaterialPageRoute(builder: (context) => const SigninPage()),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text('Failed to log out: ${e.toString()}'),
                            backgroundColor: AppTheme.errorRed,
                          ),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: Text('Settings'),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Text('Log Out'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.secondaryOrange],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Guide Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Set up your professional profile to attract more clients',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(
                    builder: (context) => const CreateProfilePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceLight,
                foregroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ratings & Reviews',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        
        // Overall Rating Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              // Rating Display
              Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        '4.8',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warningYellow,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        color: AppTheme.warningYellow,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Based on 127 reviews',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 20),
              
              // Rating Bars
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, 0.8),
                    _buildRatingBar(4, 0.15),
                    _buildRatingBar(3, 0.03),
                    _buildRatingBar(2, 0.01),
                    _buildRatingBar(1, 0.01),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Recent Reviews
        const Text(
          'Recent Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        
        HomeContent._buildReviewCard(
          name: 'Emma Thompson',
          rating: 5,
          comment: 'Excellent tour guide! Kumara was very knowledgeable about Sri Lankan history and made the experience unforgettable.',
          date: '2 days ago',
        ),
        
        const SizedBox(height: 12),
        
        HomeContent._buildReviewCard(
          name: 'Michael Rodriguez',
          rating: 4,
          comment: 'Great experience overall. Very professional and friendly guide. Highly recommend for cultural tours.',
          date: '1 week ago',
        ),
        
        const SizedBox(height: 15),
        
        Center(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                _showAllReviews(context);
              },
              child: const Text(
                'View All Reviews',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppTheme.dividerBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.warningYellow),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(percentage * 100).round()}%',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildReviewCard({
    required String name,
    required int rating,
    required String comment,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) => Icon(
                          Icons.star,
                          size: 16,
                          color: index < rating 
                              ? const Color(0xFFed8936)
                              : Colors.grey[300],
                        )),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Center(
      child: _buildStatCard(
        icon: Icons.star,
        title: 'Rating',
        value: '4.8',
        color: AppTheme.warningYellow,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAllReviews(BuildContext context) {
    final List<Map<String, dynamic>> allReviews = [
      {
        'name': 'Emma Thompson',
        'rating': 5,
        'comment': 'Excellent tour guide! Kumara was very knowledgeable about Sri Lankan history and made the experience unforgettable.',
        'date': '2 days ago',
      },
      {
        'name': 'Michael Rodriguez',
        'rating': 4,
        'comment': 'Great experience overall. Very professional and friendly guide. Highly recommend for cultural tours.',
        'date': '1 week ago',
      },
      {
        'name': 'Sarah Johnson',
        'rating': 5,
        'comment': 'Amazing tour of Sigiriya! Kumara explained everything in detail and was very patient with our questions.',
        'date': '2 weeks ago',
      },
      {
        'name': 'David Chen',
        'rating': 5,
        'comment': 'Wonderful experience visiting the Temple of the Tooth. Kumara\'s knowledge of Buddhist culture is impressive.',
        'date': '3 weeks ago',
      },
      {
        'name': 'Maria Garcia',
        'rating': 4,
        'comment': 'Great tour of Kandy. Kumara showed us the best spots and shared interesting local stories.',
        'date': '1 month ago',
      },
      {
        'name': 'James Wilson',
        'rating': 5,
        'comment': 'Fantastic wildlife safari in Yala National Park. Kumara knew exactly where to find the leopards!',
        'date': '1 month ago',
      },
      {
        'name': 'Sophie Anderson',
        'rating': 4,
        'comment': 'Beautiful tour of the tea plantations in Nuwara Eliya. Kumara was very informative about the tea industry.',
        'date': '2 months ago',
      },
      {
        'name': 'Carlos Martinez',
        'rating': 5,
        'comment': 'Excellent city tour of Colombo. Kumara showed us both the modern and historical sides of the city.',
        'date': '2 months ago',
      },
      {
        'name': 'Lisa Brown',
        'rating': 5,
        'comment': 'Amazing experience at the Galle Fort. Kumara\'s historical knowledge made the tour very engaging.',
        'date': '3 months ago',
      },
      {
        'name': 'Robert Taylor',
        'rating': 4,
        'comment': 'Great tour of the spice gardens. Kumara explained the medicinal properties of various spices.',
        'date': '3 months ago',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'All Reviews',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Reviews List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: allReviews.length,
                itemBuilder: (context, index) {
                  final review = allReviews[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: HomeContent._buildReviewCard(
                      name: review['name'],
                      rating: review['rating'],
                      comment: review['comment'],
                      date: review['date'],
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

  void _showNotifications(BuildContext context) async {
    final user = FirebaseService().currentUser;
    if (user == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
        ),
      ),
    );

    try {
      // Fetch comprehensive notifications
      final notifications = await FirebaseService().getComprehensiveGuideNotifications(user.uid);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show enhanced notifications modal
      _showEnhancedNotificationsModal(context, notifications);
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading notifications: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _showEnhancedNotificationsModal(BuildContext context, Map<String, List<Map<String, dynamic>>> notifications) {
    String selectedCategory = 'all';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Get all notifications for display
          List<Map<String, dynamic>> allNotifications = [];
          if (selectedCategory == 'all') {
            allNotifications = [
              ...notifications['urgent']!,
              ...notifications['tours']!,
              ...notifications['reviews']!,
              ...notifications['payments']!,
              ...notifications['reminders']!,
              ...notifications['system']!,
            ];
          } else {
            allNotifications = notifications[selectedCategory] ?? [];
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_active,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                                fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                            Text(
                              '${allNotifications.length} notifications',
                      style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                      ),
                            ),
                          ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                  ),
                ],
              ),
            ),
                
                const SizedBox(height: 20),
                
                // Category Filter Tabs
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryTab('all', 'All', _getTotalNotificationCount(notifications), selectedCategory, setState),
                      _buildCategoryTab('urgent', 'Urgent', notifications['urgent']!.length, selectedCategory, setState),
                      _buildCategoryTab('tours', 'Tours', notifications['tours']!.length, selectedCategory, setState),
                      _buildCategoryTab('reviews', 'Reviews', notifications['reviews']!.length, selectedCategory, setState),
                      _buildCategoryTab('payments', 'Payments', notifications['payments']!.length, selectedCategory, setState),
                      _buildCategoryTab('reminders', 'Reminders', notifications['reminders']!.length, selectedCategory, setState),
                      _buildCategoryTab('system', 'System', notifications['system']!.length, selectedCategory, setState),
                    ],
                  ),
                ),
            
            const SizedBox(height: 20),
            
            // Notifications List
            Expanded(
                  child: allNotifications.isEmpty
                      ? _buildEmptyNotifications()
                      : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: allNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = allNotifications[index];
                            return _buildEnhancedNotificationCard(context, notification);
                          },
              ),
            ),
          ],
        ),
          );
        },
      ),
    );
  }

  int _getTotalNotificationCount(Map<String, List<Map<String, dynamic>>> notifications) {
    return notifications['urgent']!.length +
           notifications['tours']!.length +
           notifications['reviews']!.length +
           notifications['payments']!.length +
           notifications['reminders']!.length +
           notifications['system']!.length;
  }

  Widget _buildCategoryTab(String category, String label, int count, String selectedCategory, StateSetter setState) {
    bool isSelected = selectedCategory == category;
    
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! Check back later for updates.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedNotificationCard(BuildContext context, Map<String, dynamic> notification) {
    String priority = notification['priority'] ?? 'medium';
    bool actionRequired = notification['actionRequired'] ?? false;
    
    Color priorityColor = _getPriorityColor(priority);
    IconData priorityIcon = _getPriorityIcon(priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: actionRequired ? Colors.orange[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: actionRequired ? Colors.orange[200]! : Colors.grey[200]!,
          width: actionRequired ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Priority and Type Icon
          Container(
              width: 48,
              height: 48,
            decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: priorityColor.withOpacity(0.3)),
            ),
            child: Icon(
                notification['icon'] ?? priorityIcon,
                color: priorityColor,
                size: 24,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Notification Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Title and Priority Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          notification['title'] ?? 'Notification',
                        style: TextStyle(
                          fontSize: 16,
                            fontWeight: actionRequired ? FontWeight.bold : FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                      if (actionRequired)
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Action Required',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Message
                  Text(
                    notification['message'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Time and Action Button
                  Row(
                    children: [
                      Text(
                        _getTimeAgo(notification['notificationTime'] ?? DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      if (actionRequired)
                        ElevatedButton(
                          onPressed: () => _handleNotificationAction(context, notification),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(80, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'View',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return Icons.warning;
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationAction(BuildContext context, Map<String, dynamic> notification) {
    String notificationType = notification['notificationType'] ?? '';
    
    switch (notificationType) {
      case 'trip_reminder':
        // Show trip details or contact tourist
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Handling trip reminder for: ${notification['tripTitle']}'),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );
        break;
      case 'new_review':
        // Show review details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing review from: ${notification['touristName']}'),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );
        break;
      case 'system':
        // Handle system notifications
        if (notification['actionUrl'] == '/profile/edit') {
          // Navigate to profile edit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Navigate to profile edit'),
              backgroundColor: AppTheme.primaryBlue,
            ),
          );
        }
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Handling notification: ${notification['title']}'),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );
    }
  }

  void _showTourNotificationsModal(BuildContext context, Map<String, List<Map<String, dynamic>>> notifications) {
    String selectedCategory = 'all';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Get all notifications for display
          List<Map<String, dynamic>> allNotifications = [];
          if (selectedCategory == 'all') {
            allNotifications = [
              ...notifications['pending']!,
              ...notifications['ongoing']!,
              ...notifications['completed']!,
              ...notifications['rejected']!,
            ];
          } else {
            allNotifications = notifications[selectedCategory] ?? [];
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
                        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                        'Tour Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
                
                const SizedBox(height: 20),
                
                // Category Filter Tabs
                _buildCategoryTabs(selectedCategory, (category) {
                  setState(() {
                    selectedCategory = category;
                  });
                }, notifications),
            
            const SizedBox(height: 20),
            
            // Notifications List
            Expanded(
                  child: allNotifications.isEmpty
                      ? _buildEmptyState(selectedCategory)
                      : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: allNotifications.length,
                itemBuilder: (context, index) {
                            final notification = allNotifications[index];
                            return _buildTourNotificationCard(context, notification);
                },
              ),
            ),
          ],
        ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs(String selectedCategory, Function(String) onCategoryChanged, Map<String, List<Map<String, dynamic>>> notifications) {
    final categories = [
      {'key': 'all', 'label': 'All', 'count': notifications.values.expand((x) => x).length},
      {'key': 'pending', 'label': 'Pending', 'count': notifications['pending']!.length},
      {'key': 'ongoing', 'label': 'Ongoing', 'count': notifications['ongoing']!.length},
      {'key': 'completed', 'label': 'Completed', 'count': notifications['completed']!.length},
      {'key': 'rejected', 'label': 'Rejected', 'count': notifications['rejected']!.length},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['key'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onCategoryChanged(category['key'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    if (category['count'] as int > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          category['count'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String category) {
    String message;
    IconData icon;
    
    switch (category) {
      case 'pending':
        message = 'No pending tour applications';
        icon = Icons.pending_actions;
        break;
      case 'ongoing':
        message = 'No ongoing tours';
        icon = Icons.tour;
        break;
      case 'completed':
        message = 'No completed tours';
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        message = 'No rejected applications';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'No tour notifications';
        icon = Icons.notifications_none;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
                          color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new tour opportunities',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTourNotificationCard(BuildContext context, Map<String, dynamic> notification) {
    // Determine status and styling
    String status = notification['status'] as String;
    String category = 'pending';
    Color statusColor = AppTheme.primaryBlue;
    IconData statusIcon = Icons.pending;
    
    DateTime now = DateTime.now();
    DateTime? startDate = notification['startDate'] as DateTime?;
    DateTime? endDate = notification['endDate'] as DateTime?;
    
    String statusText = 'Pending';
    if (status == 'accepted') {
      category = 'pending';
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = 'Accepted - Waiting for Tourist';
    } else if (status == 'started') {
      if (endDate != null && now.isAfter(endDate)) {
        category = 'completed';
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
      } else {
        category = 'ongoing';
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.play_circle;
        statusText = 'Trip Started';
      }
    } else if (status == 'completed') {
      category = 'completed';
      statusColor = AppTheme.primaryBlue;
      statusIcon = Icons.check_circle;
      statusText = 'Completed';
    } else if (status == 'rejected') {
      category = 'rejected';
      statusColor = AppTheme.errorRed;
      statusIcon = Icons.cancel;
      statusText = 'Rejected';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
      ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatNotificationTime(notification['notificationTime'] as DateTime?),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Tourist info
          Row(
            children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                          shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.secondaryOrange],
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    Text(
                      notification['touristName'] ?? 'Unknown Tourist',
                      style: const TextStyle(
                          fontSize: 16,
                        fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    Text(
                      notification['touristEmail'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
                      ),
                  ],
                ),
          
          const SizedBox(height: 16),
          
          // Trip details
                Text(
            notification['description'] ?? 'Tour Request',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Location and date
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                notification['location'] ?? 'Unknown Location',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                startDate != null 
                    ? '${startDate.day}/${startDate.month}/${startDate.year}'
                    : 'TBD',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          
                const SizedBox(height: 8),
          
          // Duration and participants
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
                Text(
                notification['duration'] ?? 'TBD',
                  style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${notification['adults'] ?? 0} adults, ${notification['children'] ?? 0} children',
                style: const TextStyle(
                  fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
          ),
          
          const SizedBox(height: 12),
          
          // Budget
          Row(
            children: [
              Icon(Icons.attach_money, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Budget: ${notification['budget'] ?? 'Not specified'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          
          if (notification['additionalInfo'] != null && notification['additionalInfo'].isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Additional Info: ${notification['additionalInfo']}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          // Action buttons based on status
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleTourAction(context, notification, 'withdraw'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.errorRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Withdraw',
                      style: TextStyle(color: AppTheme.errorRed),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleTourAction(context, notification, 'view'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (status == 'accepted') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleTourAction(context, notification, 'contact'),
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Contact Tourist'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleTourAction(context, notification, 'view'),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleTourAction(context, notification, 'view'),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatNotificationTime(DateTime? time) {
    if (time == null) return 'Unknown time';
    
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _handleTourAction(BuildContext context, Map<String, dynamic> notification, String action) {
    switch (action) {
      case 'withdraw':
        _showWithdrawConfirmation(context, notification);
        break;
      case 'view':
        _showTourDetails(context, notification);
        break;
      case 'contact':
        _contactTourist(context, notification);
        break;
    }
  }

  void _showWithdrawConfirmation(BuildContext context, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Application'),
        content: Text('Are you sure you want to withdraw your application for "${notification['description']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _withdrawApplication(context, notification['applicationId']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Withdraw', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTourDetails(BuildContext context, Map<String, dynamic> notification) {
    // Show detailed tour information in a dialog or navigate to detail page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['description'] ?? 'Tour Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Location', notification['location'] ?? 'Not specified'),
              _buildDetailRow('Date', notification['startDate'] != null 
                  ? '${notification['startDate'].day}/${notification['startDate'].month}/${notification['startDate'].year}'
                  : 'Not specified'),
              _buildDetailRow('Duration', notification['duration'] ?? 'Not specified'),
              _buildDetailRow('Participants', '${notification['adults'] ?? 0} adults, ${notification['children'] ?? 0} children'),
              _buildDetailRow('Budget', notification['budget'] ?? 'Not specified'),
              if (notification['additionalInfo'] != null)
                _buildDetailRow('Additional Info', notification['additionalInfo']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _contactTourist(BuildContext context, Map<String, dynamic> notification) {
    // Implement contact functionality (email, phone, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact functionality will be implemented'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  Future<void> _withdrawApplication(BuildContext context, String applicationId) async {
    try {
      await FirebaseService().deleteTripApplication(applicationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application withdrawn successfully'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error withdrawing application: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}

class GuideOngoingPage extends StatefulWidget {
  const GuideOngoingPage({Key? key}) : super(key: key);

  @override
  State<GuideOngoingPage> createState() => _GuideOngoingPageState();
}

class _GuideOngoingPageState extends State<GuideOngoingPage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _ongoingTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOngoingTrips();
  }

  Future<void> _loadOngoingTrips() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _firebaseService.getCurrentUser();
      if (user != null) {
        List<Map<String, dynamic>> trips = await _firebaseService.getGuideOngoingTrips(user.uid);
        setState(() {
          _ongoingTrips = trips;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading ongoing trips: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trips: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Ongoing Trips',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOngoingTrips,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _ongoingTrips.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadOngoingTrips,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Trip Applications',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Track your accepted, started, and completed trips',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ..._ongoingTrips.map((trip) => _buildOngoingTripCard(trip)).toList(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_run_outlined,
              size: 80,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No Ongoing Trips',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any accepted trips yet.\nApply to trips to see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to trips page
                DefaultTabController.of(context)?.animateTo(1);
              },
              icon: const Icon(Icons.search),
              label: const Text('Browse Trips'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingTripCard(Map<String, dynamic> trip) {
    String status = trip['status'] ?? 'unknown';
    String statusText = _getStatusText(status);
    Color statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with tourist info and status
          Row(
            children: [
              // Tourist Avatar
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.secondaryOrange],
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              
              // Tourist Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip['touristName'] ?? 'Unknown Tourist',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      trip['touristEmail'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Trip Details
          Text(
            trip['title'] ?? 'Untitled Trip',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Location and Date
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trip['location'] ?? 'Unknown Location',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatDate(trip['startDate']),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Duration and Participants
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                trip['duration'] ?? 'Unknown Duration',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${trip['participants'] ?? 'Unknown'} participants',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'started':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppTheme.primaryBlue;
      case 'started':
        return AppTheme.secondaryOrange;
      case 'completed':
        return AppTheme.successGreen;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Date TBD';
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Date TBD';
  }
}
        'location': 'Sigiriya',
        'date': 'Dec 25, 2024',
        'time': '9:00 AM',
        'duration': '4 hours',
        'participants': 8,
        'budget': 'LKR 15,000',
        'description': 'Looking for an experienced guide to explore Sigiriya Rock Fortress. We are a group of 8 people interested in learning about the ancient history and architecture.',
        'specialRequirements': ['English speaking guide', 'Photography assistance'],
        'status': 'Open for Bidding',
        'postedTime': '2 hours ago',
        'bidsCount': 3,
      },
      {
        'id': '2',
        'touristName': 'Michael Rodriguez',
        'touristImage': null,
        'tripTitle': 'Ella Nine Arch Bridge Tour',
        'location': 'Ella',
        'date': 'Dec 28, 2024',
        'time': '8:00 AM',
        'duration': '6 hours',
        'participants': 5,
        'budget': 'LKR 12,000',
        'description': 'Want to visit the famous Nine Arch Bridge and surrounding tea plantations. Need a guide who knows the best photography spots.',
        'specialRequirements': ['Photography guide', 'Tea plantation visit'],
        'status': 'Open for Bidding',
        'postedTime': '5 hours ago',
        'bidsCount': 7,
      },
      {
        'id': '3',
        'touristName': 'Sarah Johnson',
        'touristImage': null,
        'tripTitle': 'Kandy Temple & Cultural Tour',
        'location': 'Kandy',
        'date': 'Dec 30, 2024',
        'time': '2:00 PM',
        'duration': '3 hours',
        'participants': 6,
        'budget': 'LKR 10,000',
        'description': 'Cultural tour of Kandy including Temple of the Tooth and local markets. Interested in learning about Buddhist culture.',
        'specialRequirements': ['Cultural knowledge', 'Market tour'],
        'status': 'Open for Bidding',
        'postedTime': '1 day ago',
        'bidsCount': 4,
      },
      {
        'id': '4',
        'touristName': 'David Chen',
        'touristImage': null,
        'tripTitle': 'Galle Fort Heritage Walk',
        'location': 'Galle',
        'date': 'Jan 2, 2025',
        'time': '10:00 AM',
        'duration': '3 hours',
        'participants': 4,
        'budget': 'LKR 8,000',
        'description': 'Heritage walk through Galle Fort with focus on colonial architecture and local history.',
        'specialRequirements': ['Historical knowledge', 'Architecture focus'],
        'status': 'Open for Bidding',
        'postedTime': '2 days ago',
        'bidsCount': 2,
      },
      {
        'id': '5',
        'touristName': 'Maria Garcia',
        'touristImage': null,
        'tripTitle': 'Mirissa Whale Watching',
        'location': 'Mirissa',
        'date': 'Jan 5, 2025',
        'time': '6:00 AM',
        'duration': '5 hours',
        'participants': 12,
        'budget': 'LKR 20,000',
        'description': 'Early morning whale watching tour. Need a guide who can help with marine life identification and photography.',
        'specialRequirements': ['Marine biology knowledge', 'Early morning availability'],
        'status': 'Open for Bidding',
        'postedTime': '3 days ago',
        'bidsCount': 5,
      },
    ];

    return Column(
      children: tripRequests.map((request) => _buildTripRequestCard(request)).toList(),
    );
  }

  Widget _buildTripRequestCard(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with tourist info
          Row(
            children: [
              // Tourist Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.secondaryOrange],
                  ),
                ),
                child: request['touristImage'] != null
                    ? ClipOval(
                        child: Image.network(
                          request['touristImage'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 25,
                      ),
              ),
              const SizedBox(width: 12),
              
              // Tourist Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['touristName'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      request['postedTime'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request['status'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successGreen,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Trip Details
          Text(
            request['tripTitle'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Location and Date
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                request['location'],
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${request['date']} at ${request['time']}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Duration and Participants
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  request['duration'],
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${request['participants']} people',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Description
          Text(
            request['description'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          
          // Special Requirements
          if (request['specialRequirements'].isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: request['specialRequirements'].map<Widget>((requirement) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    requirement,
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          
          // Budget and Bids Info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      request['budget'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Bids Received',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${request['bidsCount']} bids',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showTripDetails(request),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(color: AppTheme.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _submitBid(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Submit Bid'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    List<Widget> bookings = [];
    
    if (_selectedTab == 1) { // My Bookings
      bookings = [
        _buildBookingCard(
          title: 'Sigiriya Rock Fortress Tour',
          date: 'Today, 2:00 PM',
          duration: '4 hours',
          participants: '8 people',
          price: 'Rs. 12,000',
          status: 'Confirmed',
          isConfirmed: true,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          title: 'Ella Nine Arch Bridge Adventure',
          date: 'Tomorrow, 9:00 AM',
          duration: '6 hours',
          participants: '5 people',
          price: 'Rs. 15,000',
          status: 'Pending',
          isConfirmed: false,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          title: 'Mirissa Whale Watching Tour',
          date: 'Dec 18, 2024',
          duration: '5 hours',
          participants: '12 people',
          price: 'Rs. 18,000',
          status: 'Completed',
          isConfirmed: true,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          title: 'Trincomalee Beach & Temple Tour',
          date: 'Dec 20, 2024',
          duration: '3 hours',
          participants: '6 people',
          price: 'Rs. 10,500',
          status: 'Confirmed',
          isConfirmed: true,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          title: 'Kandy Temple of the Tooth',
          date: 'Dec 22, 2024',
          duration: '3 hours',
          participants: '10 people',
          price: 'Rs. 9,000',
          status: 'Pending',
          isConfirmed: false,
        ),
      ];
    } else if (_selectedTab == 1) { // Upcoming bookings
      bookings = [
        _buildBookingCard(
          title: 'Sigiriya Rock Fortress Tour',
          date: 'Today, 2:00 PM',
          duration: '4 hours',
          participants: '8 people',
          price: 'Rs. 12,000',
          status: 'Confirmed',
          isConfirmed: true,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          title: 'Ella Nine Arch Bridge Adventure',
          date: 'Tomorrow, 9:00 AM',
          duration: '6 hours',
          participants: '5 people',
          price: 'Rs. 15,000',
          status: 'Pending',
          isConfirmed: false,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          title: 'Trincomalee Beach & Temple Tour',
          date: 'Dec 20, 2024',
          duration: '3 hours',
          participants: '6 people',
          price: 'Rs. 10,500',
          status: 'Confirmed',
          isConfirmed: true,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          title: 'Kandy Temple of the Tooth',
          date: 'Dec 22, 2024',
          duration: '3 hours',
          participants: '10 people',
          price: 'Rs. 9,000',
          status: 'Pending',
          isConfirmed: false,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          title: 'Galle Fort Heritage Walk',
          date: 'Dec 25, 2024',
          duration: '3 hours',
          participants: '7 people',
          price: 'Rs. 8,500',
          status: 'Confirmed',
          isConfirmed: true,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          title: 'Nuwara Eliya Tea Plantation Tour',
          date: 'Dec 28, 2024',
          duration: '4 hours',
          participants: '9 people',
          price: 'Rs. 11,000',
          status: 'Pending',
          isConfirmed: false,
        ),
      ];
    } else { // Completed bookings
      bookings = [
        _buildBookingCard(
          title: 'Mirissa Whale Watching Tour',
          date: 'Dec 18, 2024',
          duration: '5 hours',
          participants: '12 people',
          price: 'Rs. 18,000',
          status: 'Completed',
          isConfirmed: true,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          title: 'Anuradhapura Ancient City Tour',
          date: 'Dec 15, 2024',
          duration: '6 hours',
          participants: '6 people',
          price: 'Rs. 14,000',
          status: 'Completed',
          isConfirmed: true,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          title: 'Polonnaruwa Archaeological Site',
          date: 'Dec 12, 2024',
          duration: '5 hours',
          participants: '8 people',
          price: 'Rs. 13,500',
          status: 'Completed',
          isConfirmed: true,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          title: 'Yala National Park Safari',
          date: 'Dec 10, 2024',
          duration: '8 hours',
          participants: '4 people',
          price: 'Rs. 20,000',
          status: 'Completed',
          isConfirmed: true,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          title: 'Bentota Beach & Water Sports',
          date: 'Dec 8, 2024',
          duration: '4 hours',
          participants: '10 people',
          price: 'Rs. 16,000',
          status: 'Completed',
          isConfirmed: true,
        ),
      ];
    }
    
    return Column(children: bookings);
  }

  void _showTripDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(request['tripTitle']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tourist: ${request['touristName']}'),
            Text('Location: ${request['location']}'),
            Text('Date: ${request['date']} at ${request['time']}'),
            Text('Duration: ${request['duration']}'),
            Text('Participants: ${request['participants']} people'),
            Text('Budget: ${request['budget']}'),
            const SizedBox(height: 8),
            const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(request['description']),
            if (request['specialRequirements'].isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Special Requirements:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...request['specialRequirements'].map((req) => Text('• $req')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitBid(request);
            },
            child: const Text('Submit Bid'),
          ),
        ],
      ),
    );
  }

  void _submitBid(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Bid'),
        content: const Text('Bid submission feature coming soon! You will be able to submit your bid with your proposed rate and message.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard({
    required String title,
    required String date,
    required String duration,
    required String participants,
    required String price,
    required String status,
    required bool isConfirmed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isConfirmed 
                      ? AppTheme.successGreen.withOpacity(0.1)
                      : AppTheme.warningYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isConfirmed 
                        ? AppTheme.successGreen
                        : AppTheme.warningYellow,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      participants,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


