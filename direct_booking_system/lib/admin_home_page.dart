import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signin_page.dart';
import 'theme/app_theme.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;
  
  List<Widget> get _pages => [
    AdminDashboard(context: context),
    const UserManagementPage(),
    const SystemSettingsPage(),
    const AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, -8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 40,
              offset: const Offset(0, -15),
              spreadRadius: 0,
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
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF667eea),
          unselectedItemColor: Colors.grey[600],
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
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  final BuildContext context;
  const AdminDashboard({Key? key, required this.context}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(),
              const SizedBox(height: 30),
              
              // Stats Cards
              _buildStatsSection(),
              const SizedBox(height: 30),
              
              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 30),
              
              // Recent Activities
              _buildRecentActivities(),
              const SizedBox(height: 30),
              
              // System Status
              _buildSystemStatus(),
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
        // Admin Avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.2),
                blurRadius: 35,
                offset: const Offset(0, 15),
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.admin_panel_settings,
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
                  color: Color(0xFF4a5568),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              (_uid == null)
                  ? const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d3748),
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
                              color: Color(0xFF2d3748),
                            ),
                          );
                        }
                        final data = snapshot.data?.data() as Map<String, dynamic>?;
                        final String name = (data?['name'] as String?) ?? 'Admin';
                        return Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3748),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 4),
              Text(
                'System Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3748),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your platform efficiently',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Notification Icon and Menu
        Row(
          children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Handle notifications
            },
          ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'logout') {
                    try {
                      await FirebaseService().signOut();
                      if (this.context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          this.context,
                          MaterialPageRoute(builder: (context) => const SigninPage()),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (this.context.mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
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
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people,
                title: 'Total Users',
                value: '2,847',
                color: const Color(0xFF667eea),
                change: '+12%',
                isPositive: true,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                icon: Icons.explore,
                title: 'Active Tours',
                value: '156',
                color: const Color(0xFF48bb78),
                change: '+8%',
                isPositive: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.book_online,
                title: 'Bookings',
                value: '1,234',
                color: const Color(0xFFed8936),
                change: '+15%',
                isPositive: true,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                icon: Icons.attach_money,
                title: 'Revenue',
                value: '\$45,678',
                color: const Color(0xFFe53e3e),
                change: '+23%',
                isPositive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String change,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 35,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          // Add a subtle colored shadow based on the card's color
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive 
                      ? const Color(0xFF48bb78).withOpacity(0.1)
                      : const Color(0xFFe53e3e).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? const Color(0xFF48bb78) : const Color(0xFFe53e3e),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? const Color(0xFF48bb78) : const Color(0xFFe53e3e),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
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
              child: _buildActionCard(
                icon: Icons.person_add,
                title: 'Add User',
                subtitle: 'Create new user account',
                color: const Color(0xFF667eea),
                onTap: () {
                  // Handle add user
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionCard(
                icon: Icons.verified_user,
                title: 'Verify Guide',
                subtitle: 'Approve tour guides',
                color: const Color(0xFF48bb78),
                onTap: () {
                  // Handle verify guide
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: 'Analytics',
                subtitle: 'View detailed reports',
                color: const Color(0xFFed8936),
                onTap: () {
                  // Handle analytics
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionCard(
                icon: Icons.support_agent,
                title: 'Support',
                subtitle: 'Handle user issues',
                color: const Color(0xFFe53e3e),
                onTap: () {
                  // Handle support
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 35,
              offset: const Offset(0, 12),
              spreadRadius: 0,
            ),
            // Add a subtle colored shadow based on the card's color
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 25,
              offset: const Offset(0, 8),
              spreadRadius: 0,
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2d3748),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3748),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all activities
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
        _buildActivityCard(
          icon: Icons.person_add,
          title: 'New User Registered',
          subtitle: 'John Doe joined as a tourist',
          time: '2 minutes ago',
          color: const Color(0xFF667eea),
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          icon: Icons.verified_user,
          title: 'Guide Verified',
          subtitle: 'Sarah Johnson approved as tour guide',
          time: '15 minutes ago',
          color: const Color(0xFF48bb78),
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          icon: Icons.book_online,
          title: 'New Booking',
          subtitle: 'Mountain Adventure booked by Emma Wilson',
          time: '1 hour ago',
          color: const Color(0xFFed8936),
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          // Add a subtle colored shadow based on the activity's color
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 7),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              color: color,
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2d3748),
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
                const SizedBox(height: 4),
                Text(
                  time,
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

  Widget _buildSystemStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Status',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2d3748),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 22,
                offset: const Offset(0, 7),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 38,
                offset: const Offset(0, 14),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStatusItem(
                title: 'Server Status',
                status: 'Online',
                isOnline: true,
              ),
              const SizedBox(height: 12),
              _buildStatusItem(
                title: 'Database',
                status: 'Connected',
                isOnline: true,
              ),
              const SizedBox(height: 12),
              _buildStatusItem(
                title: 'API Services',
                status: 'Running',
                isOnline: true,
              ),
              const SizedBox(height: 12),
              _buildStatusItem(
                title: 'Payment Gateway',
                status: 'Active',
                isOnline: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem({
    required String title,
    required String status,
    required bool isOnline,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isOnline ? const Color(0xFF48bb78) : const Color(0xFFe53e3e),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2d3748),
            ),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isOnline ? const Color(0xFF48bb78) : const Color(0xFFe53e3e),
          ),
        ),
      ],
    );
  }
}

// Placeholder pages for other tabs
class UserManagementPage extends StatelessWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('User Management Page - Coming Soon'),
      ),
    );
  }
}

class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('System Settings Page - Coming Soon'),
      ),
    );
  }
}

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Admin Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3748),
                ),
              ),
              const SizedBox(height: 30),
              
              // Profile Card
              _buildProfileCard(context),
              const SizedBox(height: 30),
              
              // Settings Section
              _buildSettingsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final FirebaseService _firebaseService = FirebaseService();
    final String? _uid = _firebaseService.currentUser?.uid;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 45,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Admin Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.5),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 45,
                  offset: const Offset(0, 20),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          
          // Admin Name
          (_uid == null)
              ? const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3748),
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
                          color: Color(0xFF2d3748),
                        ),
                      );
                    }
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final String name = (data?['name'] as String?) ?? 'Admin';
                    return Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d3748),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 8),
          
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Administrator',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF667eea),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2d3748),
          ),
        ),
        const SizedBox(height: 16),
        
        // Logout Option
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 35,
                offset: const Offset(0, 12),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFe53e3e).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout,
                color: Color(0xFFe53e3e),
                size: 20,
              ),
            ),
            title: const Text(
              'Log Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2d3748),
              ),
            ),
            subtitle: const Text(
              'Sign out from your admin account',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF718096),
            ),
            onTap: () async {
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
            },
          ),
        ),
      ],
    );
  }
}

