import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({Key? key}) : super(key: key);

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _selectedTab = 'all'; // all, active, guides, tourists, admins
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
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people,
                  color: Color(0xFF667eea),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage all users in the system',
                      style: TextStyle(
                        fontSize: 14,
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
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
    return Container(
      padding: const EdgeInsets.all(20),
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
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[500],
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // User Category Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabChip('All Users', 'all', _selectedTab, (value) {
                  setState(() {
                    _selectedTab = value;
                  });
                }),
                const SizedBox(width: 12),
                _buildTabChip('Active', 'active', _selectedTab, (value) {
                  setState(() {
                    _selectedTab = value;
                  });
                }),
                const SizedBox(width: 12),
                _buildTabChip('Guides', 'guides', _selectedTab, (value) {
                  setState(() {
                    _selectedTab = value;
                  });
                }),
                const SizedBox(width: 12),
                _buildTabChip('Tourists', 'tourists', _selectedTab, (value) {
                  setState(() {
                    _selectedTab = value;
                  });
                }),
                const SizedBox(width: 12),
                _buildTabChip('Admins', 'admins', _selectedTab, (value) {
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
    String title = 'All Users';
    String subtitle = 'Showing all users in the system';
    Color titleColor = const Color(0xFF667eea);
    IconData titleIcon = Icons.people;
    
    switch (_selectedTab) {
      case 'active':
        title = 'Active Users';
        subtitle = 'Showing active users only';
        titleColor = const Color(0xFF48bb78);
        titleIcon = Icons.check_circle;
        break;
      case 'guides':
        title = 'Tour Guides';
        subtitle = 'Professional tour guides offering services';
        titleColor = const Color(0xFF667eea);
        titleIcon = Icons.explore;
        break;
      case 'tourists':
        title = 'Tourists';
        subtitle = 'Travelers booking tour services';
        titleColor = const Color(0xFF48bb78);
        titleIcon = Icons.person;
        break;
      case 'admins':
        title = 'Administrators';
        subtitle = 'System administrators and moderators';
        titleColor = const Color(0xFFed8936);
        titleIcon = Icons.admin_panel_settings;
        break;
      default:
        title = 'All Users';
        subtitle = 'Showing all users in the system';
        titleColor = const Color(0xFF667eea);
        titleIcon = Icons.people;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: titleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              titleIcon,
              color: titleColor,
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
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
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            fontSize: 14,
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

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userData = user.data() as Map<String, dynamic>;
            return _buildUserCard(user.id, userData);
          },
        );
      },
    );
  }

  List<DocumentSnapshot> _applyFilters(List<DocumentSnapshot> users) {
    return users.where((user) {
      final userData = user.data() as Map<String, dynamic>;
      final name = (userData['name'] ?? '').toString().toLowerCase();
      final email = (userData['email'] ?? '').toString().toLowerCase();
      final role = (userData['role'] ?? '').toString().toLowerCase();
      final status = (userData['status'] ?? 'active').toString().toLowerCase();

      // Search filter
      if (_searchQuery.isNotEmpty) {
        if (!name.contains(_searchQuery) && 
            !email.contains(_searchQuery)) {
          return false;
        }
      }

      // Tab filter
      switch (_selectedTab) {
        case 'active':
          if (status != 'active') return false;
          break;
        case 'guides':
          if (role != 'guide') return false;
          break;
        case 'tourists':
          if (role != 'tourist') return false;
          break;
        case 'admins':
          if (role != 'admin') return false;
          break;
        case 'all':
        default:
          // Show all users regardless of role or status
          break;
      }

      return true;
    }).toList();
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> userData) {
    final name = userData['name'] ?? 'Unknown';
    final email = userData['email'] ?? 'No email';
    final role = userData['role'] ?? 'user';
    final status = userData['status'] ?? 'active';
    final profileImageUrl = userData['profileImageUrl'];
    final createdAt = userData['createdAt'] as Timestamp?;
    final lastLogin = userData['lastLogin'] as Timestamp?;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'active':
        statusColor = const Color(0xFF48bb78);
        statusIcon = Icons.check_circle;
        break;
      case 'disabled':
        statusColor = const Color(0xFFe53e3e);
        statusIcon = Icons.block;
        break;
      case 'pending':
        statusColor = const Color(0xFFed8936);
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = const Color(0xFF667eea);
        statusIcon = Icons.help;
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

    // Show detailed guide information when on guides tab
    if (_selectedTab == 'guides' && role.toLowerCase() == 'guide') {
      return _buildDetailedGuideCard(userId, userData, name, email, role, status, 
          profileImageUrl, createdAt, lastLogin, roleColor, roleIcon, statusColor, statusIcon);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Profile Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: roleColor.withOpacity(0.1),
                  ),
                  child: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(
                            profileImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                roleIcon,
                                color: roleColor,
                                size: 24,
                              );
                            },
                          ),
                        )
                      : Icon(
                          roleIcon,
                          color: roleColor,
                          size: 24,
                        ),
                ),
                
                const SizedBox(width: 16),
                
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2d3748),
                              ),
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  color: statusColor,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (createdAt != null)
                            Text(
                              'Joined ${_formatDate(createdAt.toDate())}',
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
                
                // Actions Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 20,
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
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          const Text('Edit User'),
                        ],
                      ),
                    ),
                    if (status == 'active')
                      PopupMenuItem(
                        value: 'disable',
                        child: Row(
                          children: [
                            Icon(Icons.block, size: 16, color: Colors.red[600]),
                            const SizedBox(width: 8),
                            Text('Disable User', style: TextStyle(color: Colors.red[600])),
                          ],
                        ),
                      ),
                    if (status == 'disabled')
                      PopupMenuItem(
                        value: 'enable',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Text('Enable User', style: TextStyle(color: Colors.green[600])),
                          ],
                        ),
                      ),
                    if (role == 'guide' && status == 'pending')
                      PopupMenuItem(
                        value: 'approve',
                        child: Row(
                          children: [
                            Icon(Icons.verified_user, size: 16, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Text('Approve Guide', style: TextStyle(color: Colors.green[600])),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          Text('Delete User', style: TextStyle(color: Colors.red[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Additional Info (if needed)
            if (lastLogin != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last login: ${_formatDate(lastLogin.toDate())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleUserAction(String action, String userId, Map<String, dynamic> userData) {
    switch (action) {
      case 'view':
        _showUserDetails(userId, userData);
        break;
      case 'edit':
        _editUser(userId, userData);
        break;
      case 'disable':
        _toggleUserStatus(userId, 'disabled');
        break;
      case 'enable':
        _toggleUserStatus(userId, 'active');
        break;
      case 'approve':
        _approveGuide(userId);
        break;
      case 'delete':
        _deleteUser(userId, userData['name'] ?? 'User');
        break;
    }
  }

  void _showUserDetails(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', userData['name'] ?? 'Unknown'),
              _buildDetailRow('Email', userData['email'] ?? 'No email'),
              _buildDetailRow('Role', userData['role'] ?? 'user'),
              _buildDetailRow('Status', userData['status'] ?? 'active'),
              _buildDetailRow('Phone', userData['phone'] ?? 'Not provided'),
              if (userData['createdAt'] != null)
                _buildDetailRow('Joined', _formatDate((userData['createdAt'] as Timestamp).toDate())),
              if (userData['lastLogin'] != null)
                _buildDetailRow('Last Login', _formatDate((userData['lastLogin'] as Timestamp).toDate())),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  void _editUser(String userId, Map<String, dynamic> userData) {
    // TODO: Implement user editing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User editing functionality coming soon'),
        backgroundColor: Color(0xFF667eea),
      ),
    );
  }

  void _toggleUserStatus(String userId, String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newStatus == 'disabled' ? 'Disable' : 'Enable'} User'),
        content: Text(
          'Are you sure you want to ${newStatus == 'disabled' ? 'disable' : 'enable'} this user?',
        ),
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
                    .update({'status': newStatus});
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User ${newStatus == 'disabled' ? 'disabled' : 'enabled'} successfully'),
                      backgroundColor: const Color(0xFF48bb78),
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
            child: Text(
              newStatus == 'disabled' ? 'Disable' : 'Enable',
              style: TextStyle(
                color: newStatus == 'disabled' ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _approveGuide(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Guide'),
        content: const Text('Are you sure you want to approve this guide?'),
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
                    .update({'status': 'active'});
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Guide approved successfully'),
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

  void _deleteUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $userName? This action cannot be undone.'),
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
                    .delete();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
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
              'Delete',
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
      case 'active':
        title = 'No active users found';
        subtitle = 'No active users match your search criteria';
        icon = Icons.check_circle_outline;
        break;
      case 'guides':
        title = 'No guides found';
        subtitle = 'No tour guides match your search criteria';
        icon = Icons.explore_outlined;
        break;
      case 'tourists':
        title = 'No tourists found';
        subtitle = 'No tourists match your search criteria';
        icon = Icons.person_outline;
        break;
      case 'admins':
        title = 'No admins found';
        subtitle = 'No administrators match your search criteria';
        icon = Icons.admin_panel_settings_outlined;
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

  Widget _buildDetailedGuideCard(String userId, Map<String, dynamic> userData, 
      String name, String email, String role, String status, String? profileImageUrl, 
      Timestamp? createdAt, Timestamp? lastLogin, Color roleColor, IconData roleIcon, 
      Color statusColor, IconData statusIcon) {
    
    // Extract guide-specific information
    final phone = userData['phone'] ?? 'Not provided';
    final bio = userData['bio'] ?? 'No bio available';
    final location = userData['location'] ?? 'Not specified';
    final languages = userData['languages'] ?? [];
    final specialties = userData['specialties'] ?? [];
    final experience = userData['experience'] ?? 'Not specified';
    final hourlyRate = userData['hourlyRate'] ?? 'Not set';
    final nicImageUrl = userData['nicImageUrl'];
    final drivingLicenseImageUrl = userData['drivingLicenseImageUrl'];
    final policeReportImageUrl = userData['policeReportImageUrl'];
    final isVerified = userData['isVerified'] ?? false;
    final rating = userData['rating'] ?? 0.0;
    final totalReviews = userData['totalReviews'] ?? 0;
    final totalTrips = userData['totalTrips'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                // Profile Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: roleColor.withOpacity(0.1),
                  ),
                  child: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.network(
                            profileImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                roleIcon,
                                color: roleColor,
                                size: 28,
                              );
                            },
                          ),
                        )
                      : Icon(
                          roleIcon,
                          color: roleColor,
                          size: 28,
                        ),
                ),
                
                const SizedBox(width: 16),
                
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2d3748),
                              ),
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  color: statusColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Actions Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 24,
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
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          const Text('Edit Guide'),
                        ],
                      ),
                    ),
                    if (status == 'active')
                      PopupMenuItem(
                        value: 'disable',
                        child: Row(
                          children: [
                            Icon(Icons.block, size: 16, color: Colors.red[600]),
                            const SizedBox(width: 8),
                            Text('Disable Guide', style: TextStyle(color: Colors.red[600])),
                          ],
                        ),
                      ),
                    if (status == 'disabled')
                      PopupMenuItem(
                        value: 'enable',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Text('Enable Guide', style: TextStyle(color: Colors.green[600])),
                          ],
                        ),
                      ),
                    if (status == 'pending')
                      PopupMenuItem(
                        value: 'approve',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Text('Approve Guide', style: TextStyle(color: Colors.green[600])),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          Text('Delete Guide', style: TextStyle(color: Colors.red[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Verification Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isVerified ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isVerified ? Colors.green[200]! : Colors.orange[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isVerified ? Icons.verified : Icons.pending_actions,
                    color: isVerified ? Colors.green[600] : Colors.orange[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isVerified ? 'Verified Guide' : 'Pending Verification',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isVerified ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Performance Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Rating',
                    rating.toStringAsFixed(1),
                    Icons.star,
                    Colors.amber[600]!,
                    '$totalReviews reviews',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Trips',
                    totalTrips.toString(),
                    Icons.explore,
                    Colors.blue[600]!,
                    'Total trips',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Rate',
                    hourlyRate.toString(),
                    Icons.attach_money,
                    Colors.green[600]!,
                    'Per hour',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Bio Section
            if (bio.isNotEmpty && bio != 'No bio available') ...[
              Text(
                'About',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bio,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Location and Experience
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Location',
                    location,
                    Icons.location_on,
                    Colors.red[600]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'Experience',
                    experience,
                    Icons.work,
                    Colors.purple[600]!,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Languages and Specialties
            if (languages.isNotEmpty) ...[
              _buildTagsSection('Languages', languages, Icons.language, Colors.blue[600]!),
              const SizedBox(height: 12),
            ],
            
            if (specialties.isNotEmpty) ...[
              _buildTagsSection('Specialties', specialties, Icons.star, Colors.orange[600]!),
              const SizedBox(height: 16),
            ],
            
            // Document Status
            _buildDocumentStatusSection(nicImageUrl, drivingLicenseImageUrl, policeReportImageUrl),
            
            const SizedBox(height: 12),
            
            // Account Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Joined ${createdAt != null ? _formatDate(createdAt.toDate()) : 'Unknown'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (lastLogin != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.login,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last login: ${_formatDate(lastLogin.toDate())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(String title, List<dynamic> tags, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              tag.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildDocumentStatusSection(String? nicImageUrl, String? drivingLicenseImageUrl, String? policeReportImageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDocumentStatus('NIC', nicImageUrl, Icons.credit_card),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDocumentStatus('License', drivingLicenseImageUrl, Icons.drive_eta),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDocumentStatus('Police Report', policeReportImageUrl, Icons.description),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentStatus(String title, String? imageUrl, IconData icon) {
    final hasDocument = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: hasDocument ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasDocument ? Colors.green[200]! : Colors.red[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            hasDocument ? Icons.check_circle : Icons.cancel,
            color: hasDocument ? Colors.green[600] : Colors.red[600],
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: hasDocument ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}
