import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'signin_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_page.dart';
import 'create_profile_page.dart';
import 'guide_trips_page.dart';
import 'guide_notifications_page.dart';
import 'trip_application_form.dart';
import 'theme/app_theme.dart';
import 'components/notification_badge.dart';
import 'components/verification_badge.dart';

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
    const OngoingTripsPage(),
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
              icon: Icon(Icons.book_online_outlined),
              activeIcon: Icon(Icons.book_online),
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

class HomeContent extends StatefulWidget {
  final BuildContext parentContext;
  
  const HomeContent({Key? key, required this.parentContext}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  int _reviewCount = 0;
  bool _isLoadingReviews = true;
  String? _profileImageUrl;
  
  // Notification state
  Map<String, List<Map<String, dynamic>>> _notifications = {
    'urgent': [],
    'tours': [],
    'reviews': [],
    'payments': [],
    'reminders': [],
    'system': [],
  };
  int _totalUnreadCount = 0;
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadReviewsData();
    _initializeNotifications();
  }

  Future<void> _loadReviewsData() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;

      print('🔍 Loading reviews and profile data for guide: ${user.uid}');
      
      // Fetch reviews, average rating, and review count
      final reviews = await _firebaseService.getGuideReviews(user.uid);
      final averageRating = await _firebaseService.getGuideAverageRating(user.uid);
      final reviewCount = await _firebaseService.getGuideReviewCount(user.uid);
      
      // Fetch profile data to get profile image URL
      final profileData = await _firebaseService.getUserProfile(user.uid);
      final profileImageUrl = profileData?['profileImageUrl'];
      
      print('📊 Reviews loaded: ${reviews.length} reviews, avg: $averageRating, count: $reviewCount');
      print('📸 Profile image URL: $profileImageUrl');
      
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = averageRating;
          _reviewCount = reviewCount;
          _profileImageUrl = profileImageUrl;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('❌ Error loading reviews: $e');
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;

      print('🔔 Initializing notifications for guide: ${user.uid}');
      
      // Initialize notification service
      await _notificationService.initialize();
      
      // Subscribe to user-specific topics
      await _notificationService.subscribeToUserTopics(user.uid, 'Tour Guide');
      
      // Load notifications
      await _loadNotifications();
      
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;

      print('🔔 Loading notifications for guide: ${user.uid}');
      
      // Get comprehensive notifications
      Map<String, List<Map<String, dynamic>>> notifications = 
          await _firebaseService.getComprehensiveGuideNotifications(user.uid);
      
      // Calculate total unread count
      int totalUnread = 0;
      for (var category in notifications.values) {
        for (var notification in category) {
          if (!(notification['isRead'] ?? false)) {
            totalUnread++;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _totalUnreadCount = totalUnread;
          _isLoadingNotifications = false;
        });
      }
      
      print('📊 Loaded ${notifications.values.expand((x) => x).length} notifications');
      print('🔴 Total unread: $totalUnread');
      
    } catch (e) {
      print('❌ Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
  }

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: _profileImageUrl != null
                ? Image.network(
                    _profileImageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      );
                    },
                  )
                : const Icon(
            Icons.person,
            color: Colors.white,
            size: 30,
                  ),
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
                        final String verificationStatus = (data?['verificationStatus'] as String?) ?? 'pending';
                        return UserNameWithVerification(
                          name: name,
                          verificationStatus: verificationStatus,
                          nameStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          badgeSize: 16,
                          showBadgeText: true,
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
              NotificationIcon(
                count: _totalUnreadCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GuideNotificationsPage(),
                    ),
                  );
                },
                icon: Icons.notifications_outlined,
                iconColor: AppTheme.textPrimary,
                iconSize: 20,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'settings') {
                    // Navigate to Settings tab
                    Navigator.push(
                      widget.parentContext,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  } else if (value == 'logout') {
                    try {
                      await FirebaseService().signOut();
                      if (widget.parentContext.mounted) {
                        Navigator.pushAndRemoveUntil(
                          widget.parentContext,
                          MaterialPageRoute(builder: (context) => const SigninPage()),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (widget.parentContext.mounted) {
                        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
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
                  widget.parentContext,
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
    if (_isLoadingReviews) {
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          ),
        ],
      );
    }

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
                      Text(
                        _averageRating > 0 ? _averageRating.toStringAsFixed(1) : '0.0',
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
                  Text(
                    'Based on $_reviewCount reviews',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 20),
              
              // Rating Bars
              Expanded(
                child: _reviewCount > 0 ? _buildRatingBars() : _buildNoReviewsMessage(),
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
        
        // Show recent reviews or no reviews message
        if (_reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Center(
              child: Text(
                'No reviews yet. Complete trips to start receiving reviews!',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Column(
            children: [
              // Show up to 2 recent reviews
              ...(_reviews.take(2).map((review) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildReviewCard(review),
              ))),
              
              if (_reviews.length > 2)
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
        ),
      ],
    );
  }

  Widget _buildRatingBars() {
    // Calculate rating distribution
    Map<int, int> ratingCounts = {};
    for (var review in _reviews) {
      int rating = review['rating'] as int;
      ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
    }

    return Column(
      children: [
        _buildRatingBar(5, ratingCounts[5] ?? 0),
        _buildRatingBar(4, ratingCounts[4] ?? 0),
        _buildRatingBar(3, ratingCounts[3] ?? 0),
        _buildRatingBar(2, ratingCounts[2] ?? 0),
        _buildRatingBar(1, ratingCounts[1] ?? 0),
      ],
    );
  }

  Widget _buildNoReviewsMessage() {
    return const Center(
      child: Text(
        'No reviews yet',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count) {
    double percentage = _reviewCount > 0 ? count / _reviewCount : 0.0;
    
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
            '$count',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    String touristName = review['touristName'] ?? 'Anonymous';
    int rating = review['rating'] as int;
    String reviewText = review['reviewText'] ?? '';
    DateTime createdAt = review['createdAt'] as DateTime;
    String tripTitle = review['tripTitle'] ?? 'Trip';
    
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
                      touristName,
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
                          _getTimeAgo(createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
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
            reviewText,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trip: $tripTitle',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
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


  Widget _buildQuickStats() {
    return Center(
      child: _buildStatCard(
        icon: Icons.star,
        title: 'Rating',
        value: _averageRating > 0 ? _averageRating.toStringAsFixed(1) : '0.0',
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
    if (_reviews.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No reviews available'),
          backgroundColor: AppTheme.warningYellow,
        ),
      );
      return;
    }

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
                  Text(
                    'All Reviews (${_reviews.length})',
                    style: const TextStyle(
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
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildReviewCard(review),
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

class OngoingTripsPage extends StatefulWidget {
  const OngoingTripsPage({Key? key}) : super(key: key);

  @override
  State<OngoingTripsPage> createState() => _OngoingTripsPageState();
}

class _OngoingTripsPageState extends State<OngoingTripsPage> {
  int _selectedTab = 0; // 0: Trip Requests, 1: Ongoing Trips, 2: Completed
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _ongoingTrips = [];
  List<Map<String, dynamic>> _completedTrips = [];
  List<Map<String, dynamic>> _tripRequests = [];
  bool _isLoading = false;
  bool _isLoadingCompleted = false;
  bool _isLoadingTripRequests = false;

  @override
  void initState() {
    super.initState();
    _loadOngoingTrips();
    _loadCompletedTrips();
    _loadTripRequests();
  }

  Future<void> _loadOngoingTrips() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _firebaseService.getCurrentUser();
      if (currentUser != null) {
        final trips = await _firebaseService.getGuideOngoingTrips(currentUser.uid);
        if (mounted) {
          setState(() {
            _ongoingTrips = trips;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading ongoing trips: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading ongoing trips: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _loadCompletedTrips() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingCompleted = true;
    });

    try {
      final currentUser = _firebaseService.getCurrentUser();
      if (currentUser != null) {
        final trips = await _firebaseService.getGuideCompletedTrips(currentUser.uid);
        if (mounted) {
          setState(() {
            _completedTrips = trips;
            _isLoadingCompleted = false;
          });
        }
      }
    } catch (e) {
      print('Error loading completed trips: $e');
      if (mounted) {
        setState(() {
          _isLoadingCompleted = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading completed trips: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _loadTripRequests() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingTripRequests = true;
    });

    try {
      final trips = await _firebaseService.getAllAvailableTrips();
      if (mounted) {
        setState(() {
          _tripRequests = trips;
          _isLoadingTripRequests = false;
        });
      }
    } catch (e) {
      print('Error loading trip requests: $e');
      if (mounted) {
        setState(() {
          _isLoadingTripRequests = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trip requests: $e'),
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Tabs
              _buildFilterTabs(),
              const SizedBox(height: 20),
              
              // Content based on selected tab
              _selectedTab == 0 ? _buildTripRequestsList() : 
              _selectedTab == 1 ? _buildOngoingTripsList() : _buildBookingsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? AppTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Trip Requests',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTab == 0 ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? AppTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ongoing Trips',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTab == 1 ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 2 ? AppTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Completed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTab == 2 ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripRequestsList() {
    if (_isLoadingTripRequests) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
        ),
      );
    }

    if (_tripRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Trip Requests Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no trip requests available at the moment.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTripRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTripRequests,
      color: AppTheme.primaryBlue,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _tripRequests.length,
        itemBuilder: (context, index) {
          final trip = _tripRequests[index];
          return _buildTripRequestCard(trip);
        },
      ),
    );
  }

  Widget _buildTripRequestCard(Map<String, dynamic> trip) {
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
                child: trip['touristImage'] != null
                    ? ClipOval(
                        child: Image.network(
                          trip['touristImage'],
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
                      trip['touristName'] ?? 'Unknown Tourist',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Trip Request',
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
                  'Available',
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
              Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                trip['location'] ?? 'Location not specified',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                _formatDate(trip['startDate'] as DateTime?),
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
                  'Trip Duration',
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
                  '${trip['maxParticipants'] ?? 0} max people',
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
            trip['description'] ?? 'No description provided',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          
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
                      trip['budget'] ?? 'Budget not specified',
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
                      '0 bids',
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
                  onPressed: () => _showTripDetails(trip),
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
                  onPressed: () => _applyForTrip(trip),
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

  Widget _buildOngoingTripsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
        ),
      );
    }

    if (_ongoingTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trip_origin_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Ongoing Trips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any ongoing trips at the moment.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOngoingTrips,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOngoingTrips,
      color: AppTheme.primaryBlue,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _ongoingTrips.length,
        itemBuilder: (context, index) {
          final trip = _ongoingTrips[index];
          return _buildOngoingTripCard(trip);
        },
      ),
    );
  }

  Widget _buildOngoingTripCard(Map<String, dynamic> trip) {
    String status = trip['status'] ?? 'unknown';
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'accepted':
        statusColor = Colors.orange;
        statusText = 'Accepted';
        break;
      case 'started':
        statusColor = Colors.green;
        statusText = 'Started';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Completed';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trip['title'] ?? 'Untitled Trip',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
        const SizedBox(height: 12),
            
            // Tourist Info
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  backgroundImage: trip['touristImage'] != null 
                      ? NetworkImage(trip['touristImage']) 
                      : null,
                  child: trip['touristImage'] == null 
                      ? Icon(Icons.person, size: 16, color: AppTheme.primaryBlue)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['touristName'] ?? 'Unknown Tourist',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        trip['touristEmail'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
        ),
        const SizedBox(height: 12),
            
            // Trip Details
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  trip['startDate'] != null 
                      ? '${(trip['startDate'] as DateTime).day}/${(trip['startDate'] as DateTime).month}/${(trip['startDate'] as DateTime).year}'
                      : 'Date TBD',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  trip['duration'] ?? 'Duration TBD',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trip['location'] ?? 'Location TBD',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  trip['price'] ?? 'Price TBD',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            
            // Action Button
            if (status == 'accepted') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement start trip functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Start trip functionality coming soon!'),
                        backgroundColor: AppTheme.primaryBlue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    if (_selectedTab == 2) { // Completed Trips
      return _buildCompletedTripsList();
    } else {
      // For other tabs, return empty state or placeholder
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }
  }

  Widget _buildCompletedTripsList() {
    if (_isLoadingCompleted) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
        ),
      );
    }

    if (_completedTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Completed Trips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any completed trips yet.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCompletedTrips,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCompletedTrips,
      color: AppTheme.primaryBlue,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _completedTrips.length,
        itemBuilder: (context, index) {
          final trip = _completedTrips[index];
          return _buildCompletedTripCard(trip);
        },
      ),
    );
  }

  Widget _buildCompletedTripCard(Map<String, dynamic> trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(trip['endDate'] as DateTime?),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            
        const SizedBox(height: 12),
            
            // Trip title
            Text(
              trip['title'] ?? 'Untitled Trip',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Tourist info
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.secondaryOrange],
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['touristName'] ?? 'Unknown Tourist',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Completed Trip',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
        const SizedBox(height: 12),
            
            // Trip details
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip['location'] ?? 'Location not specified',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(trip['startDate'] as DateTime?)} - ${_formatDate(trip['endDate'] as DateTime?)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date not set';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _applyForTrip(Map<String, dynamic> trip) {
    // Navigate to trip application form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripApplicationForm(trip: trip),
      ),
    );
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

