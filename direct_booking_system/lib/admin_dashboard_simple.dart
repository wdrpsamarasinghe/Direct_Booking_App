import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signin_page.dart';
import 'theme/app_theme.dart';

class AdminDashboardSimple extends StatefulWidget {
  final BuildContext context;
  const AdminDashboardSimple({Key? key, required this.context}) : super(key: key);

  @override
  State<AdminDashboardSimple> createState() => _AdminDashboardSimpleState();
}

class _AdminDashboardSimpleState extends State<AdminDashboardSimple> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  // Real-time data from actual database
  Map<String, int> _userCounts = {};
  Map<String, int> _tripStats = {};
  Map<String, int> _applicationStats = {};
  Map<String, int> _verificationStats = {};
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> _topGuides = [];
  List<Map<String, dynamic>> _recentUsers = [];
  List<Map<String, dynamic>> _pendingApplications = [];
  List<Map<String, dynamic>> _pendingVerifications = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadUserStatistics(),
        _loadTripStatistics(),
        _loadApplicationStatistics(),
        _loadVerificationStatistics(),
        _loadRecentActivities(),
        _loadTopGuides(),
        _loadRecentUsers(),
        _loadPendingApplications(),
        _loadPendingVerifications(),
      ]);
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadDashboardData();
    setState(() {
      _isRefreshing = false;
    });
  }

  // Load real user statistics from users collection
  Future<void> _loadUserStatistics() async {
    try {
      final QuerySnapshot snapshot = await _firebaseService.firestore.collection('users').get();
      
      Map<String, int> counts = {
        'total': 0,
        'tourists': 0,
        'guides': 0,
        'admins': 0,
        'active': 0,
        'inactive': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        counts['total'] = (counts['total'] ?? 0) + 1;
        
        final role = (data['role'] as String?)?.toLowerCase() ?? 'tourist';
        final isActive = data['isActive'] ?? true;
        
        switch (role) {
          case 'tour guide':
            counts['guides'] = (counts['guides'] ?? 0) + 1;
            break;
          case 'admin':
            counts['admins'] = (counts['admins'] ?? 0) + 1;
            break;
          case 'tourist':
          default:
            counts['tourists'] = (counts['tourists'] ?? 0) + 1;
        }
        
        if (isActive) {
          counts['active'] = (counts['active'] ?? 0) + 1;
        } else {
          counts['inactive'] = (counts['inactive'] ?? 0) + 1;
        }
      }

      setState(() {
        _userCounts = counts;
      });
    } catch (e) {
      print('Error loading user statistics: $e');
    }
  }

  // Load real trip statistics from trips collection
  Future<void> _loadTripStatistics() async {
    try {
      final QuerySnapshot snapshot = await _firebaseService.firestore.collection('trips').get();
      
      Map<String, int> stats = {
        'total': 0,
        'active': 0,
        'completed': 0,
        'cancelled': 0,
        'upcoming': 0,
      };

      final now = DateTime.now();
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        stats['total'] = (stats['total'] ?? 0) + 1;
        
        final status = data['status'] as String? ?? 'active';
        final startDate = data['startDate'] as Timestamp?;
        
        if (startDate != null) {
          final tripStartDate = startDate.toDate();
          if (tripStartDate.isAfter(now)) {
            stats['upcoming'] = (stats['upcoming'] ?? 0) + 1;
          } else if (tripStartDate.isBefore(now) && status == 'active') {
            stats['completed'] = (stats['completed'] ?? 0) + 1;
          }
        }
        
        switch (status.toLowerCase()) {
          case 'active':
            stats['active'] = (stats['active'] ?? 0) + 1;
            break;
          case 'completed':
            stats['completed'] = (stats['completed'] ?? 0) + 1;
            break;
          case 'cancelled':
            stats['cancelled'] = (stats['cancelled'] ?? 0) + 1;
            break;
        }
      }

      setState(() {
        _tripStats = stats;
      });
    } catch (e) {
      print('Error loading trip statistics: $e');
    }
  }

  // Load verification statistics from users collection
  Future<void> _loadVerificationStatistics() async {
    try {
      final QuerySnapshot snapshot = await _firebaseService.firestore
          .collection('users')
          .get();

      int pending = 0;
      int verified = 0;
      int rejected = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['verificationStatus'] ?? 'pending';
        
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'verified':
            verified++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }

      _verificationStats = {
        'pending': pending,
        'verified': verified,
        'rejected': rejected,
        'total': pending + verified + rejected,
      };

      print('✅ Verification stats loaded: $_verificationStats');
    } catch (e) {
      print('❌ Error loading verification statistics: $e');
      _verificationStats = {
        'pending': 0,
        'verified': 0,
        'rejected': 0,
        'total': 0,
      };
    }
  }

  // Load real application statistics from trip_applications collection
  Future<void> _loadApplicationStatistics() async {
    try {
      final QuerySnapshot snapshot = await _firebaseService.firestore.collection('trip_applications').get();
      
      Map<String, int> stats = {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'cancelled': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        stats['total'] = (stats['total'] ?? 0) + 1;
        
        final status = data['status'] as String? ?? 'pending';
        
        switch (status.toLowerCase()) {
          case 'pending':
            stats['pending'] = (stats['pending'] ?? 0) + 1;
            break;
          case 'approved':
            stats['approved'] = (stats['approved'] ?? 0) + 1;
            break;
          case 'rejected':
            stats['rejected'] = (stats['rejected'] ?? 0) + 1;
            break;
          case 'cancelled':
            stats['cancelled'] = (stats['cancelled'] ?? 0) + 1;
            break;
        }
      }

      setState(() {
        _applicationStats = stats;
      });
    } catch (e) {
      print('Error loading application statistics: $e');
    }
  }

  // Load recent activities from multiple collections
  Future<void> _loadRecentActivities() async {
    try {
      List<Map<String, dynamic>> activities = [];
      
      // Recent user registrations
      final usersSnapshot = await _firebaseService.firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        activities.add({
          'type': 'user_registration',
          'title': 'New User Registration',
          'description': '${data['name']} (${data['role']}) joined the platform',
          'timestamp': data['createdAt'],
          'icon': Icons.person_add,
          'color': Colors.blue,
        });
      }
      
      // Recent trip applications
      final applicationsSnapshot = await _firebaseService.firestore
          .collection('trip_applications')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      for (var doc in applicationsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        activities.add({
          'type': 'trip_application',
          'title': 'New Trip Application',
          'description': 'Application for trip: ${data['tripTitle'] ?? 'Unknown Trip'}',
          'timestamp': data['createdAt'],
          'icon': Icons.assignment,
          'color': Colors.orange,
        });
      }
      
      // Sort by timestamp and take the most recent
      activities.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      setState(() {
        _recentActivities = activities.take(10).toList();
      });
    } catch (e) {
      print('Error loading recent activities: $e');
    }
  }

  // Load top performing guides
  Future<void> _loadTopGuides() async {
    try {
      final QuerySnapshot snapshot = await _firebaseService.firestore
          .collection('users')
          .where('role', isEqualTo: 'Tour Guide')
          .get();
      
      List<Map<String, dynamic>> guides = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get guide's trip count
        final tripsSnapshot = await _firebaseService.firestore
            .collection('trips')
            .where('guideId', isEqualTo: doc.id)
            .get();
        
        // Get guide's average rating
        final reviewsSnapshot = await _firebaseService.firestore
            .collection('reviews')
            .where('guideId', isEqualTo: doc.id)
            .get();
        
        double averageRating = 0.0;
        if (reviewsSnapshot.docs.isNotEmpty) {
          double totalRating = 0;
          for (var reviewDoc in reviewsSnapshot.docs) {
            final reviewData = reviewDoc.data() as Map<String, dynamic>;
            totalRating += (reviewData['rating'] as num?)?.toDouble() ?? 0;
          }
          averageRating = totalRating / reviewsSnapshot.docs.length;
        }
        
        guides.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Guide',
          'email': data['email'] ?? '',
          'tripCount': tripsSnapshot.docs.length,
          'averageRating': averageRating,
          'profileImageUrl': data['profileImageUrl'],
          'location': data['location'],
          'specialties': data['specialties'] ?? [],
        });
      }
      
      // Sort by trip count and rating
      guides.sort((a, b) {
        final aScore = (a['tripCount'] as int) * 0.7 + (a['averageRating'] as double) * 0.3;
        final bScore = (b['tripCount'] as int) * 0.7 + (b['averageRating'] as double) * 0.3;
        return bScore.compareTo(aScore);
      });
      
      setState(() {
        _topGuides = guides.take(5).toList();
      });
    } catch (e) {
      print('Error loading top guides: $e');
    }
  }

  // Load recent users
  Future<void> _loadRecentUsers() async {
    try {
      final QuerySnapshot snapshot = await _firebaseService.firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      List<Map<String, dynamic>> users = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        users.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown User',
          'email': data['email'] ?? '',
          'role': data['role'] ?? 'Tourist',
          'createdAt': data['createdAt'],
          'isActive': data['isActive'] ?? true,
          'profileImageUrl': data['profileImageUrl'],
        });
      }
      
      setState(() {
        _recentUsers = users;
      });
    } catch (e) {
      print('Error loading recent users: $e');
    }
  }

  // Load pending applications that need admin attention
  Future<void> _loadPendingApplications() async {
    try {
      final QuerySnapshot snapshot = await _firebaseService.firestore
          .collection('trip_applications')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      List<Map<String, dynamic>> applications = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get trip details
        final tripDoc = await _firebaseService.firestore
            .collection('trips')
            .doc(data['tripId'] as String?)
            .get();
        
        // Get tourist details
        final touristDoc = await _firebaseService.firestore
            .collection('users')
            .doc(data['touristId'] as String?)
            .get();
        
        applications.add({
          'id': doc.id,
          'tripTitle': tripDoc.data()?['title'] ?? 'Unknown Trip',
          'touristName': touristDoc.data()?['name'] ?? 'Unknown Tourist',
          'touristEmail': touristDoc.data()?['email'] ?? '',
          'createdAt': data['createdAt'],
          'status': data['status'],
          'message': data['message'],
        });
      }
      
      setState(() {
        _pendingApplications = applications;
      });
    } catch (e) {
      print('Error loading pending applications: $e');
    }
  }

  // Load pending verification users
  Future<void> _loadPendingVerifications() async {
    try {
      final QuerySnapshot snapshot = await _firebaseService.firestore
          .collection('users')
          .where('verificationStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      List<Map<String, dynamic>> verifications = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        verifications.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown User',
          'email': data['email'] ?? '',
          'role': data['role'] ?? 'user',
          'createdAt': data['createdAt'],
          'verificationStatus': data['verificationStatus'],
          'phone': data['phone'] ?? 'Not provided',
          'location': data['location'] ?? 'Not specified',
        });
      }
      
      setState(() {
        _pendingVerifications = verifications;
      });
    } catch (e) {
      print('Error loading pending verifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive padding based on screen size
              double horizontalPadding = 20;
              double verticalSpacing = 30;
              
              if (constraints.maxWidth < 600) {
                // Mobile: Smaller padding and spacing
                horizontalPadding = 16;
                verticalSpacing = 20;
              } else if (constraints.maxWidth < 900) {
                // Tablet: Medium padding
                horizontalPadding = 18;
                verticalSpacing = 25;
              }
              
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeader(),
                    SizedBox(height: verticalSpacing),
                    
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      // Key Metrics Overview
                      _buildKeyMetricsOverview(),
                      SizedBox(height: verticalSpacing),
                      
                      // Data Visualization Section (Simple)
                      _buildDataVisualizationSection(),
                      SizedBox(height: verticalSpacing),
                      
                      // Pending Actions Section
                      _buildPendingActionsSection(),
                      SizedBox(height: verticalSpacing),
                      
                      // Pending Verifications Section
                      _buildPendingVerificationsSection(),
                      SizedBox(height: verticalSpacing),
                      
                      // Top Performers Section
                      _buildTopPerformersSection(),
                      SizedBox(height: verticalSpacing),
                      
                      // Recent Activities
                      _buildRecentActivitiesSection(),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // Mobile: Stack vertically
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isRefreshing ? Icons.hourglass_empty : Icons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _isRefreshing ? null : _refreshData,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Here\'s what\'s happening with your platform.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white.withOpacity(0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Last updated: ${DateTime.now().toString().substring(0, 16)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Desktop/Tablet: Horizontal layout
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome back! Here\'s what\'s happening with your platform.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Last updated: ${DateTime.now().toString().substring(0, 16)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isRefreshing ? Icons.hourglass_empty : Icons.refresh,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _isRefreshing ? null : _refreshData,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildKeyMetricsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            double fontSize = 22;
            if (constraints.maxWidth < 600) {
              fontSize = 20;
            } else if (constraints.maxWidth < 400) {
              fontSize = 18;
            }
            
            return Text(
              'Platform Overview',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2d3748),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid based on screen width
            int crossAxisCount = 2;
            double childAspectRatio = 1.5;
            
            if (constraints.maxWidth < 600) {
              // Mobile: Single column with more height
              crossAxisCount = 1;
              childAspectRatio = 2.5;
            } else if (constraints.maxWidth < 900) {
              // Tablet: 2 columns with more height
              crossAxisCount = 2;
              childAspectRatio = 2.2;
            } else {
              // Desktop: 4 columns
              crossAxisCount = 4;
              childAspectRatio = 1.5;
            }
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: constraints.maxWidth < 600 ? 12 : 16,
              mainAxisSpacing: constraints.maxWidth < 600 ? 12 : 16,
              childAspectRatio: childAspectRatio,
              children: [
                _buildMetricCard(
                  title: 'Total Users',
                  value: '${_userCounts['total'] ?? 0}',
                  subtitle: '${_userCounts['active'] ?? 0} active',
                  icon: Icons.people,
                  color: const Color(0xFF667eea),
                  trend: '+12%',
                ),
                _buildMetricCard(
                  title: 'Tour Guides',
                  value: '${_userCounts['guides'] ?? 0}',
                  subtitle: '${_topGuides.length} top performers',
                  icon: Icons.explore,
                  color: const Color(0xFF48bb78),
                  trend: '+8%',
                ),
                _buildMetricCard(
                  title: 'Total Trips',
                  value: '${_tripStats['total'] ?? 0}',
                  subtitle: '${_tripStats['active'] ?? 0} active',
                  icon: Icons.tour,
                  color: const Color(0xFFed8936),
                  trend: '+15%',
                ),
                _buildMetricCard(
                  title: 'Applications',
                  value: '${_applicationStats['total'] ?? 0}',
                  subtitle: '${_applicationStats['pending'] ?? 0} pending',
                  icon: Icons.assignment,
                  color: const Color(0xFFe53e3e),
                  trend: '+23%',
                ),
                _buildMetricCard(
                  title: 'Verifications',
                  value: '${_verificationStats['total'] ?? 0}',
                  subtitle: '${_verificationStats['pending'] ?? 0} pending',
                  icon: Icons.verified_user,
                  color: const Color(0xFF9f7aea),
                  trend: '+5%',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing based on card width
        double iconSize = 20;
        double valueFontSize = 24;
        double titleFontSize = 14;
        double subtitleFontSize = 12;
        double padding = 20;
        
        if (constraints.maxWidth < 200) {
          // Very small cards (mobile single column)
          iconSize = 14;
          valueFontSize = 18;
          titleFontSize = 11;
          subtitleFontSize = 9;
          padding = 10;
        } else if (constraints.maxWidth < 300) {
          // Small cards
          iconSize = 16;
          valueFontSize = 20;
          titleFontSize = 12;
          subtitleFontSize = 10;
          padding = 12;
        } else if (constraints.maxWidth < 400) {
          // Medium cards
          iconSize = 18;
          valueFontSize = 22;
          titleFontSize = 13;
          subtitleFontSize = 11;
          padding = 14;
        }
        
        return Container(
          padding: EdgeInsets.all(padding),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(padding * 0.3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: iconSize,
                    ),
                  ),
                  if (trend != null && constraints.maxWidth > 150)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth < 200 ? 4 : 6,
                        vertical: constraints.maxWidth < 200 ? 2 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        trend,
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: constraints.maxWidth < 200 ? 9 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: padding * 0.4),
              Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2d3748),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2d3748),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataVisualizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResponsiveTitle('Data Overview'),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              // Mobile: Stack vertically
              return Column(
                children: [
                  _buildSimpleChart(
                    title: 'User Distribution',
                    data: {
                      'Tourists': _userCounts['tourists'] ?? 0,
                      'Guides': _userCounts['guides'] ?? 0,
                      'Admins': _userCounts['admins'] ?? 0,
                    },
                    colors: [
                      const Color(0xFF667eea),
                      const Color(0xFF48bb78),
                      const Color(0xFFed8936),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSimpleChart(
                    title: 'Trip Status',
                    data: {
                      'Active': _tripStats['active'] ?? 0,
                      'Completed': _tripStats['completed'] ?? 0,
                      'Cancelled': _tripStats['cancelled'] ?? 0,
                      'Upcoming': _tripStats['upcoming'] ?? 0,
                    },
                    colors: [
                      const Color(0xFF48bb78),
                      const Color(0xFF667eea),
                      const Color(0xFFe53e3e),
                      const Color(0xFFed8936),
                    ],
                  ),
                ],
              );
            } else {
              // Tablet/Desktop: Side by side
              return Row(
                children: [
                  Expanded(
                    child: _buildSimpleChart(
                      title: 'User Distribution',
                      data: {
                        'Tourists': _userCounts['tourists'] ?? 0,
                        'Guides': _userCounts['guides'] ?? 0,
                        'Admins': _userCounts['admins'] ?? 0,
                      },
                      colors: [
                        const Color(0xFF667eea),
                        const Color(0xFF48bb78),
                        const Color(0xFFed8936),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSimpleChart(
                      title: 'Trip Status',
                      data: {
                        'Active': _tripStats['active'] ?? 0,
                        'Completed': _tripStats['completed'] ?? 0,
                        'Cancelled': _tripStats['cancelled'] ?? 0,
                        'Upcoming': _tripStats['upcoming'] ?? 0,
                      },
                      colors: [
                        const Color(0xFF48bb78),
                        const Color(0xFF667eea),
                        const Color(0xFFe53e3e),
                        const Color(0xFFed8936),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSimpleChart({
    required String title,
    required Map<String, int> data,
    required List<Color> colors,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 20),
          ...data.entries.map((entry) {
            final index = data.keys.toList().indexOf(entry.key);
            final color = colors[index % colors.length];
            final percentage = _userCounts['total']! > 0 
                ? (entry.value / _userCounts['total']! * 100).toStringAsFixed(1)
                : '0.0';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2d3748),
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value} ($percentage%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPendingActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildResponsiveTitle('Pending Actions'),
            if (_pendingApplications.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFe53e3e).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_pendingApplications.length} pending',
                  style: const TextStyle(
                    color: Color(0xFFe53e3e),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_pendingApplications.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
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
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Color(0xFF48bb78),
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'All caught up!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2d3748),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No pending applications at the moment.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
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
              children: _pendingApplications.take(5).map((application) {
                return _buildPendingApplicationCard(application);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPendingApplicationCard(Map<String, dynamic> application) {
    final createdAt = application['createdAt'] as Timestamp?;
    final timeAgo = createdAt != null ? _getTimeAgo(createdAt.toDate()) : 'Unknown';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFe53e3e).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFe53e3e).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFe53e3e).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment,
              color: Color(0xFFe53e3e),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  application['tripTitle'] ?? 'Unknown Trip',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2d3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${application['touristName'] ?? 'Unknown Tourist'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _approveApplication(application['id']),
                icon: const Icon(Icons.check, color: Color(0xFF48bb78)),
                tooltip: 'Approve',
              ),
              IconButton(
                onPressed: () => _rejectApplication(application['id']),
                icon: const Icon(Icons.close, color: Color(0xFFe53e3e)),
                tooltip: 'Reject',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingVerificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildResponsiveTitle('Pending Verifications'),
            if (_pendingVerifications.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFed8936).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_pendingVerifications.length} pending',
                  style: const TextStyle(
                    color: Color(0xFFed8936),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_pendingVerifications.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
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
                Icon(
                  Icons.verified_user_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Pending Verifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All users have been verified',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
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
              children: _pendingVerifications.take(5).map((verification) {
                return _buildPendingVerificationCard(verification);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPendingVerificationCard(Map<String, dynamic> verification) {
    final createdAt = verification['createdAt'] as Timestamp?;
    final timeAgo = createdAt != null ? _getTimeAgo(createdAt.toDate()) : 'Unknown';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFed8936).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFed8936).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFed8936).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.verified_user,
              color: Color(0xFFed8936),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verification['name'] ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2d3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  verification['email'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFed8936).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        verification['role']?.toString().toUpperCase() ?? 'USER',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFed8936),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _approveVerification(verification['id']),
                icon: const Icon(Icons.check_circle, color: Color(0xFF48bb78)),
                tooltip: 'Approve',
              ),
              IconButton(
                onPressed: () => _rejectVerification(verification['id']),
                icon: const Icon(Icons.cancel, color: Color(0xFFe53e3e)),
                tooltip: 'Reject',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResponsiveTitle('Top Performing Guides'),
        const SizedBox(height: 20),
        Container(
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
            children: _topGuides.map((guide) {
              return _buildGuideCard(guide);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard(Map<String, dynamic> guide) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF667eea).withOpacity(0.1),
            backgroundImage: guide['profileImageUrl'] != null
                ? NetworkImage(guide['profileImageUrl'])
                : null,
            child: guide['profileImageUrl'] == null
                ? const Icon(Icons.person, color: Color(0xFF667eea))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guide['name'] ?? 'Unknown Guide',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2d3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  guide['location'] ?? 'Unknown Location',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber[600],
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${guide['averageRating'].toStringAsFixed(1)} rating',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.tour,
                      color: Colors.blue[600],
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${guide['tripCount']} trips',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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

  Widget _buildRecentActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResponsiveTitle('Recent Activities'),
        const SizedBox(height: 20),
        Container(
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
            children: _recentActivities.take(5).map((activity) {
              return _buildActivityCard(activity);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final timestamp = activity['timestamp'] as Timestamp?;
    final timeAgo = timestamp != null ? _getTimeAgo(timestamp.toDate()) : 'Unknown';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? 'Unknown Activity',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2d3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['description'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
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

  Widget _buildResponsiveTitle(String title) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fontSize = 22;
        if (constraints.maxWidth < 600) {
          fontSize = 20;
        } else if (constraints.maxWidth < 400) {
          fontSize = 18;
        }
        
        return Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2d3748),
          ),
        );
      },
    );
  }

  Future<void> _approveApplication(String applicationId) async {
    try {
      await _firebaseService.firestore
          .collection('trip_applications')
          .doc(applicationId)
          .update({
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application approved successfully!'),
          backgroundColor: Color(0xFF48bb78),
        ),
      );
      
      _loadPendingApplications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectApplication(String applicationId) async {
    try {
      await _firebaseService.firestore
          .collection('trip_applications')
          .doc(applicationId)
          .update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application rejected successfully!'),
          backgroundColor: Color(0xFFe53e3e),
        ),
      );
      
      _loadPendingApplications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _approveVerification(String userId) async {
    try {
      await _firebaseService.approveUserVerification(userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User verification approved successfully'),
          backgroundColor: Color(0xFF48bb78),
        ),
      );
      
      // Refresh the data
      _loadPendingVerifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectVerification(String userId) async {
    try {
      await _firebaseService.rejectUserVerification(userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User verification rejected successfully'),
          backgroundColor: Color(0xFFe53e3e),
        ),
      );
      
      // Refresh the data
      _loadPendingVerifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
