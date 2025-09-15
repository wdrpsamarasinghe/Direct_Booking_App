import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';

class UserDetailViewPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final VoidCallback onVerificationChanged;

  const UserDetailViewPage({
    Key? key,
    required this.userId,
    required this.userData,
    required this.onVerificationChanged,
  }) : super(key: key);

  @override
  State<UserDetailViewPage> createState() => _UserDetailViewPageState();
}

class _UserDetailViewPageState extends State<UserDetailViewPage> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  Map<String, dynamic>? _detailedUserData;

  @override
  void initState() {
    super.initState();
    _loadDetailedUserData();
  }

  Future<void> _loadDetailedUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 [ADMIN] Loading detailed user data for user ID: ${widget.userId}');
      
      final doc = await _firebaseService.firestore
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        print('✅ [ADMIN] Successfully loaded user data for ID: ${widget.userId}');
        print('🔍 [ADMIN] User role: ${userData['role']}');
        print('🔍 [ADMIN] User name: ${userData['name']}');
        
        // Debug: Print all document-related fields
        print('🔍 [ADMIN] === DOCUMENT FIELDS DEBUG ===');
        print('🔍 [ADMIN] nicDocumentUrl: ${userData['nicDocumentUrl']}');
        print('🔍 [ADMIN] drivingLicenceDocumentUrl: ${userData['drivingLicenceDocumentUrl']}');
        print('🔍 [ADMIN] policeReportDocumentUrl: ${userData['policeReportDocumentUrl']}');
        print('🔍 [ADMIN] passportImageUrl: ${userData['passportImageUrl']}');
        print('🔍 [ADMIN] === END DOCUMENT FIELDS DEBUG ===');
        
        // Debug: Print all user data keys to see what's available
        print('🔍 [ADMIN] === ALL USER DATA KEYS ===');
        userData.keys.forEach((key) {
          print('🔍 [ADMIN] Key: $key = ${userData[key]}');
        });
        print('🔍 [ADMIN] === END ALL USER DATA KEYS ===');
        
        setState(() {
          _detailedUserData = userData;
          _isLoading = false;
        });
      } else {
        print('❌ [ADMIN] User document not found for ID: ${widget.userId}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [ADMIN] Error loading detailed user data for ID ${widget.userId}: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      appBar: AppBar(
        title: Text(
          'User Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2d3748),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2d3748)),
        actions: [
          if (_detailedUserData != null && _detailedUserData!['verificationStatus'] == 'pending')
            TextButton(
              onPressed: _isLoading ? null : () => _showVerificationActions(),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Verify',
                      style: TextStyle(
                        color: Color(0xFF667eea),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
            )
          : _detailedUserData == null
              ? const Center(
                  child: Text(
                    'User data not found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      _buildProfileHeader(),
                      const SizedBox(height: 30),
                      
                      // Verification Status
                      _buildVerificationStatus(),
                      const SizedBox(height: 30),
                      
                      // Basic Information
                      _buildBasicInformation(),
                      const SizedBox(height: 30),
                      
                      // Contact Information
                      _buildContactInformation(),
                      const SizedBox(height: 30),
                      
                      // Professional Information (for guides)
                      if (_detailedUserData!['role'] == 'guide') ...[
                        _buildProfessionalInformation(),
                        const SizedBox(height: 30),
                      ],
                      
                      // Identity Documents - Make this more prominent
                      _buildIdentityDocuments(),
                      const SizedBox(height: 30),
                      
                      // Account Information
                      _buildAccountInformation(),
                      const SizedBox(height: 30),
                      
                      // Verification Actions (if pending)
                      if (_detailedUserData!['verificationStatus'] == 'pending')
                        _buildVerificationActions(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    final userData = _detailedUserData!;
    final name = userData['name'] ?? 'Unknown';
    final email = userData['email'] ?? 'No email';
    final role = userData['role'] ?? 'user';
    final profileImageUrl = userData['profileImageUrl'];
    final verificationStatus = userData['verificationStatus'] ?? 'pending';

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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image and Basic Info
          Row(
            children: [
              // Profile Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: roleColor.withOpacity(0.1),
                ),
                child: profileImageUrl != null && profileImageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.network(
                          profileImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              roleIcon,
                              color: roleColor,
                              size: 40,
                            );
                          },
                        ),
                      )
                    : Icon(
                        roleIcon,
                        color: roleColor,
                        size: 40,
                      ),
              ),
              
              const SizedBox(width: 20),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3748),
                          ),
                        ),
                        if (verificationStatus == 'verified') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF48bb78),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                roleIcon,
                                color: roleColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: roleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Verification Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: verificationColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                verificationIcon,
                                color: verificationColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                verificationText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: verificationColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus() {
    final verificationStatus = _detailedUserData!['verificationStatus'] ?? 'pending';
    final verifiedAt = _detailedUserData!['verifiedAt'] as Timestamp?;
    final rejectedAt = _detailedUserData!['rejectedAt'] as Timestamp?;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (verificationStatus) {
      case 'verified':
        statusColor = const Color(0xFF48bb78);
        statusIcon = Icons.verified;
        statusText = 'Verified';
        statusDescription = verifiedAt != null 
            ? 'Verified on ${_formatDate(verifiedAt.toDate())}'
            : 'User has been verified';
        break;
      case 'rejected':
        statusColor = const Color(0xFFe53e3e);
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        statusDescription = rejectedAt != null 
            ? 'Rejected on ${_formatDate(rejectedAt.toDate())}'
            : 'User verification was rejected';
        break;
      default:
        statusColor = const Color(0xFFed8936);
        statusIcon = Icons.pending_actions;
        statusText = 'Pending Verification';
        statusDescription = 'User is waiting for verification';
    }

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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformation() {
    final userData = _detailedUserData!;
    
    return _buildInfoSection(
      title: 'Basic Information',
      icon: Icons.person,
      color: const Color(0xFF667eea),
      children: [
        _buildInfoRow('Full Name', userData['name'] ?? 'Not provided'),
        _buildInfoRow('Email', userData['email'] ?? 'Not provided'),
        _buildInfoRow('Date of Birth', userData['dateOfBirth'] != null 
            ? _formatDate((userData['dateOfBirth'] as Timestamp).toDate())
            : 'Not provided'),
        _buildInfoRow('Nationality', userData['nationality'] ?? 'Not provided'),
        if (userData['role'] == 'tourist')
          _buildInfoRow('Passport Number', userData['passportNumber'] ?? 'Not provided'),
      ],
    );
  }

  Widget _buildContactInformation() {
    final userData = _detailedUserData!;
    
    return _buildInfoSection(
      title: 'Contact Information',
      icon: Icons.contact_phone,
      color: const Color(0xFF48bb78),
      children: [
        _buildInfoRow('Phone Number', userData['phone'] ?? userData['contactNumber'] ?? 'Not provided'),
        _buildInfoRow('Location', userData['location'] ?? 'Not specified'),
        if (userData['role'] == 'tourist') ...[
          _buildInfoRow('Emergency Contact 1', userData['emergencyContact1'] ?? 'Not provided'),
          _buildInfoRow('Emergency Contact 2', userData['emergencyContact2'] ?? 'Not provided'),
          _buildInfoRow('Emergency Relationship', userData['relationship'] ?? 'Not provided'),
        ],
      ],
    );
  }

  Widget _buildProfessionalInformation() {
    final userData = _detailedUserData!;
    
    return _buildInfoSection(
      title: 'Professional Information',
      icon: Icons.work,
      color: const Color(0xFFed8936),
      children: [
        _buildInfoRow('Experience', userData['experience'] ?? 'Not specified'),
        _buildInfoRow('Hourly Rate', userData['hourlyRate'] != null 
            ? '${userData['hourlyRate']} LKR/hour'
            : 'Not set'),
        _buildInfoRow('Daily Rate', userData['dailyRate'] != null 
            ? '${userData['dailyRate']} LKR/day'
            : 'Not set'),
        if (userData['languages'] != null && (userData['languages'] as List).isNotEmpty)
          _buildInfoRow('Languages', (userData['languages'] as List).join(', ')),
        if (userData['specialties'] != null && (userData['specialties'] as List).isNotEmpty)
          _buildInfoRow('Specialties', (userData['specialties'] as List).join(', ')),
        if (userData['bio'] != null && userData['bio'].isNotEmpty)
          _buildInfoRow('Bio', userData['bio']),
      ],
    );
  }



  Widget _buildIdentityDocuments() {
    final userData = _detailedUserData!;
    final role = userData['role'] ?? 'user';
    
    // Debug: Print document URLs for troubleshooting
    print('🔍 [ADMIN] User role: $role');
    print('🔍 [ADMIN] NIC Document URL: ${userData['nicDocumentUrl']}');
    print('🔍 [ADMIN] Driving License URL: ${userData['drivingLicenceDocumentUrl']}');
    print('🔍 [ADMIN] Police Report URL: ${userData['policeReportDocumentUrl']}');
    print('🔍 [ADMIN] Passport URL: ${userData['passportImageUrl']}');
    
    List<Widget> documentWidgets = [];
    
    // Normalize role to lowercase for comparison
    final normalizedRole = role.toLowerCase();
    
    if (normalizedRole == 'guide' || normalizedRole == 'tour guide') {
      // Guide documents - using correct field names from database
      documentWidgets.addAll([
        _buildDocumentCard(
          title: 'NIC Document',
          imageUrl: userData['nicDocumentUrl'],
          icon: Icons.credit_card,
          color: const Color(0xFF667eea),
        ),
        _buildDocumentCard(
          title: 'Driving License',
          imageUrl: userData['drivingLicenceDocumentUrl'],
          icon: Icons.drive_eta,
          color: const Color(0xFF48bb78),
        ),
        _buildDocumentCard(
          title: 'Police Report',
          imageUrl: userData['policeReportDocumentUrl'],
          icon: Icons.security,
          color: const Color(0xFFed8936),
        ),
      ]);
    } else if (normalizedRole == 'tourist') {
      // Tourist documents - using correct field name from database
      documentWidgets.add(
        _buildDocumentCard(
          title: 'Passport',
          imageUrl: userData['passportImageUrl'],
          icon: Icons.card_membership,
          color: const Color(0xFF9f7aea),
        ),
      );
    }
    
    print('🔍 [ADMIN] Normalized role: $normalizedRole');
    print('🔍 [ADMIN] Document widgets count: ${documentWidgets.length}');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with prominent title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFe53e3e).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description,
                  color: Color(0xFFe53e3e),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Identity Documents',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3748),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Document status summary
          _buildDocumentStatusSummary(userData, role),
          const SizedBox(height: 20),
          
          // Document widgets
          if (documentWidgets.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No identity documents uploaded',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ...documentWidgets,
        ],
      ),
    );
  }


  Widget _buildDocumentStatusSummary(Map<String, dynamic> userData, String role) {
    List<Map<String, dynamic>> documents = [];
    
    // Normalize role to lowercase for comparison
    final normalizedRole = role.toLowerCase();
    
    if (normalizedRole == 'guide' || normalizedRole == 'tour guide') {
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
    } else if (normalizedRole == 'tourist') {
      documents = [
        {
          'name': 'Passport',
          'url': userData['passportImageUrl'],
          'icon': Icons.card_membership,
          'color': const Color(0xFF9f7aea),
        },
      ];
    }
    
    int uploadedCount = documents.where((doc) => doc['url'] != null && doc['url'].toString().isNotEmpty).length;
    int totalCount = documents.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: uploadedCount == totalCount ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: uploadedCount == totalCount ? Colors.green[200]! : Colors.orange[200]!,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                uploadedCount == totalCount ? Icons.check_circle : Icons.warning,
                color: uploadedCount == totalCount ? Colors.green[600] : Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Document Status: $uploadedCount of $totalCount documents uploaded',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: uploadedCount == totalCount ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Show individual document status
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: documents.map((doc) {
              final hasUrl = doc['url'] != null && doc['url'].toString().isNotEmpty;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasUrl ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasUrl ? Colors.green[300]! : Colors.red[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      doc['icon'],
                      color: hasUrl ? Colors.green[700] : Colors.red[700],
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      doc['name'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: hasUrl ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      hasUrl ? Icons.check : Icons.close,
                      color: hasUrl ? Colors.green[700] : Colors.red[700],
                      size: 14,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String? imageUrl,
    required IconData icon,
    required Color color,
  }) {
    final hasDocument = imageUrl != null && imageUrl.isNotEmpty;
    
    // Debug: Print document information
    print('🔍 [ADMIN] Document: $title');
    print('🔍 [ADMIN] Has document: $hasDocument');
    print('🔍 [ADMIN] Image URL: $imageUrl');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasDocument ? color.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDocument ? color.withOpacity(0.3) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasDocument ? color.withOpacity(0.1) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: hasDocument ? color : Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: hasDocument ? color : Colors.grey[700],
                  ),
                ),
              ),
              if (hasDocument)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'UPLOADED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'MISSING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          if (hasDocument) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showDocumentImage(title, imageUrl!),
              child: Container(
                width: double.infinity,
                height: 300, // Increased height for better visibility
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      _buildDocumentImage(imageUrl!, title),
                      // Add a click indicator
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentImage(String imageUrl, String title) {
    print('🔍 [ADMIN] Building document image for: $title');
    print('🔍 [ADMIN] Image URL: $imageUrl');
    
    return FutureBuilder<bool>(
      future: _testImageUrl(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ [ADMIN] Testing image URL accessibility for: $title');
          return Container(
            color: Colors.grey[100],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Loading document...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.data!) {
          print('❌ [ADMIN] Image URL test failed for: $title');
          print('❌ [ADMIN] Error: ${snapshot.error}');
          print('❌ [ADMIN] Data: ${snapshot.data}');
          return Container(
            color: Colors.grey[100],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.grey[400],
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load document',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'URL: ${imageUrl.length > 50 ? '${imageUrl.substring(0, 50)}...' : imageUrl}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return FutureBuilder<String>(
          future: _getOptimizedImageUrl(imageUrl),
          builder: (context, urlSnapshot) {
            if (urlSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: Colors.grey[100],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Optimizing URL...'),
                    ],
                  ),
                ),
              );
            }

            final optimizedUrl = urlSnapshot.data ?? imageUrl;
            print('✅ [ADMIN] Image URL test passed for: $title');
            print('✅ [ADMIN] Using optimized URL: $optimizedUrl');
            
            return Image.network(
              optimizedUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  print('✅ [ADMIN] Image loaded successfully for: $title');
                  return child;
                }
                print('⏳ [ADMIN] Loading image for: $title');
                return Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('❌ [ADMIN] Image.network failed for: $title');
                print('❌ [ADMIN] Error: $error');
                print('❌ [ADMIN] StackTrace: $stackTrace');
                return Container(
                  color: Colors.grey[100],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Error: ${error.toString()}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _testImageUrl(String imageUrl) async {
    try {
      print('🔍 [ADMIN] Testing document image URL for user ${widget.userId}: $imageUrl');
      
      // First try to get a fresh signed URL for better access
      final signedUrl = await _firebaseService.getDocumentDownloadUrl(imageUrl);
      final urlToTest = signedUrl ?? imageUrl;
      
      // Test if the URL is accessible
      final response = await _firebaseService.testImageUrl(urlToTest);
      print('${response ? '✅' : '❌'} [ADMIN] Image URL test result for user ${widget.userId}: $response');
      
      return response;
    } catch (e) {
      print('❌ [ADMIN] Error testing image URL for user ${widget.userId}: $e');
      return false;
    }
  }

  Future<String> _getOptimizedImageUrl(String imageUrl) async {
    try {
      print('🔍 [ADMIN] Optimizing image URL for user ${widget.userId}: $imageUrl');
      
      // Get a fresh signed URL for better access
      final signedUrl = await _firebaseService.getDocumentDownloadUrl(imageUrl);
      
      print('✅ [ADMIN] Optimized URL for user ${widget.userId}: $signedUrl');
      return signedUrl ?? imageUrl;
    } catch (e) {
      print('❌ [ADMIN] Error getting optimized image URL for user ${widget.userId}: $e');
      return imageUrl;
    }
  }

  Widget _buildAccountInformation() {
    final userData = _detailedUserData!;
    final createdAt = userData['createdAt'] as Timestamp?;
    final lastLogin = userData['lastLogin'] as Timestamp?;
    
    return _buildInfoSection(
      title: 'Account Information',
      icon: Icons.account_circle,
      color: const Color(0xFF718096),
      children: [
        _buildInfoRow('User ID', widget.userId),
        _buildInfoRow('Account Created', createdAt != null 
            ? _formatDate(createdAt.toDate())
            : 'Unknown'),
        _buildInfoRow('Last Login', lastLogin != null 
            ? _formatDate(lastLogin.toDate())
            : 'Never'),
        _buildInfoRow('Profile Completed', userData['profileCompleted'] == true ? 'Yes' : 'No'),
        _buildInfoRow('Account Status', userData['isActive'] == true ? 'Active' : 'Inactive'),
      ],
    );
  }

  Widget _buildVerificationActions() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Color(0xFF667eea),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Verification Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2d3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _approveUser(widget.userId, _detailedUserData!),
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF48bb78),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _rejectUser(widget.userId, _detailedUserData!),
                  icon: const Icon(Icons.cancel, size: 20),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe53e3e),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
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
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2d3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  void _showDocumentImage(String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: FutureBuilder<bool>(
                    future: _testImageUrl(imageUrl),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Testing document accessibility...'),
                            ],
                          ),
                        );
                      }

                      if (snapshot.hasError || !snapshot.data!) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.grey[400],
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Document not accessible',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'URL: ${imageUrl.length > 80 ? '${imageUrl.substring(0, 80)}...' : imageUrl}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return FutureBuilder<String>(
                        future: _getOptimizedImageUrl(imageUrl),
                        builder: (context, urlSnapshot) {
                          if (urlSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Optimizing document URL...'),
                                ],
                              ),
                            );
                          }

                          final optimizedUrl = urlSnapshot.data ?? imageUrl;
                          
                          return Image.network(
                            optimizedUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Loading document...'),
                                  ],
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.grey[400],
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Error: ${error.toString()}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
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

  void _showVerificationActions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Actions'),
        content: const Text('Choose an action for this user verification:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _approveUser(widget.userId, _detailedUserData!);
            },
            child: const Text(
              'Approve',
              style: TextStyle(color: Colors.green),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectUser(widget.userId, _detailedUserData!);
            },
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
              setState(() {
                _isLoading = true;
              });
              
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
                  
                  // Refresh the data
                  await _loadDetailedUserData();
                  widget.onVerificationChanged();
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
              
              setState(() {
                _isLoading = false;
              });
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
              setState(() {
                _isLoading = true;
              });
              
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
                  
                  // Refresh the data
                  await _loadDetailedUserData();
                  widget.onVerificationChanged();
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
              
              setState(() {
                _isLoading = false;
              });
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
