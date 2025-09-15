import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services/firebase_service.dart';
import 'signin_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'tourist_trips.dart';
import 'tourist_ongoing_page.dart';
import 'components/verification_badge.dart';

class TouristHomePage extends StatefulWidget {
  const TouristHomePage({Key? key}) : super(key: key);

  @override
  State<TouristHomePage> createState() => _TouristHomePageState();
}

class _TouristHomePageState extends State<TouristHomePage> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const TouristHomeContent(),
    const TouristOngoingPage(),
    const TouristTrips(),
    const TouristProfilePage(),
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
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Ongoing',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trip_origin_outlined),
              activeIcon: Icon(Icons.trip_origin),
              label: 'My Trip',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class TouristHomeContent extends StatefulWidget {
  const TouristHomeContent({Key? key}) : super(key: key);

  @override
  State<TouristHomeContent> createState() => _TouristHomeContentState();
}

class _TouristHomeContentState extends State<TouristHomeContent> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _profileImageUrl;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;

      print('🔍 Loading profile data for tourist: ${user.uid}');
      
      final profileData = await _firebaseService.getUserProfile(user.uid);
      
      if (mounted) {
        setState(() {
          _profileImageUrl = profileData?['profileImageUrl'];
          _isLoadingProfile = false;
        });
      }
      
      print('📸 Tourist profile image URL: $_profileImageUrl');
    } catch (e) {
      print('❌ Error loading tourist profile data: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
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
              _buildHeader(context),
              const SizedBox(height: 30),
              
              // Categories
              _buildCategories(context),
              const SizedBox(height: 30),
              
              // Recent Bookings
              _buildRecentBookings(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                        final String name = (data?['name'] as String?) ?? 'Tourist';
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
              Text(
                'Ready for your next adventure?',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
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
                  _showNotifications(context);
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'logout') {
                    try {
                      await FirebaseService().signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const SigninPage()),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to log out: ${e.toString()}'),
                            backgroundColor: AppTheme.errorRed,
                          ),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
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





  Widget _buildCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2d3748),
          ),
        ),
        const SizedBox(height: 15),
         Row(
           children: [
             Expanded(
               child: _buildCategoryCard(
                 context: context,
                 icon: Icons.hiking,
                 title: 'Wildlife',
                 color: const Color(0xFF667eea),
               ),
             ),
             const SizedBox(width: 12),
             Expanded(
               child: _buildCategoryCard(
                 context: context,
                 icon: Icons.history,
                 title: 'Heritage',
                 color: const Color(0xFF48bb78),
               ),
             ),
             const SizedBox(width: 12),
             Expanded(
               child: _buildCategoryCard(
                 context: context,
                 icon: Icons.waves,
                 title: 'Beaches',
                 color: const Color(0xFFed8936),
               ),
             ),
           ],
         ),
         const SizedBox(height: 12),
         Row(
           children: [
             Expanded(
               child: _buildCategoryCard(
                 context: context,
                 icon: Icons.landscape,
                 title: 'Tea Country',
                 color: const Color(0xFF38a169),
               ),
             ),
             const SizedBox(width: 12),
             Expanded(
               child: _buildCategoryCard(
                 context: context,
                 icon: Icons.restaurant,
                 title: 'Local Food',
                 color: const Color(0xFFd69e2e),
               ),
             ),
             const SizedBox(width: 12),
             Expanded(
               child: _buildCategoryCard(
                 context: context,
                 icon: Icons.temple_buddhist,
                 title: 'Spiritual',
                 color: const Color(0xFF805ad5),
               ),
             ),
           ],
         ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        _showCategoryTours(context, title);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
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
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2d3748),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3748),
              ),
            ),
             TextButton(
               onPressed: () {
                 _showAllBookings(context);
               },
               child: const Text(
                 'View All',
                 style: TextStyle(
                   color: Color(0xFF667eea),
                   fontWeight: FontWeight.w600,
                 ),
               ),
             ),
          ],
        ),
        const SizedBox(height: 15),
        _buildBookingCard(
          tour: 'Sigiriya Rock Fortress Tour',
          date: 'Dec 15, 2024',
          status: 'Confirmed',
          isConfirmed: true,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          tour: 'Ella Nine Arch Bridge Adventure',
          date: 'Dec 20, 2024',
          status: 'Pending',
          isConfirmed: false,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          tour: 'Mirissa Whale Watching',
          date: 'Dec 25, 2024',
          status: 'Confirmed',
          isConfirmed: true,
        ),
      ],
    );
  }

  Widget _buildBookingCard({
    required String tour,
    required String date,
    required String status,
    required bool isConfirmed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.explore,
              color: Color(0xFF667eea),
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tour,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2d3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isConfirmed 
                  ? const Color(0xFF48bb78).withOpacity(0.1)
                  : const Color(0xFFed8936).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isConfirmed 
                    ? const Color(0xFF48bb78)
                    : const Color(0xFFed8936),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showNotifications(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Booking Confirmed',
        'message': 'Your Sigiriya Rock Fortress tour has been confirmed for Dec 15, 2024',
        'time': '2 minutes ago',
        'type': 'booking',
        'isRead': false,
        'icon': Icons.check_circle,
        'color': Color(0xFF48bb78),
      },
      {
        'title': 'Payment Successful',
        'message': 'Payment of Rs. 8,500 for Sigiriya tour has been processed',
        'time': '1 hour ago',
        'type': 'payment',
        'isRead': false,
        'icon': Icons.payment,
        'color': Color(0xFF48bb78),
      },
      {
        'title': 'Tour Reminder',
        'message': 'Your Ella Nine Arch Bridge tour starts tomorrow at 9:00 AM',
        'time': '3 hours ago',
        'type': 'reminder',
        'isRead': true,
        'icon': Icons.schedule,
        'color': Color(0xFFed8936),
      },
      {
        'title': 'New Tour Available',
        'message': 'Check out the new Mirissa Whale Watching tour with special rates',
        'time': '1 day ago',
        'type': 'promotion',
        'isRead': true,
        'icon': Icons.local_offer,
        'color': Color(0xFF667eea),
      },
      {
        'title': 'Weather Update',
        'message': 'Perfect weather conditions for your upcoming beach tour in Galle',
        'time': '2 days ago',
        'type': 'weather',
        'isRead': true,
        'icon': Icons.wb_sunny,
        'color': Color(0xFFed8936),
      },
      {
        'title': 'Welcome to Sri Lanka!',
        'message': 'Thank you for choosing our platform. Explore amazing destinations!',
        'time': '3 days ago',
        'type': 'welcome',
        'isRead': true,
        'icon': Icons.celebration,
        'color': Color(0xFF667eea),
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
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2d3748),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Mark all as read functionality
                    },
                    child: const Text(
                      'Mark all as read',
                      style: TextStyle(
                        color: Color(0xFF667eea),
                        fontWeight: FontWeight.w600,
                      ),
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
            
            // Notifications List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationCard(notification);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification['isRead'] ? Colors.white : const Color(0xFFf7fafc),
        borderRadius: BorderRadius.circular(12),
        border: notification['isRead'] 
            ? null 
            : Border.all(color: const Color(0xFF667eea).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: notification['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              notification['icon'],
              color: notification['color'],
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Notification Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: notification['isRead'] ? FontWeight.w500 : FontWeight.w600,
                          color: const Color(0xFF2d3748),
                        ),
                      ),
                    ),
                    if (!notification['isRead'])
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF667eea),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification['message'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification['time'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _showAllToursOld(BuildContext context) {
    final List<Map<String, dynamic>> allTours = [
      {
        'title': 'Sigiriya Rock Fortress',
        'location': 'Sigiriya',
        'rating': 4.8,
        'price': 'Rs. 8,500',
        'duration': '4 hours',
        'image': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        'description': 'Explore the ancient rock fortress and UNESCO World Heritage site',
      },
      {
        'title': 'Ella Nine Arch Bridge',
        'location': 'Ella',
        'rating': 4.9,
        'price': 'Rs. 12,000',
        'duration': '6 hours',
        'image': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        'description': 'Walk across the iconic railway bridge surrounded by tea plantations',
      },
      {
        'title': 'Kandy Temple of the Tooth',
        'location': 'Kandy',
        'rating': 4.7,
        'price': 'Rs. 6,500',
        'duration': '3 hours',
        'image': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        'description': 'Visit the sacred Buddhist temple housing the tooth relic of Buddha',
      },
      {
        'title': 'Mirissa Whale Watching',
        'location': 'Mirissa',
        'rating': 4.6,
        'price': 'Rs. 15,000',
        'duration': '5 hours',
        'image': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        'description': 'Spot blue whales and dolphins in their natural habitat',
      },
      {
        'title': 'Galle Fort Heritage Walk',
        'location': 'Galle',
        'rating': 4.8,
        'price': 'Rs. 7,500',
        'duration': '3 hours',
        'image': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        'description': 'Discover the colonial architecture and history of Galle Fort',
      },
      {
        'title': 'Anuradhapura Ancient City',
        'location': 'Anuradhapura',
        'rating': 4.7,
        'price': 'Rs. 9,000',
        'duration': '5 hours',
        'image': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        'description': 'Explore the ancient capital with its sacred Bodhi tree and stupas',
      },
      {
        'title': 'Yala National Park Safari',
        'location': 'Yala',
        'rating': 4.9,
        'price': 'Rs. 18,000',
        'duration': '8 hours',
        'image': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        'description': 'Wildlife safari to spot leopards, elephants, and diverse birdlife',
      },
      {
        'title': 'Nuwara Eliya Tea Country',
        'location': 'Nuwara Eliya',
        'rating': 4.5,
        'price': 'Rs. 10,000',
        'duration': '4 hours',
        'image': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        'description': 'Visit tea plantations and learn about Ceylon tea production',
      },
      {
        'title': 'Trincomalee Beach & Temple',
        'location': 'Trincomalee',
        'rating': 4.6,
        'price': 'Rs. 11,000',
        'duration': '4 hours',
        'image': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        'description': 'Relax on pristine beaches and visit the historic Koneswaram Temple',
      },
      {
        'title': 'Dambulla Cave Temple',
        'location': 'Dambulla',
        'rating': 4.7,
        'price': 'Rs. 8,000',
        'duration': '3 hours',
        'image': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        'description': 'Explore the largest cave temple complex with ancient Buddhist murals',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                    'All Tours in Sri Lanka',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2d3748),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Tours Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: allTours.length,
                itemBuilder: (context, index) {
                  final tour = allTours[index];
                  return _buildAllToursCard(tour);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllToursCard(Map<String, dynamic> tour) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tour Image
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: DecorationImage(
                image: NetworkImage(tour['image']),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          tour['rating'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tour Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tour['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2d3748),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        tour['location'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        tour['duration'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        tour['price'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryTours(BuildContext context, String category) {
    Map<String, List<String>> categoryPlaces = {
      'Wildlife': [
        'Yala National Park',
        'Udawalawe National Park',
        'Minneriya National Park',
        'Sinharaja Rainforest',
        'Wilpattu National Park',
        'Bundala National Park',
        'Kumana National Park',
        'Gal Oya National Park',
        'Horton Plains National Park',
        'Pinnawala Elephant Orphanage',
        'Udawalawe Elephant Transit Home',
        'Wasgamuwa National Park',
        'Maduru Oya National Park',
        'Lunugamvehera National Park',
        'Angammedilla National Park',
      ],
      'Heritage': [
        'Sigiriya Rock Fortress',
        'Anuradhapura Ancient City',
        'Polonnaruwa Archaeological Site',
        'Galle Fort',
        'Dambulla Cave Temple',
        'Kandy Temple of the Tooth',
        'Mihintale Sacred Mountain',
        'Abhayagiri Monastery',
        'Jetavanaramaya Stupa',
        'Ruwanwelisaya Stupa',
        'Lankatilaka Temple',
        'Gadaladeniya Temple',
        'Embekke Devalaya',
        'Kataragama Temple',
        'Nallur Kandaswamy Temple',
        'Dutch Reformed Church',
        'St. Mary\'s Cathedral',
        'Jami Ul-Alfar Mosque',
        'Gangaramaya Temple',
        'Kelaniya Raja Maha Viharaya',
      ],
      'Beaches': [
        'Mirissa Beach',
        'Unawatuna Beach',
        'Bentota Beach',
        'Arugam Bay',
        'Hikkaduwa Beach',
        'Negombo Beach',
        'Kalpitiya Beach',
        'Trincomalee Beach',
        'Pasikudah Beach',
        'Nilaveli Beach',
        'Uppuveli Beach',
        'Weligama Beach',
        'Tangalle Beach',
        'Polhena Beach',
        'Mount Lavinia Beach',
        'Beruwala Beach',
        'Ahungalla Beach',
        'Koggala Beach',
        'Dickwella Beach',
        'Hiriketiya Beach',
      ],
      'Tea Country': [
        'Nuwara Eliya',
        'Ella',
        'Horton Plains',
        'Adam\'s Peak',
        'Kandy',
        'Badulla',
        'Bandarawela',
        'Haputale',
        'Maskeliya',
        'Hatton',
        'Dickoya',
        'Talawakelle',
        'Nanu Oya',
        'Pattipola',
        'Ohiya',
        'Bambarakanda Falls',
        'Ravana Falls',
        'Devon Falls',
        'St. Clair\'s Falls',
        'Laxapana Falls',
      ],
      'Local Food': [
        'Colombo Pettah Market',
        'Galle Face Green',
        'Mount Lavinia Beach',
        'Negombo Fish Market',
        'Kandy Central Market',
        'Anuradhapura Market',
        'Jaffna Market',
        'Batticaloa Market',
        'Trincomalee Market',
        'Galle Market',
        'Matale Spice Market',
        'Kurunegala Market',
        'Ratnapura Gem Market',
        'Chilaw Fish Market',
        'Kalutara Market',
        'Ambalangoda Market',
        'Bentota Market',
        'Hikkaduwa Market',
        'Ella Market',
        'Nuwara Eliya Market',
      ],
      'Spiritual': [
        'Temple of the Sacred Tooth Relic',
        'Dambulla Cave Temple',
        'Mihintale',
        'Anuradhapura Sacred City',
        'Polonnaruwa Sacred City',
        'Kataragama Temple',
        'Nallur Kandaswamy Temple',
        'Gangaramaya Temple',
        'Kelaniya Raja Maha Viharaya',
        'Lankatilaka Temple',
        'Gadaladeniya Temple',
        'Embekke Devalaya',
        'Sri Dalada Maligawa',
        'Maligawa Temple',
        'Aluvihare Rock Temple',
        'Muthiyangana Temple',
        'Koneswaram Temple',
        'Thirukoneswaram Temple',
        'Nagadeepa Temple',
        'Munneswaram Temple',
      ],
    };

    final places = categoryPlaces[category] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            Container(
              margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    '$category Places',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2d3748),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Places List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  return _buildPlaceItem(place, index + 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceItem(String place, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Number indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                index.toString(),
                          style: const TextStyle(
                  fontSize: 14,
                            fontWeight: FontWeight.w600,
                  color: Color(0xFF667eea),
                          ),
                        ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Place name
          Expanded(
            child: Text(
              place,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2d3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllBookings(BuildContext context) {
    final List<Map<String, dynamic>> allBookings = [
      {
        'tour': 'Sigiriya Rock Fortress Tour',
        'date': 'Dec 15, 2024',
        'status': 'Confirmed',
        'isConfirmed': true,
        'price': 'Rs. 8,500',
        'duration': '4 hours',
        'participants': '2 people',
      },
      {
        'tour': 'Ella Nine Arch Bridge Adventure',
        'date': 'Dec 20, 2024',
        'status': 'Pending',
        'isConfirmed': false,
        'price': 'Rs. 12,000',
        'duration': '6 hours',
        'participants': '4 people',
      },
      {
        'tour': 'Mirissa Whale Watching',
        'date': 'Dec 25, 2024',
        'status': 'Confirmed',
        'isConfirmed': true,
        'price': 'Rs. 15,000',
        'duration': '5 hours',
        'participants': '3 people',
      },
      {
        'tour': 'Kandy Temple of the Tooth',
        'date': 'Dec 28, 2024',
        'status': 'Confirmed',
        'isConfirmed': true,
        'price': 'Rs. 6,500',
        'duration': '3 hours',
        'participants': '2 people',
      },
      {
        'tour': 'Galle Fort Heritage Walk',
        'date': 'Jan 2, 2025',
        'status': 'Pending',
        'isConfirmed': false,
        'price': 'Rs. 7,500',
        'duration': '3 hours',
        'participants': '5 people',
      },
      {
        'tour': 'Yala National Park Safari',
        'date': 'Jan 5, 2025',
        'status': 'Confirmed',
        'isConfirmed': true,
        'price': 'Rs. 18,000',
        'duration': '8 hours',
        'participants': '6 people',
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
                    'All Bookings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2d3748),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Bookings List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: allBookings.length,
                itemBuilder: (context, index) {
                  final booking = allBookings[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDetailedBookingCard(booking),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedBookingCard(Map<String, dynamic> booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.explore,
                  color: Color(0xFF667eea),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['tour'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2d3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking['date'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: booking['isConfirmed'] 
                      ? const Color(0xFF48bb78).withOpacity(0.1)
                      : const Color(0xFFed8936).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: booking['isConfirmed'] 
                        ? const Color(0xFF48bb78)
                        : const Color(0xFFed8936),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                booking['duration'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                booking['participants'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                booking['price'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Placeholder pages for other tabs
class ExplorePage extends StatelessWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Explore Page - Coming Soon'),
      ),
    );
  }
}

class TouristProfilePage extends StatefulWidget {
  const TouristProfilePage({Key? key}) : super(key: key);

  @override
  State<TouristProfilePage> createState() => _TouristProfilePageState();
}

class _TouristProfilePageState extends State<TouristProfilePage> {
  final GlobalKey<_TouristProfileFormState> _formKey = GlobalKey<_TouristProfileFormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2d3748),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2d3748)),
        actions: [
          TextButton(
            onPressed: () {
              _formKey.currentState?.saveProfile();
            },
            child: const Text(
              'Update',
              style: TextStyle(
                color: Color(0xFF667eea),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: TouristProfileForm(key: _formKey),
    );
  }
}

class TouristProfileForm extends StatefulWidget {
  const TouristProfileForm({Key? key}) : super(key: key);

  @override
  State<TouristProfileForm> createState() => _TouristProfileFormState();
}

class _TouristProfileFormState extends State<TouristProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyEmailController = TextEditingController();
  final _emergencyContact1Controller = TextEditingController();
  final _emergencyContact2Controller = TextEditingController();
  final _relationshipController = TextEditingController();
  
  File? _profileImage;
  File? _passportImage;
  String? _profileImageUrl;
  String? _passportImageUrl;
  String? _profileImageBase64;
  String? _passportImageBase64;
  bool _isLoadingImage = false;
  final ImagePicker _picker = ImagePicker();
  final FirebaseService _firebaseService = FirebaseService();
  
  DateTime? _dateOfBirth;
  List<String> _selectedLanguages = [];
  String? _selectedCountryCode = '+94';
  String? _selectedEmergencyCountryCode1 = '+94';
  String? _selectedEmergencyCountryCode2 = '+94';
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _profileExists = false;
  
  final List<String> _availableLanguages = [
    'English', 'Sinhala', 'Tamil', 'French', 'German', 'Spanish', 
    'Italian', 'Portuguese', 'Russian', 'Chinese', 'Japanese', 'Korean',
    'Arabic', 'Hindi', 'Dutch', 'Swedish', 'Norwegian', 'Danish'
  ];
  
  final List<Map<String, String>> _countryCodes = [
    {'code': '+94', 'country': 'Sri Lanka', 'flag': '🇱🇰'},
    {'code': '+1', 'country': 'USA/Canada', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': '+91', 'country': 'India', 'flag': '🇮🇳'},
    {'code': '+86', 'country': 'China', 'flag': '🇨🇳'},
    {'code': '+81', 'country': 'Japan', 'flag': '🇯🇵'},
    {'code': '+82', 'country': 'South Korea', 'flag': '🇰🇷'},
    {'code': '+65', 'country': 'Singapore', 'flag': '🇸🇬'},
    {'code': '+60', 'country': 'Malaysia', 'flag': '🇲🇾'},
    {'code': '+66', 'country': 'Thailand', 'flag': '🇹🇭'},
    {'code': '+61', 'country': 'Australia', 'flag': '🇦🇺'},
    {'code': '+64', 'country': 'New Zealand', 'flag': '🇳🇿'},
    {'code': '+49', 'country': 'Germany', 'flag': '🇩🇪'},
    {'code': '+33', 'country': 'France', 'flag': '🇫🇷'},
    {'code': '+39', 'country': 'Italy', 'flag': '🇮🇹'},
    {'code': '+34', 'country': 'Spain', 'flag': '🇪🇸'},
    {'code': '+31', 'country': 'Netherlands', 'flag': '🇳🇱'},
    {'code': '+46', 'country': 'Sweden', 'flag': '🇸🇪'},
    {'code': '+47', 'country': 'Norway', 'flag': '🇳🇴'},
    {'code': '+45', 'country': 'Denmark', 'flag': '🇩🇰'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _nationalityController.dispose();
    _emergencyNameController.dispose();
    _emergencyEmailController.dispose();
    _emergencyContact1Controller.dispose();
    _emergencyContact2Controller.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _firebaseService.currentUser;
      if (user != null) {
        final userData = await _firebaseService.getUserProfile(user.uid);
        if (userData != null && mounted) {
          setState(() {
            _nameController.text = userData['name'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _contactController.text = userData['contactNumber'] ?? '';
            _nationalityController.text = userData['nationality'] ?? '';
            _profileImageUrl = userData['profileImageUrl'];
            _passportImageUrl = userData['passportImageUrl'];
            
            // Load date of birth
            if (userData['dateOfBirth'] != null) {
              _dateOfBirth = (userData['dateOfBirth'] as Timestamp).toDate();
            }
            
            // Load languages
            if (userData['preferredLanguages'] != null) {
              _selectedLanguages = List<String>.from(userData['preferredLanguages']);
            }
            
            // Load country codes
            _selectedCountryCode = userData['countryCode'] ?? '+94';
            _selectedEmergencyCountryCode1 = userData['emergencyCountryCode1'] ?? '+94';
            _selectedEmergencyCountryCode2 = userData['emergencyCountryCode2'] ?? '+94';
            
            // Load emergency contact
            _emergencyNameController.text = userData['emergencyContactName'] ?? '';
            _emergencyEmailController.text = userData['emergencyContactEmail'] ?? '';
            _emergencyContact1Controller.text = userData['emergencyContact1'] ?? '';
            _emergencyContact2Controller.text = userData['emergencyContact2'] ?? '';
            _relationshipController.text = userData['emergencyRelationship'] ?? '';
            
            _profileExists = true; // Profile data exists
            _isLoadingData = false;
          });
        } else {
          setState(() {
            _isLoadingData = false;
          });
        }
      } else {
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information Section
                _buildSectionTitle('Personal Information'),
                const SizedBox(height: 15),
                _buildPersonalInfoSection(),
                const SizedBox(height: 30),
                
                // Emergency Contact Section
                _buildSectionTitle('Emergency Contact'),
                const SizedBox(height: 15),
                _buildEmergencyContactSection(),
                const SizedBox(height: 30),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2d3748),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Photo
          _buildPhotoSection('Profile Photo (Optional)', _profileImage, _profileImageUrl, 'profile'),
          const SizedBox(height: 20),
          
          // Full Name
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'your.email@example.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Contact Number with Country Code
          _buildContactNumberField(),
          const SizedBox(height: 20),
          
          // Date of Birth
          _buildDatePickerField(),
          const SizedBox(height: 20),
          
          // Nationality/Country
          _buildTextField(
            controller: _nationalityController,
            label: 'Nationality/Country',
            hint: 'Sri Lanka',
            icon: Icons.flag,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your nationality';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Preferred Languages
          _buildLanguagesSection(),
          const SizedBox(height: 20),
          
          // Passport Photo
          _buildPassportPhotoSection(),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emergency Contact Name
          _buildTextField(
            controller: _emergencyNameController,
            label: 'Emergency Contact Name',
            hint: 'Enter emergency contact name',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter emergency contact name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Emergency Contact Email
          _buildTextField(
            controller: _emergencyEmailController,
            label: 'Emergency Contact Email',
            hint: 'emergency@example.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter emergency contact email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Emergency Contact Number 1
          _buildEmergencyContactNumberField(1),
          const SizedBox(height: 20),
          
          // Emergency Contact Number 2
          _buildEmergencyContactNumberField(2),
          const SizedBox(height: 20),
          
          // Relationship
          _buildTextField(
            controller: _relationshipController,
            label: 'Relationship to Tourist',
            hint: 'Parent, Spouse, Sibling, Friend, etc.',
            icon: Icons.family_restroom,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter relationship';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String title, File? file, String? fileUrl, String type) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showImagePickerOptions(type),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF667eea),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _buildProfileImageWidget(file, fileUrl, type),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          file != null || fileUrl != null ? 'Change $title' : 'Add $title',
          style: const TextStyle(
            color: Color(0xFF667eea),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImageWidget(File? file, String? fileUrl, String type) {
    final base64Image = type == 'profile' ? _profileImageBase64 : _passportImageBase64;
    final hasImage = (fileUrl != null && fileUrl.isNotEmpty) || file != null || base64Image != null;
    
    if (!hasImage) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Icon(
          type == 'profile' ? Icons.camera_alt : Icons.credit_card,
          color: Colors.white,
          size: 40,
        ),
      );
    }

    // For web platforms, use a different approach to handle CORS issues
    if (kIsWeb) {
      return _buildWebProfileImage(file, fileUrl, base64Image, type);
    } else {
      return _buildMobileProfileImage(file, fileUrl, type);
    }
  }

  Widget _buildWebProfileImage(File? file, String? fileUrl, String? base64Image, String type) {
    if (_isLoadingImage) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 2,
          ),
        ),
      );
    }
    
    // Show base64 image only if no network URL is available
    if (base64Image != null && (fileUrl == null || fileUrl.isEmpty)) {
      return ClipOval(
        child: Image.memory(
          base64Decode(base64Image),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackImage(type);
          },
        ),
      );
    }
    
    // For web, try to load the network image first
    if (fileUrl != null && fileUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          fileUrl,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // If network image fails, try base64 image
            if (base64Image != null) {
              return ClipOval(
                child: Image.memory(
                  base64Decode(base64Image),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackImage(type);
                  },
                ),
              );
            }
            return _buildFallbackImage(type);
          },
        ),
      );
    }

    return _buildFallbackImage(type);
  }

  Widget _buildMobileProfileImage(File? file, String? fileUrl, String type) {
    // If we have a local file AND no network URL, show it immediately
    if (file != null && (fileUrl == null || fileUrl.isEmpty)) {
      return ClipOval(
        child: Image.file(
          file,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackImage(type);
          },
        ),
      );
    }

    // If we have a network URL, load it
    if (fileUrl != null && fileUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          fileUrl,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackImage(type);
          },
        ),
      );
    }

    return _buildFallbackImage(type);
  }

  Widget _buildFallbackImage(String type) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: Icon(
        type == 'profile' ? Icons.person : Icons.credit_card,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildPassportPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.credit_card,
                color: Color(0xFF667eea),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Passport Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3748),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                'Optional',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload a clear photo of your passport for verification purposes',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        
        // Passport Photo Upload Area
        GestureDetector(
          onTap: () => _showImagePickerOptions('passport'),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _passportImage != null || _passportImageUrl != null 
                    ? const Color(0xFF667eea) 
                    : Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_passportImage != null || _passportImageUrl != null 
                      ? const Color(0xFF667eea) 
                      : Colors.grey).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildPassportImageWidget(),
          ),
        ),
        const SizedBox(height: 15),
        
        // Action Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _passportImage != null || _passportImageUrl != null 
                ? Colors.green.withOpacity(0.1)
                : const Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _passportImage != null || _passportImageUrl != null 
                  ? Colors.green.withOpacity(0.3)
                  : const Color(0xFF667eea).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _passportImage != null || _passportImageUrl != null 
                    ? Icons.check_circle 
                    : Icons.add_photo_alternate,
                color: _passportImage != null || _passportImageUrl != null 
                    ? Colors.green 
                    : const Color(0xFF667eea),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _passportImage != null || _passportImageUrl != null 
                    ? 'Passport Photo Added' 
                    : 'Add Passport Photo',
                style: TextStyle(
                  color: _passportImage != null || _passportImageUrl != null 
                      ? Colors.green 
                      : const Color(0xFF667eea),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassportImageWidget() {
    final hasImage = (_passportImageUrl != null && _passportImageUrl!.isNotEmpty) || 
                    _passportImage != null || 
                    _passportImageBase64 != null;
    
    if (!hasImage) {
      return _buildPassportPlaceholder();
    }

    // For web platforms, use a different approach to handle CORS issues
    if (kIsWeb) {
      return _buildWebPassportImage();
    } else {
      return _buildMobilePassportImage();
    }
  }

  Widget _buildWebPassportImage() {
    if (_isLoadingImage) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 2,
          ),
        ),
      );
    }
    
    // Show base64 image only if no network URL is available
    if (_passportImageBase64 != null && (_passportImageUrl == null || _passportImageUrl!.isEmpty)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          base64Decode(_passportImageBase64!),
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPassportPlaceholder();
          },
        ),
      );
    }
    
    // For web, try to load the network image first
    if (_passportImageUrl != null && _passportImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          _passportImageUrl!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // If network image fails, try base64 image
            if (_passportImageBase64 != null) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  base64Decode(_passportImageBase64!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPassportPlaceholder();
                  },
                ),
              );
            }
            return _buildPassportPlaceholder();
          },
        ),
      );
    }

    return _buildPassportPlaceholder();
  }

  Widget _buildMobilePassportImage() {
    // If we have a local file AND no network URL, show it immediately
    if (_passportImage != null && (_passportImageUrl == null || _passportImageUrl!.isEmpty)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          _passportImage!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPassportPlaceholder();
          },
        ),
      );
    }

    // If we have a network URL, load it
    if (_passportImageUrl != null && _passportImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          _passportImageUrl!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildPassportPlaceholder();
          },
        ),
      );
    }

    return _buildPassportPlaceholder();
  }

  Widget _buildPassportPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Colors.grey[100]!,
            Colors.grey[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.credit_card,
              color: Color(0xFF667eea),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap to upload passport photo',
            style: TextStyle(
              color: Color(0xFF667eea),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Camera or Gallery',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactNumberField() {
    return Row(
      children: [
        // Country Code Dropdown
        Container(
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: _countryCodes.map((country) {
                return DropdownMenuItem<String>(
                  value: country['code'],
                  child: Row(
                    children: [
                      Text(country['flag']!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(country['code']!, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCountryCode = value;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Contact Number
        Expanded(
          child: _buildTextField(
            controller: _contactController,
            label: 'Contact Number',
            hint: '77 123 4567',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter contact number';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyContactNumberField(int contactNumber) {
    final controller = contactNumber == 1 ? _emergencyContact1Controller : _emergencyContact2Controller;
    final selectedCode = contactNumber == 1 ? _selectedEmergencyCountryCode1 : _selectedEmergencyCountryCode2;
    
    return Row(
      children: [
        // Country Code Dropdown
        Container(
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCode,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: _countryCodes.map((country) {
                return DropdownMenuItem<String>(
                  value: country['code'],
                  child: Row(
                    children: [
                      Text(country['flag']!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(country['code']!, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  if (contactNumber == 1) {
                    _selectedEmergencyCountryCode1 = value;
                  } else {
                    _selectedEmergencyCountryCode2 = value;
                  }
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Contact Number
        Expanded(
          child: _buildTextField(
            controller: controller,
            label: 'Emergency Contact $contactNumber',
            hint: '77 123 4567',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter emergency contact $contactNumber';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: _selectDateOfBirth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: const Color(0xFF667eea)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date of Birth',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateOfBirth != null
                        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                        : 'Select your date of birth',
                    style: TextStyle(
                      fontSize: 16,
                      color: _dateOfBirth != null ? Colors.black : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferred Languages:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2d3748),
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableLanguages.map((language) {
            final isSelected = _selectedLanguages.contains(language);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedLanguages.remove(language);
                  } else {
                    _selectedLanguages.add(language);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF667eea) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF667eea) : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  language,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }


  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Must be at least 18 years old
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  void _showImagePickerOptions(String type) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select ${type == 'profile' ? 'Profile' : 'Passport'} Photo Source',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3748),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, type);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, type);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF667eea).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF667eea).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF667eea),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF667eea),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    try {
      setState(() {
        _isLoadingImage = true;
      });

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('Picking ${type == 'profile' ? 'profile' : 'passport'} image...'),
            ],
          ),
          backgroundColor: const Color(0xFF667eea),
          duration: const Duration(seconds: 2),
        ),
      );

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        // For web compatibility, convert to base64 first
        String? base64Data;
        if (kIsWeb) {
          base64Data = base64Encode(await image.readAsBytes());
        }
        
        setState(() {
          if (type == 'profile') {
            _profileImage = File(image.path);
            _profileImageBase64 = base64Data;
          } else {
            _passportImage = File(image.path);
            _passportImageBase64 = base64Data;
          }
          _isLoadingImage = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('${type == 'profile' ? 'Profile' : 'Passport'} image selected successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isLoadingImage = false;
        });
        // User cancelled
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selection cancelled'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _isLoadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error picking image: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String? profileImageUrl = _profileImageUrl;
      String? passportImageUrl = _passportImageUrl;

      // Upload new images if selected
      if (_profileImage != null) {
        print('📸 Uploading profile image...');
        Uint8List imageBytes;
        if (kIsWeb && _profileImageBase64 != null) {
          // For web, use base64 data
          imageBytes = base64Decode(_profileImageBase64!);
        } else {
          // For mobile, read from file
          imageBytes = await _profileImage!.readAsBytes();
        }
        profileImageUrl = await _firebaseService.uploadProfileImage(
          '${user.uid}_profile_${DateTime.now().millisecondsSinceEpoch}', 
          imageBytes
        );
        print('✅ Profile image uploaded successfully: $profileImageUrl');
        
        // Clear local image after successful upload
        setState(() {
          _profileImage = null;
          _profileImageBase64 = null;
        });
      }

      if (_passportImage != null) {
        print('📸 Uploading passport image...');
        Uint8List imageBytes;
        if (kIsWeb && _passportImageBase64 != null) {
          // For web, use base64 data
          imageBytes = base64Decode(_passportImageBase64!);
        } else {
          // For mobile, read from file
          imageBytes = await _passportImage!.readAsBytes();
        }
        passportImageUrl = await _firebaseService.uploadProfileImage(
          '${user.uid}_passport_${DateTime.now().millisecondsSinceEpoch}', 
          imageBytes
        );
        print('✅ Passport image uploaded successfully: $passportImageUrl');
        
        // Clear local image after successful upload
        setState(() {
          _passportImage = null;
          _passportImageBase64 = null;
        });
      }

      // Calculate age from date of birth
      final now = DateTime.now();
      final age = now.year - _dateOfBirth!.year;
      final monthDiff = now.month - _dateOfBirth!.month;
      final finalAge = monthDiff < 0 || (monthDiff == 0 && now.day < _dateOfBirth!.day) 
          ? age - 1 
          : age;

      // Prepare profile data
      final profileData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'contactNumber': _contactController.text.trim(),
        'countryCode': _selectedCountryCode,
        'dateOfBirth': Timestamp.fromDate(_dateOfBirth!),
        'age': finalAge,
        'nationality': _nationalityController.text.trim(),
        'preferredLanguages': _selectedLanguages,
        'profileImageUrl': profileImageUrl,
        'passportImageUrl': passportImageUrl,
        'emergencyContactName': _emergencyNameController.text.trim(),
        'emergencyContactEmail': _emergencyEmailController.text.trim(),
        'emergencyContact1': _emergencyContact1Controller.text.trim(),
        'emergencyCountryCode1': _selectedEmergencyCountryCode1,
        'emergencyContact2': _emergencyContact2Controller.text.trim(),
        'emergencyCountryCode2': _selectedEmergencyCountryCode2,
        'emergencyRelationship': _relationshipController.text.trim(),
      };

      // Update user profile in Firestore
      await _firebaseService.updateUserProfile(user.uid, profileData);

      // Mark profile as existing after successful save
      setState(() {
        _profileExists = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_profileExists 
                ? 'Profile updated successfully!' 
                : 'Profile created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}



