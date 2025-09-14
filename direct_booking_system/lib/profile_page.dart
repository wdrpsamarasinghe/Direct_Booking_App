import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _profileImageUrl;
  String? _userName;
  String? _userBio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;

      print('🔍 Loading profile data for user: ${user.uid}');
      
      final profileData = await _firebaseService.getUserProfile(user.uid);
      
      if (mounted) {
        setState(() {
          _profileImageUrl = profileData?['profileImageUrl'];
          _userName = profileData?['name'] ?? 'User';
          _userBio = profileData?['bio'] ?? 'Professional Tour Guide';
          _isLoading = false;
        });
      }
      
      print('📸 Profile image URL: $_profileImageUrl');
      print('👤 User name: $_userName');
    } catch (e) {
      print('❌ Error loading profile data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFf7fafc),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(),
              
              const SizedBox(height: 20),
              
              // Stats Section
              _buildStatsSection(),
              
              const SizedBox(height: 20),
              
              // Profile Options
              _buildProfileOptions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(56),
              child: _profileImageUrl != null
                  ? Image.network(
                      _profileImageUrl!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Name and Title
          Text(
            _userName ?? 'User',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _userBio ?? 'Professional Tour Guide',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Contact Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildContactItem(
                icon: Icons.email,
                text: 'sarah.johnson@email.com',
              ),
              const SizedBox(width: 20),
              _buildContactItem(
                icon: Icons.phone,
                text: '+1 (555) 123-4567',
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Edit Profile Button
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: TextButton.icon(
              onPressed: () {
                // Handle edit profile
              },
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
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

  Widget _buildContactItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.calendar_today,
              title: 'Tours Completed',
              value: '156',
              color: const Color(0xFF667eea),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              icon: Icons.people,
              title: 'Happy Clients',
              value: '1,234',
              color: const Color(0xFF48bb78),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star,
              title: 'Average Rating',
              value: '4.8',
              color: const Color(0xFFed8936),
            ),
          ),
        ],
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildOptionCard(
            icon: Icons.work_outline,
            title: 'My Tours',
            subtitle: 'Manage your tour offerings',
            onTap: () {
              // Navigate to tours
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            icon: Icons.schedule,
            title: 'Schedule',
            subtitle: 'View and manage bookings',
            onTap: () {
              // Navigate to schedule
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            icon: Icons.analytics_outlined,
            title: 'Analytics',
            subtitle: 'View performance insights',
            onTap: () {
              // Navigate to analytics
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            icon: Icons.message_outlined,
            title: 'Messages',
            subtitle: 'Chat with clients',
            onTap: () {
              // Navigate to messages
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            icon: Icons.payment,
            title: 'Payments',
            subtitle: 'Manage earnings and payouts',
            onTap: () {
              // Navigate to payments
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              // Navigate to help
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Log out of your account',
            onTap: () {
              // Handle sign out
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDestructive 
                    ? const Color(0xFFe53e3e).withOpacity(0.1)
                    : const Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive 
                    ? const Color(0xFFe53e3e)
                    : const Color(0xFF667eea),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive 
                          ? const Color(0xFFe53e3e)
                          : const Color(0xFF2d3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

