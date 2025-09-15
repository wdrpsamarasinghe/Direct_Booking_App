import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';
import 'user_detail_view_page.dart';

class AdminVerificationPage extends StatefulWidget {
  const AdminVerificationPage({Key? key}) : super(key: key);

  @override
  State<AdminVerificationPage> createState() => _AdminVerificationPageState();
}

class _AdminVerificationPageState extends State<AdminVerificationPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _selectedTab = 'pending'; // pending, verified, rejected
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(),
            
            // Search and Filter Section
            _buildSearchAndFilter(),
            
            // Category Title Section
            _buildCategoryTitle(),
            
            // Users List
            Expanded(
              child: _buildUsersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600 ? 32 : 20,
        vertical: MediaQuery.of(context).size.width > 600 ? 24 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
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
                padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 16 : 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.verified_user,
                  color: const Color(0xFF667eea),
                  size: MediaQuery.of(context).size.width > 600 ? 28 : 24,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width > 600 ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Verification',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 600 ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2d3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verify and approve user profiles',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  iconSize: MediaQuery.of(context).size.width > 600 ? 28 : 24,
                  icon: _isLoading 
                      ? SizedBox(
                          width: MediaQuery.of(context).size.width > 600 ? 24 : 20,
                          height: MediaQuery.of(context).size.width > 600 ? 24 : 20,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _isLoading = true;
                    });
                    // Simulate refresh
                    Future.delayed(const Duration(seconds: 1), () {
                      setState(() {
                        _isLoading = false;
                      });
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : 20,
        vertical: isTablet ? 24 : 20,
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
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
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name, email...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: isTablet ? 16 : 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[500],
                  size: isTablet ? 24 : 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 16,
                  vertical: isTablet ? 16 : 12,
                ),
              ),
            ),
          ),
          
          SizedBox(height: isTablet ? 24 : 20),
          
          // Verification Status Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabChip('Pending', 'pending', _selectedTab, (value) {
                  setState(() {
                    _selectedTab = value;
                  });
                }),
                SizedBox(width: isTablet ? 16 : 12),
                _buildTabChip('Verified', 'verified', _selectedTab, (value) {
                  setState(() {
                    _selectedTab = value;
                  });
                }),
                SizedBox(width: isTablet ? 16 : 12),
                _buildTabChip('Rejected', 'rejected', _selectedTab, (value) {
                  setState(() {
                    _selectedTab = value;
                  });
                }),
                SizedBox(width: isTablet ? 16 : 12),
                _buildTabChip('All', 'all', _selectedTab, (value) {
                  setState(() {
                    _selectedTab = value;
                  });
                }),
              ],
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildCategoryTitle() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    String title = 'Pending Verification';
    String subtitle = 'Users waiting for verification';
    Color titleColor = const Color(0xFFed8936);
    IconData titleIcon = Icons.pending_actions;
    
    switch (_selectedTab) {
      case 'verified':
        title = 'Verified Users';
        subtitle = 'Successfully verified users';
        titleColor = const Color(0xFF48bb78);
        titleIcon = Icons.verified;
        break;
      case 'rejected':
        title = 'Rejected Users';
        subtitle = 'Users whose verification was rejected';
        titleColor = const Color(0xFFe53e3e);
        titleIcon = Icons.cancel;
        break;
      case 'all':
        title = 'All Users';
        subtitle = 'All users regardless of verification status';
        titleColor = const Color(0xFF667eea);
        titleIcon = Icons.people;
        break;
      default:
        title = 'Pending Verification';
        subtitle = 'Users waiting for verification';
        titleColor = const Color(0xFFed8936);
        titleIcon = Icons.pending_actions;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : 20,
        vertical: isTablet ? 20 : 16,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: titleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              titleIcon,
              color: titleColor,
              size: isTablet ? 28 : 24,
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, String value, String selectedValue, Function(String) onSelected) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSelected = selectedValue == value;
    
    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 28 : 24,
          vertical: isTablet ? 14 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF667eea) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF667eea) : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        List<DocumentSnapshot> users = snapshot.data!.docs;
        
        // Apply filters
        users = _applyFilters(users);

        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;
        final isDesktop = screenWidth > 1024;
        
        if (isDesktop) {
          // Desktop: Show cards in a grid layout
          return GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              return _buildUserCard(user.id, userData);
            },
          );
        } else {
          // Mobile/Tablet: Show cards in a list
        return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userData = user.data() as Map<String, dynamic>;
            return _buildUserCard(user.id, userData);
          },
        );
        }
      },
    );
  }

  List<DocumentSnapshot> _applyFilters(List<DocumentSnapshot> users) {
    return users.where((user) {
      final userData = user.data() as Map<String, dynamic>;
      final name = (userData['name'] ?? '').toString().toLowerCase();
      final email = (userData['email'] ?? '').toString().toLowerCase();
      final verificationStatus = (userData['verificationStatus'] ?? 'pending').toString().toLowerCase();

      // Search filter
      if (_searchQuery.isNotEmpty) {
        if (!name.contains(_searchQuery) && 
            !email.contains(_searchQuery)) {
          return false;
        }
      }

      // Tab filter
      switch (_selectedTab) {
        case 'pending':
          if (verificationStatus != 'pending') return false;
          break;
        case 'verified':
          if (verificationStatus != 'verified') return false;
          break;
        case 'rejected':
          if (verificationStatus != 'rejected') return false;
          break;
        case 'all':
        default:
          // Show all users regardless of verification status
          break;
      }

      return true;
    }).toList();
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> userData) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    
    final name = userData['name'] ?? 'Unknown';
    final email = userData['email'] ?? 'No email';
    final role = userData['role'] ?? 'user';
    final verificationStatus = userData['verificationStatus'] ?? 'pending';
    final profileImageUrl = userData['profileImageUrl'];
    final createdAt = userData['createdAt'] as Timestamp?;
    final phone = userData['phone'] ?? 'Not provided';
    final bio = userData['bio'] ?? 'No bio available';
    final location = userData['location'] ?? 'Not specified';

    Color verificationColor;
    IconData verificationIcon;
    String verificationText;
    
    switch (verificationStatus) {
      case 'verified':
        verificationColor = const Color(0xFF48bb78);
        verificationIcon = Icons.verified;
        verificationText = 'VERIFIED';
        break;
      case 'rejected':
        verificationColor = const Color(0xFFe53e3e);
        verificationIcon = Icons.cancel;
        verificationText = 'REJECTED';
        break;
      default:
        verificationColor = const Color(0xFFed8936);
        verificationIcon = Icons.pending_actions;
        verificationText = 'PENDING';
    }

    Color roleColor;
    IconData roleIcon;
    switch (role) {
      case 'guide':
        roleColor = const Color(0xFF667eea);
        roleIcon = Icons.explore;
        break;
      case 'tourist':
        roleColor = const Color(0xFF48bb78);
        roleIcon = Icons.person;
        break;
      case 'admin':
        roleColor = const Color(0xFFed8936);
        roleIcon = Icons.admin_panel_settings;
        break;
      default:
        roleColor = const Color(0xFF718096);
        roleIcon = Icons.person_outline;
    }

    // Special design for all verification statuses
    if (verificationStatus == 'pending') {
      return _buildPendingUserCard(
        userId, userData, name, email, role, profileImageUrl, 
        createdAt, phone, bio, location, roleColor, roleIcon,
        screenWidth, isTablet, isDesktop
      );
    } else if (verificationStatus == 'verified') {
      return _buildVerifiedUserCard(
        userId, userData, name, email, role, profileImageUrl, 
        createdAt, phone, bio, location, roleColor, roleIcon,
        screenWidth, isTablet, isDesktop
      );
    } else if (verificationStatus == 'rejected') {
      return _buildRejectedUserCard(
        userId, userData, name, email, role, profileImageUrl, 
        createdAt, phone, bio, location, roleColor, roleIcon,
        screenWidth, isTablet, isDesktop
      );
    }

    return GestureDetector(
      onTap: () => _showUserDetails(userId, userData),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
                blurRadius: isTablet ? 24 : 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
                blurRadius: isTablet ? 36 : 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                // Profile Image
                Container(
                      width: isTablet ? 70 : 60,
                      height: isTablet ? 70 : 60,
                  decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(isTablet ? 35 : 30),
                    color: roleColor.withOpacity(0.1),
                  ),
                  child: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? ClipRRect(
                              borderRadius: BorderRadius.circular(isTablet ? 35 : 30),
                          child: Image.network(
                            profileImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                roleIcon,
                                color: roleColor,
                                    size: isTablet ? 32 : 28,
                              );
                            },
                          ),
                        )
                      : Icon(
                          roleIcon,
                          color: roleColor,
                              size: isTablet ? 32 : 28,
                        ),
                ),
                
                    SizedBox(width: isTablet ? 20 : 16),
                
                // Basic Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2d3748),
                              ),
                            ),
                          ),
                          // Verification Status Badge
                          Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 8 : 6,
                                ),
                            decoration: BoxDecoration(
                              color: verificationColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  verificationIcon,
                                  color: verificationColor,
                                      size: isTablet ? 16 : 14,
                                ),
                                    SizedBox(width: isTablet ? 8 : 6),
                                Text(
                                  verificationText,
                                  style: TextStyle(
                                        fontSize: isTablet ? 12 : 11,
                                    fontWeight: FontWeight.w700,
                                    color: verificationColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                          SizedBox(height: isTablet ? 8 : 6),
                      Text(
                        email,
                        style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                          SizedBox(height: isTablet ? 6 : 4),
                      Text(
                        phone,
                        style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // View Details Indicator
                    if (!isDesktop) ...[
                Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 10 : 8,
                          vertical: isTablet ? 6 : 4,
                        ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        color: const Color(0xFF667eea),
                              size: isTablet ? 16 : 14,
                      ),
                            SizedBox(width: isTablet ? 6 : 4),
                      Text(
                        'View Details',
                        style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF667eea),
                        ),
                      ),
                    ],
                  ),
                ),
                      SizedBox(width: isTablet ? 12 : 8),
                    ],
                
                // Actions Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                        size: isTablet ? 28 : 24,
                  ),
                  onSelected: (value) => _handleUserAction(value, userId, userData),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          const Text('View Details'),
                        ],
                      ),
                    ),
                    if (verificationStatus == 'pending') ...[
                      PopupMenuItem(
                        value: 'approve',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Text('Approve', style: TextStyle(color: Colors.green[600])),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'reject',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, size: 16, color: Colors.red[600]),
                            const SizedBox(width: 8),
                            Text('Reject', style: TextStyle(color: Colors.red[600])),
                          ],
                        ),
                      ),
                    ],
                    if (verificationStatus == 'verified')
                      PopupMenuItem(
                        value: 'reject',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, size: 16, color: Colors.red[600]),
                            const SizedBox(width: 8),
                            Text('Revoke Verification', style: TextStyle(color: Colors.red[600])),
                          ],
                        ),
                      ),
                    if (verificationStatus == 'rejected')
                      PopupMenuItem(
                        value: 'approve',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Text('Approve', style: TextStyle(color: Colors.green[600])),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
                SizedBox(height: isTablet ? 20 : 16),
            
            // Role Badge
            Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 14 : 12,
                    vertical: isTablet ? 8 : 6,
                  ),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    roleIcon,
                    color: roleColor,
                        size: isTablet ? 18 : 16,
                  ),
                      SizedBox(width: isTablet ? 8 : 6),
                  Text(
                    role.toUpperCase(),
                    style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: roleColor,
                    ),
                  ),
                ],
              ),
            ),
            
                SizedBox(height: isTablet ? 20 : 16),
            
            // Bio Section
            if (bio.isNotEmpty && bio != 'No bio available') ...[
              Text(
                'About',
                style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
                  SizedBox(height: isTablet ? 10 : 8),
              Text(
                bio,
                style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                    maxLines: isDesktop ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              ),
                  SizedBox(height: isTablet ? 20 : 16),
            ],
            
            // Location
            if (location.isNotEmpty && location != 'Not specified') ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.red[600],
                        size: isTablet ? 18 : 16,
                  ),
                      SizedBox(width: isTablet ? 10 : 8),
                  Text(
                    location,
                    style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
                  SizedBox(height: isTablet ? 20 : 16),
            ],
            
            // Document Status Summary
            if (role == 'guide' || role == 'tourist') ...[
                  SizedBox(height: isTablet ? 16 : 12),
              _buildDocumentStatusSummary(userData, role),
            ],
            
            // Document Images Preview
            if (role == 'guide' || role == 'tourist') ...[
                  SizedBox(height: isTablet ? 16 : 12),
              _buildDocumentImagesPreview(userData, role),
            ],
            
            // Account Info
            Container(
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                        size: isTablet ? 18 : 16,
                    color: Colors.grey[600],
                  ),
                      SizedBox(width: isTablet ? 10 : 8),
                  Text(
                    'Joined ${createdAt != null ? _formatDate(createdAt.toDate()) : 'Unknown'}',
                    style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Buttons for Pending Users
            if (verificationStatus == 'pending') ...[
                  SizedBox(height: isTablet ? 20 : 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleUserAction('approve', userId, userData),
                          icon: Icon(
                            Icons.check_circle,
                            size: isTablet ? 20 : 18,
                          ),
                          label: Text(
                            'Approve',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF48bb78),
                        foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 16 : 12,
                              horizontal: isTablet ? 20 : 16,
                            ),
                        shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                        ),
                      ),
                    ),
                  ),
                      SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleUserAction('reject', userId, userData),
                          icon: Icon(
                            Icons.cancel,
                            size: isTablet ? 20 : 18,
                          ),
                          label: Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFe53e3e),
                        foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 16 : 12,
                              horizontal: isTablet ? 20 : 16,
                            ),
                        shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingUserCard(
    String userId, 
    Map<String, dynamic> userData, 
    String name, 
    String email, 
    String role, 
    String? profileImageUrl, 
    Timestamp? createdAt, 
    String phone, 
    String bio, 
    String location, 
    Color roleColor, 
    IconData roleIcon,
    double screenWidth,
    bool isTablet,
    bool isDesktop
  ) {
    return GestureDetector(
      onTap: () => _showUserDetails(userId, userData),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: EdgeInsets.only(bottom: isTablet ? 24 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFed8936).withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            border: Border.all(
              color: const Color(0xFFed8936).withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFed8936).withOpacity(0.15),
                blurRadius: isTablet ? 30 : 25,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: isTablet ? 40 : 35,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              // Pending Status Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 20,
                  vertical: isTablet ? 16 : 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFed8936).withOpacity(0.1),
                      const Color(0xFFed8936).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isTablet ? 24 : 20),
                    topRight: Radius.circular(isTablet ? 24 : 20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 12 : 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFed8936).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                      ),
                      child: Icon(
                        Icons.pending_actions,
                        color: const Color(0xFFed8936),
                        size: isTablet ? 24 : 20,
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending Verification',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFed8936),
                            ),
                          ),
                          Text(
                            'Review required for approval',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: const Color(0xFFed8936).withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16 : 12,
                        vertical: isTablet ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFed8936),
                        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                      ),
                      child: Text(
                        'REVIEW',
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main Content
              Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                child: Column(
                  children: [
                    // User Info Section
                    Row(
                      children: [
                        // Profile Image with Role Badge
                        Stack(
                          children: [
                            Container(
                              width: isTablet ? 80 : 70,
                              height: isTablet ? 80 : 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(isTablet ? 40 : 35),
                                color: roleColor.withOpacity(0.1),
                                border: Border.all(
                                  color: roleColor.withOpacity(0.3),
                                  width: 3,
                                ),
                              ),
                              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(isTablet ? 40 : 35),
                                      child: Image.network(
                                        profileImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            roleIcon,
                                            color: roleColor,
                                            size: isTablet ? 36 : 32,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      roleIcon,
                                      color: roleColor,
                                      size: isTablet ? 36 : 32,
                                    ),
                            ),
                            // Role Badge
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 6 : 4),
                                decoration: BoxDecoration(
                                  color: roleColor,
                                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  roleIcon,
                                  color: Colors.white,
                                  size: isTablet ? 16 : 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(width: isTablet ? 20 : 16),
                        
                        // User Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: isTablet ? 22 : 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2d3748),
                                ),
                              ),
                              SizedBox(height: isTablet ? 8 : 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: isTablet ? 18 : 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: isTablet ? 8 : 6),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isTablet ? 6 : 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: isTablet ? 18 : 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: isTablet ? 8 : 6),
                                  Text(
                                    phone,
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Quick Actions
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF667eea).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.visibility,
                                  color: const Color(0xFF667eea),
                                  size: isTablet ? 24 : 20,
                                ),
                                onPressed: () => _showUserDetails(userId, userData),
                              ),
                            ),
                            SizedBox(height: isTablet ? 8 : 6),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.grey[600],
                                size: isTablet ? 24 : 20,
                              ),
                              onSelected: (value) => _handleUserAction(value, userId, userData),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      const Text('View Details'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'approve',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                                      const SizedBox(width: 8),
                                      Text('Approve', style: TextStyle(color: Colors.green[600])),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'reject',
                                  child: Row(
                                    children: [
                                      Icon(Icons.cancel, size: 16, color: Colors.red[600]),
                                      const SizedBox(width: 8),
                                      Text('Reject', style: TextStyle(color: Colors.red[600])),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Document Status & Location
                    Row(
                      children: [
                        // Document Status
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: Colors.blue[600],
                                  size: isTablet ? 20 : 18,
                                ),
                                SizedBox(width: isTablet ? 12 : 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Documents',
                                        style: TextStyle(
                                          fontSize: isTablet ? 14 : 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      Text(
                                        'Review required',
                                        style: TextStyle(
                                          fontSize: isTablet ? 12 : 10,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(width: isTablet ? 16 : 12),
                        
                        // Location
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.green[600],
                                  size: isTablet ? 20 : 18,
                                ),
                                SizedBox(width: isTablet ? 12 : 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Location',
                                        style: TextStyle(
                                          fontSize: isTablet ? 14 : 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      Text(
                                        location,
                                        style: TextStyle(
                                          fontSize: isTablet ? 12 : 10,
                                          color: Colors.green[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleUserAction('approve', userId, userData),
                            icon: Icon(
                              Icons.check_circle,
                              size: isTablet ? 22 : 20,
                            ),
                            label: Text(
                              'Approve User',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF48bb78),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 18 : 14,
                                horizontal: isTablet ? 24 : 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleUserAction('reject', userId, userData),
                            icon: Icon(
                              Icons.cancel,
                              size: isTablet ? 22 : 20,
                            ),
                            label: Text(
                              'Reject User',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFe53e3e),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 18 : 14,
                                horizontal: isTablet ? 24 : 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                              ),
                              elevation: 3,
                            ),
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
      ),
    );
  }

  Widget _buildVerifiedUserCard(
    String userId, 
    Map<String, dynamic> userData, 
    String name, 
    String email, 
    String role, 
    String? profileImageUrl, 
    Timestamp? createdAt, 
    String phone, 
    String bio, 
    String location, 
    Color roleColor, 
    IconData roleIcon,
    double screenWidth,
    bool isTablet,
    bool isDesktop
  ) {
    return GestureDetector(
      onTap: () => _showUserDetails(userId, userData),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: EdgeInsets.only(bottom: isTablet ? 24 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFF48bb78).withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            border: Border.all(
              color: const Color(0xFF48bb78).withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF48bb78).withOpacity(0.15),
                blurRadius: isTablet ? 30 : 25,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: isTablet ? 40 : 35,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              // Verified Status Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 20,
                  vertical: isTablet ? 16 : 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF48bb78).withOpacity(0.1),
                      const Color(0xFF48bb78).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isTablet ? 24 : 20),
                    topRight: Radius.circular(isTablet ? 24 : 20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 12 : 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF48bb78).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                      ),
                      child: Icon(
                        Icons.verified,
                        color: const Color(0xFF48bb78),
                        size: isTablet ? 24 : 20,
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verified User',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF48bb78),
                            ),
                          ),
                          Text(
                            'Successfully verified and approved',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: const Color(0xFF48bb78).withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16 : 12,
                        vertical: isTablet ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF48bb78),
                        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                      ),
                      child: Text(
                        'VERIFIED',
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main Content
              Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                child: Column(
                  children: [
                    // User Info Section
                    Row(
                      children: [
                        // Profile Image with Role Badge
                        Stack(
                          children: [
                            Container(
                              width: isTablet ? 80 : 70,
                              height: isTablet ? 80 : 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(isTablet ? 40 : 35),
                                color: roleColor.withOpacity(0.1),
                                border: Border.all(
                                  color: roleColor.withOpacity(0.3),
                                  width: 3,
                                ),
                              ),
                              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(isTablet ? 40 : 35),
                                      child: Image.network(
                                        profileImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            roleIcon,
                                            color: roleColor,
                                            size: isTablet ? 36 : 32,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      roleIcon,
                                      color: roleColor,
                                      size: isTablet ? 36 : 32,
                                    ),
                            ),
                            // Role Badge
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 6 : 4),
                                decoration: BoxDecoration(
                                  color: roleColor,
                                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  roleIcon,
                                  color: Colors.white,
                                  size: isTablet ? 16 : 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(width: isTablet ? 20 : 16),
                        
                        // User Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: isTablet ? 22 : 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2d3748),
                                ),
                              ),
                              SizedBox(height: isTablet ? 8 : 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: isTablet ? 18 : 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: isTablet ? 8 : 6),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isTablet ? 6 : 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: isTablet ? 18 : 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: isTablet ? 8 : 6),
                                  Text(
                                    phone,
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Quick Actions
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF667eea).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.visibility,
                                  color: const Color(0xFF667eea),
                                  size: isTablet ? 24 : 20,
                                ),
                                onPressed: () => _showUserDetails(userId, userData),
                              ),
                            ),
                            SizedBox(height: isTablet ? 8 : 6),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.grey[600],
                                size: isTablet ? 24 : 20,
                              ),
                              onSelected: (value) => _handleUserAction(value, userId, userData),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      const Text('View Details'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'reject',
                                  child: Row(
                                    children: [
                                      Icon(Icons.cancel, size: 16, color: Colors.red[600]),
                                      const SizedBox(width: 8),
                                      Text('Revoke Verification', style: TextStyle(color: Colors.red[600])),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Document Status & Location
                    Row(
                      children: [
                        // Document Status
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green[600],
                                  size: isTablet ? 20 : 18,
                                ),
                                SizedBox(width: isTablet ? 12 : 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Documents',
                                        style: TextStyle(
                                          fontSize: isTablet ? 14 : 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      Text(
                                        'Verified & approved',
                                        style: TextStyle(
                                          fontSize: isTablet ? 12 : 10,
                                          color: Colors.green[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(width: isTablet ? 16 : 12),
                        
                        // Location
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.blue[600],
                                  size: isTablet ? 20 : 18,
                                ),
                                SizedBox(width: isTablet ? 12 : 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Location',
                                        style: TextStyle(
                                          fontSize: isTablet ? 14 : 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      Text(
                                        location,
                                        style: TextStyle(
                                          fontSize: isTablet ? 12 : 10,
                                          color: Colors.blue[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleUserAction('reject', userId, userData),
                        icon: Icon(
                          Icons.cancel,
                          size: isTablet ? 22 : 20,
                        ),
                        label: Text(
                          'Revoke Verification',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFe53e3e),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 18 : 14,
                            horizontal: isTablet ? 24 : 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedUserCard(
    String userId, 
    Map<String, dynamic> userData, 
    String name, 
    String email, 
    String role, 
    String? profileImageUrl, 
    Timestamp? createdAt, 
    String phone, 
    String bio, 
    String location, 
    Color roleColor, 
    IconData roleIcon,
    double screenWidth,
    bool isTablet,
    bool isDesktop
  ) {
    return GestureDetector(
      onTap: () => _showUserDetails(userId, userData),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: EdgeInsets.only(bottom: isTablet ? 24 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFe53e3e).withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            border: Border.all(
              color: const Color(0xFFe53e3e).withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFe53e3e).withOpacity(0.15),
                blurRadius: isTablet ? 30 : 25,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: isTablet ? 40 : 35,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              // Rejected Status Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 20,
                  vertical: isTablet ? 16 : 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFe53e3e).withOpacity(0.1),
                      const Color(0xFFe53e3e).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isTablet ? 24 : 20),
                    topRight: Radius.circular(isTablet ? 24 : 20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 12 : 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe53e3e).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                      ),
                      child: Icon(
                        Icons.cancel,
                        color: const Color(0xFFe53e3e),
                        size: isTablet ? 24 : 20,
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rejected User',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFe53e3e),
                            ),
                          ),
                          Text(
                            'Verification was rejected',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: const Color(0xFFe53e3e).withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16 : 12,
                        vertical: isTablet ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe53e3e),
                        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                      ),
                      child: Text(
                        'REJECTED',
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main Content
              Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                child: Column(
                  children: [
                    // User Info Section
                    Row(
                      children: [
                        // Profile Image with Role Badge
                        Stack(
                          children: [
                            Container(
                              width: isTablet ? 80 : 70,
                              height: isTablet ? 80 : 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(isTablet ? 40 : 35),
                                color: roleColor.withOpacity(0.1),
                                border: Border.all(
                                  color: roleColor.withOpacity(0.3),
                                  width: 3,
                                ),
                              ),
                              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(isTablet ? 40 : 35),
                                      child: Image.network(
                                        profileImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            roleIcon,
                                            color: roleColor,
                                            size: isTablet ? 36 : 32,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      roleIcon,
                                      color: roleColor,
                                      size: isTablet ? 36 : 32,
                                    ),
                            ),
                            // Role Badge
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 6 : 4),
                                decoration: BoxDecoration(
                                  color: roleColor,
                                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  roleIcon,
                                  color: Colors.white,
                                  size: isTablet ? 16 : 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(width: isTablet ? 20 : 16),
                        
                        // User Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: isTablet ? 22 : 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2d3748),
                                ),
                              ),
                              SizedBox(height: isTablet ? 8 : 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: isTablet ? 18 : 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: isTablet ? 8 : 6),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isTablet ? 6 : 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: isTablet ? 18 : 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: isTablet ? 8 : 6),
                                  Text(
                                    phone,
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Quick Actions
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF667eea).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.visibility,
                                  color: const Color(0xFF667eea),
                                  size: isTablet ? 24 : 20,
                                ),
                                onPressed: () => _showUserDetails(userId, userData),
                              ),
                            ),
                            SizedBox(height: isTablet ? 8 : 6),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.grey[600],
                                size: isTablet ? 24 : 20,
                              ),
                              onSelected: (value) => _handleUserAction(value, userId, userData),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      const Text('View Details'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'approve',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                                      const SizedBox(width: 8),
                                      Text('Approve', style: TextStyle(color: Colors.green[600])),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Document Status & Location
                    Row(
                      children: [
                        // Document Status
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cancel,
                                  color: Colors.red[600],
                                  size: isTablet ? 20 : 18,
                                ),
                                SizedBox(width: isTablet ? 12 : 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Documents',
                                        style: TextStyle(
                                          fontSize: isTablet ? 14 : 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                      Text(
                                        'Rejected & needs review',
                                        style: TextStyle(
                                          fontSize: isTablet ? 12 : 10,
                                          color: Colors.red[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(width: isTablet ? 16 : 12),
                        
                        // Location
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.orange[600],
                                  size: isTablet ? 20 : 18,
                                ),
                                SizedBox(width: isTablet ? 12 : 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Location',
                                        style: TextStyle(
                                          fontSize: isTablet ? 14 : 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                      Text(
                                        location,
                                        style: TextStyle(
                                          fontSize: isTablet ? 12 : 10,
                                          color: Colors.orange[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleUserAction('approve', userId, userData),
                        icon: Icon(
                          Icons.check_circle,
                          size: isTablet ? 22 : 20,
                        ),
                        label: Text(
                          'Approve User',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF48bb78),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 18 : 14,
                            horizontal: isTablet ? 24 : 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUserAction(String action, String userId, Map<String, dynamic> userData) {
    switch (action) {
      case 'view':
        _showUserDetails(userId, userData);
        break;
      case 'approve':
        _approveUser(userId, userData);
        break;
      case 'reject':
        _rejectUser(userId, userData);
        break;
    }
  }

  void _showUserDetails(String userId, Map<String, dynamic> userData) {
    print('🔍 [ADMIN] Opening user details for user ID: $userId');
    print('🔍 [ADMIN] User name: ${userData['name']}');
    print('🔍 [ADMIN] User role: ${userData['role']}');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailViewPage(
          userId: userId,
          userData: userData,
          onVerificationChanged: () {
            // Refresh the verification list when returning
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2d3748),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _approveUser(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve User'),
        content: Text('Are you sure you want to approve ${userData['name'] ?? 'this user'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firebaseService.firestore
                    .collection('users')
                    .doc(userId)
                    .update({
                  'verificationStatus': 'verified',
                  'verifiedAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User approved successfully'),
                      backgroundColor: Color(0xFF48bb78),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: const Color(0xFFe53e3e),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Approve',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  void _rejectUser(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: Text('Are you sure you want to reject ${userData['name'] ?? 'this user'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firebaseService.firestore
                    .collection('users')
                    .doc(userId)
                    .update({
                  'verificationStatus': 'rejected',
                  'rejectedAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User rejected successfully'),
                      backgroundColor: Color(0xFFe53e3e),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: const Color(0xFFe53e3e),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading users...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading users',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String title = 'No users found';
    String subtitle = 'Try adjusting your search or filters';
    IconData icon = Icons.people_outline;
    
    switch (_selectedTab) {
      case 'pending':
        title = 'No pending users';
        subtitle = 'No users are waiting for verification';
        icon = Icons.pending_actions;
        break;
      case 'verified':
        title = 'No verified users';
        subtitle = 'No users have been verified yet';
        icon = Icons.verified;
        break;
      case 'rejected':
        title = 'No rejected users';
        subtitle = 'No users have been rejected';
        icon = Icons.cancel;
        break;
      default:
        title = 'No users found';
        subtitle = 'Try adjusting your search criteria';
        icon = Icons.people_outline;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStatusSummary(Map<String, dynamic> userData, String role) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    List<Map<String, dynamic>> documents = [];
    
    if (role == 'guide') {
      documents = [
        {
          'name': 'NIC',
          'url': userData['nicDocumentUrl'],
          'icon': Icons.credit_card,
        },
        {
          'name': 'License',
          'url': userData['drivingLicenceDocumentUrl'],
          'icon': Icons.drive_eta,
        },
        {
          'name': 'Police Report',
          'url': userData['policeReportDocumentUrl'],
          'icon': Icons.security,
        },
      ];
    } else if (role == 'tourist') {
      documents = [
        {
          'name': 'Passport',
          'url': userData['passportImageUrl'],
          'icon': Icons.card_membership,
        },
      ];
    }
    
    int uploadedCount = documents.where((doc) => doc['url'] != null && doc['url'].toString().isNotEmpty).length;
    int totalCount = documents.length;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: uploadedCount == totalCount ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        border: Border.all(
          color: uploadedCount == totalCount ? Colors.green[200]! : Colors.orange[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            uploadedCount == totalCount ? Icons.check_circle : Icons.warning,
            color: uploadedCount == totalCount ? Colors.green[600] : Colors.orange[600],
            size: isTablet ? 20 : 16,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Expanded(
            child: Text(
              'Documents: $uploadedCount/$totalCount uploaded',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: uploadedCount == totalCount ? Colors.green[700] : Colors.orange[700],
              ),
            ),
          ),
          if (uploadedCount < totalCount)
            Text(
              'Incomplete',
              style: TextStyle(
                fontSize: isTablet ? 12 : 10,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            )
          else
            Text(
              'Complete',
              style: TextStyle(
                fontSize: isTablet ? 12 : 10,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentImagesPreview(Map<String, dynamic> userData, String role) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    
    List<Map<String, dynamic>> documents = [];
    
    if (role == 'guide') {
      documents = [
        {
          'name': 'NIC Document',
          'url': userData['nicDocumentUrl'],
          'icon': Icons.credit_card,
          'color': const Color(0xFF667eea),
        },
        {
          'name': 'Driving License',
          'url': userData['drivingLicenceDocumentUrl'],
          'icon': Icons.drive_eta,
          'color': const Color(0xFF48bb78),
        },
        {
          'name': 'Police Report',
          'url': userData['policeReportDocumentUrl'],
          'icon': Icons.security,
          'color': const Color(0xFFed8936),
        },
      ];
    } else if (role == 'tourist') {
      documents = [
        {
          'name': 'Passport',
          'url': userData['passportImageUrl'],
          'icon': Icons.card_membership,
          'color': const Color(0xFF9f7aea),
        },
      ];
    }

    // Debug: Print document URLs
    print('🔍 [ADMIN] Document preview for role: $role');
    for (var doc in documents) {
      print('🔍 [ADMIN] ${doc['name']}: ${doc['url']}');
    }

    // Filter to only show documents that have URLs
    final uploadedDocuments = documents.where((doc) => 
        doc['url'] != null && doc['url'].toString().isNotEmpty).toList();
    
    print('🔍 [ADMIN] Uploaded documents count: ${uploadedDocuments.length}');

    if (uploadedDocuments.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey[600],
              size: isTablet ? 24 : 20,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'No identity documents uploaded yet',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isTablet ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: Colors.grey[700],
                size: isTablet ? 20 : 16,
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                'Identity Documents',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          // Show document images in a horizontal scrollable row
          SizedBox(
            height: isTablet ? 100 : 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: uploadedDocuments.length,
              itemBuilder: (context, index) {
                final doc = uploadedDocuments[index];
                return Container(
                  width: isTablet ? 100 : 80,
                  margin: EdgeInsets.only(right: index < uploadedDocuments.length - 1 ? (isTablet ? 16 : 12) : 0),
                  child: Column(
                    children: [
                      // Document image preview
                      GestureDetector(
                        onTap: () => _showDocumentImage(doc['name'], doc['url']),
                        child: Container(
                          width: isTablet ? 80 : 60,
                          height: isTablet ? 80 : 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                            border: Border.all(
                              color: doc['color'].withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                            child: _buildDocumentImagePreview(doc['url']),
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 6 : 4),
                      // Document name
                      Text(
                        doc['name'],
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentImagePreview(String? imageUrl) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[100],
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[400],
          size: isTablet ? 28 : 24,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[100],
          child: Center(
            child: SizedBox(
              width: isTablet ? 24 : 20,
              height: isTablet ? 24 : 20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[100],
          child: Icon(
            Icons.error_outline,
            color: Colors.grey[400],
            size: isTablet ? 28 : 24,
          ),
        );
      },
    );
  }

  void _showDocumentImage(String title, String imageUrl) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: isDesktop 
              ? MediaQuery.of(context).size.width * 0.7
              : MediaQuery.of(context).size.width * 0.9,
          height: isDesktop 
              ? MediaQuery.of(context).size.height * 0.9
              : MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isTablet ? 16 : 12),
                    topRight: Radius.circular(isTablet ? 16 : 12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        size: isTablet ? 28 : 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Image
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: isTablet ? 40 : 32,
                          height: isTablet ? 40 : 32,
                          child: const CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.grey[400],
                              size: isTablet ? 64 : 48,
                            ),
                            SizedBox(height: isTablet ? 20 : 16),
                            Text(
                              'Failed to load document',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: isTablet ? 12 : 8),
                            Text(
                              'URL: ${imageUrl.length > 50 ? '${imageUrl.substring(0, 50)}...' : imageUrl}',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
