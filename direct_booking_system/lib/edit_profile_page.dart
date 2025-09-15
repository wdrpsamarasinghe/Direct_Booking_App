import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _dailyRateController = TextEditingController();
  
  File? _profileImage;
  String? _profileImageUrl;
  String? _profileImageBase64;
  final ImagePicker _picker = ImagePicker();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isLoadingImage = false;
  bool _isUploadingNic = false;
  bool _isUploadingDriving = false;
  bool _isUploadingPolice = false;
  
  List<String> _selectedLanguages = [];
  List<String> _selectedSpecialties = [];
  String? _selectedLocation;
  
  DateTime? _dateOfBirth;
  int? _selectedExperience;
  File? _nicDocument;
  File? _drivingLicenceDocument;
  File? _policeReportDocument;
  String? _nicDocumentUrl;
  String? _drivingLicenceDocumentUrl;
  String? _policeReportDocumentUrl;
  
  final List<String> _availableLanguages = [
    'English', 'Sinhala', 'Tamil', 'French', 'German', 'Spanish', 
    'Italian', 'Portuguese', 'Russian', 'Chinese', 'Japanese', 'Korean'
  ];
  
  final List<String> _availableSpecialties = [
    'Historical Tours', 'Cultural Tours', 'Nature Tours', 'Adventure Tours',
    'Food Tours', 'Photography Tours', 'Wildlife Tours', 'Religious Tours',
    'City Tours', 'Beach Tours', 'Mountain Tours', 'Museum Tours'
  ];

  final List<String> _sriLankanDistricts = [
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Matale',
    'Nuwara Eliya',
    'Galle',
    'Matara',
    'Hambantota',
    'Jaffna',
    'Kilinochchi',
    'Mannar',
    'Mullaitivu',
    'Vavuniya',
    'Batticaloa',
    'Ampara',
    'Trincomalee',
    'Kurunegala',
    'Puttalam',
    'Anuradhapura',
    'Polonnaruwa',
    'Badulla',
    'Moneragala',
    'Ratnapura',
    'Kegalle'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }


  Future<void> _loadUserData() async {
    try {
      print('🔍 Loading user data for edit profile');
      
      // Test Firebase Storage connectivity first
      final isStorageConnected = await _firebaseService.testStorageConnectivity();
      print('📡 Storage connectivity: $isStorageConnected');
      
      final user = _firebaseService.currentUser;
      if (user != null) {
        final userData = await _firebaseService.getUserProfile(user.uid);
        if (userData != null && mounted) {
          print('📊 User data loaded successfully');
          print('📊 Full user data: $userData');
          
          // Extract profile image URL and validate it
          String? profileImageUrl = userData['profileImageUrl'];
          print('📸 Profile image URL loaded: $profileImageUrl');
          
          // Validate the URL format and accessibility
          if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
            print('📸 URL validation: ${_isValidUrl(profileImageUrl)}');
            if (_isValidUrl(profileImageUrl)) {
              print('✅ Profile image URL is valid');
              
              // Test the URL accessibility
              final isUrlAccessible = await _firebaseService.testImageUrl(profileImageUrl);
              print('📡 Image URL accessibility: $isUrlAccessible');
              
              if (!isUrlAccessible) {
                print('❌ Image URL is not accessible, clearing it');
                profileImageUrl = null;
              }
            } else {
              print('❌ Profile image URL is invalid, clearing it');
              profileImageUrl = null;
            }
          }
          
          setState(() {
            _nameController.text = userData['name'] ?? '';
            _bioController.text = userData['bio'] ?? '';
            _phoneController.text = userData['phone'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _locationController.text = userData['location'] ?? '';
            _selectedLocation = userData['location'];
            _hourlyRateController.text = userData['hourlyRate']?.toString() ?? '';
            _dailyRateController.text = userData['dailyRate']?.toString() ?? '';
            _profileImageUrl = profileImageUrl;
            
            // Load date of birth
            if (userData['dateOfBirth'] != null) {
              _dateOfBirth = (userData['dateOfBirth'] as Timestamp).toDate();
            }
            
            // Load experience
            if (userData['experience'] != null) {
              _selectedExperience = userData['experience'] is int 
                  ? userData['experience'] 
                  : int.tryParse(userData['experience'].toString());
            }
            
            // Load identity documents
            _nicDocumentUrl = userData['nicDocumentUrl'];
            _drivingLicenceDocumentUrl = userData['drivingLicenceDocumentUrl'];
            _policeReportDocumentUrl = userData['policeReportDocumentUrl'];
            
            // Load languages
            if (userData['languages'] != null) {
              _selectedLanguages = List<String>.from(userData['languages']);
            }
            
            // Load specialties
            if (userData['specialties'] != null) {
              _selectedSpecialties = List<String>.from(userData['specialties']);
            }
            
            _isLoadingData = false;
          });
          
          // For web platform, automatically download image as base64 to bypass CORS
          if (kIsWeb && profileImageUrl != null) {
            print('🌐 Web platform detected - automatically downloading image as base64');
            _downloadImageAsBase64();
          }
        } else {
          print('⚠️ No user data found');
          setState(() {
            _isLoadingData = false;
          });
        }
      } else {
        print('❌ No authenticated user');
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: const Color(0xFFf7fafc),
        appBar: AppBar(
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3748),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF2d3748)),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2d3748),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2d3748)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadUserData,
            tooltip: 'Refresh Profile Data',
          ),
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF667eea),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo Section
                _buildProfilePhotoSection(),
                const SizedBox(height: 30),
                
                // Basic Information Section
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: 15),
                _buildBasicInfoSection(),
                const SizedBox(height: 30),
                
                // Professional Information Section
                _buildSectionTitle('Professional Information'),
                const SizedBox(height: 15),
                _buildProfessionalInfoSection(),
                const SizedBox(height: 30),
                
                // Identity Information Section
                _buildSectionTitle('Identity Information'),
                const SizedBox(height: 15),
                _buildIdentityInfoSection(),
                const SizedBox(height: 30),
                
                // Languages Section
                _buildSectionTitle('Languages'),
                const SizedBox(height: 15),
                _buildLanguagesSection(),
                const SizedBox(height: 30),
                
                // Specialties Section
                _buildSectionTitle('Specialties'),
                const SizedBox(height: 15),
                _buildSpecialtiesSection(),
                const SizedBox(height: 30),
                
                // Contact Information Section
                _buildSectionTitle('Contact Information'),
                const SizedBox(height: 15),
                _buildContactInfoSection(),
                const SizedBox(height: 30),
                
                // Save Button
                _buildSaveButton(),
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

  Widget _buildProfilePhotoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showImagePickerOptions,
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
              child: _buildProfileImageWidget(),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) || 
            _profileImage != null || 
            _profileImageBase64 != null
                ? (kIsWeb ? 'Image Uploaded (Web)' : 'Change Photo')
                : 'Add Photo from Gallery',
            style: const TextStyle(
              color: Color(0xFF667eea),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
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
          _buildDatePickerField(),
          const SizedBox(height: 20),
          _buildLocationDropdown(),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoSection() {
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
          _buildTextField(
            controller: _bioController,
            label: 'Bio (Optional)',
            hint: 'Tell us about yourself and your guiding experience...',
            icon: Icons.description,
            maxLines: 4,
            validator: (value) {
              // Bio is now optional - no validation needed
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildExperienceDropdown(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
            controller: _hourlyRateController,
            label: 'Hourly Rate (LKR)',
            hint: '2500',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                      return 'Please enter hourly rate';
              }
              return null;
            },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildTextField(
                  controller: _dailyRateController,
                  label: 'Daily Rate (LKR)',
                  hint: '15000',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter daily rate';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection() {
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
          const Text(
            'Select languages you speak:',
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
          if (_selectedLanguages.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Please select at least one language',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesSection() {
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
          const Text(
            'Select your specialties:',
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
            children: _availableSpecialties.map((specialty) {
              final isSelected = _selectedSpecialties.contains(specialty);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSpecialties.remove(specialty);
                    } else {
                      _selectedSpecialties.add(specialty);
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
                    specialty,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedSpecialties.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Please select at least one specialty',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
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
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+94 77 123 4567',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityInfoSection() {
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
              const Text(
                'Identity Information (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2d3748),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Optional',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload these documents to verify your identity and increase trust with tourists.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          _buildDocumentUploadField(
            title: 'NIC Document',
            subtitle: 'Upload your National Identity Card',
            icon: Icons.credit_card,
            file: _nicDocument,
            fileUrl: _nicDocumentUrl,
            onTap: () => _pickDocument('nic'),
          ),
          const SizedBox(height: 20),
          _buildDocumentUploadField(
            title: 'Driving Licence',
            subtitle: 'Upload your driving licence',
            icon: Icons.drive_eta,
            file: _drivingLicenceDocument,
            fileUrl: _drivingLicenceDocumentUrl,
            onTap: () => _pickDocument('driving'),
          ),
          const SizedBox(height: 20),
          _buildDocumentUploadField(
            title: 'Police Report',
            subtitle: 'Upload your police clearance report',
            icon: Icons.security,
            file: _policeReportDocument,
            fileUrl: _policeReportDocumentUrl,
            onTap: () => _pickDocument('police'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadField({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? file,
    required String? fileUrl,
    required VoidCallback onTap,
  }) {
    final hasFile = file != null || fileUrl != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFF667eea).withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? const Color(0xFF667eea) : Colors.grey[300]!,
            width: hasFile ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasFile 
                        ? const Color(0xFF667eea) 
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: hasFile ? Colors.white : Colors.grey[600],
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
                          color: hasFile ? const Color(0xFF667eea) : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDocumentStatusText(file, fileUrl),
                        style: TextStyle(
                          fontSize: 14,
                          color: hasFile ? const Color(0xFF667eea) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasFile && fileUrl != null && fileUrl.isNotEmpty) ...[
                      IconButton(
                        onPressed: () => _showDocumentOptions(fileUrl, title),
                        icon: const Icon(Icons.more_vert),
                        color: Colors.grey[600],
                        tooltip: 'Document options',
                      ),
                    ],
                    if (_isDocumentUploading(title)) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                        ),
                      ),
                    ] else ...[
                      Icon(
                        hasFile ? Icons.check_circle : Icons.upload,
                        color: hasFile ? const Color(0xFF667eea) : Colors.grey[400],
                      ),
                    ],
                  ],
                ),
              ],
            ),
            // Show image preview if document is uploaded
            if (hasFile) ...[
              const SizedBox(height: 12),
              _buildDocumentImagePreview(file, fileUrl),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedExperience,
      decoration: InputDecoration(
        labelText: 'Experience (Years)',
        prefixIcon: Icon(Icons.work, color: const Color(0xFF667eea)),
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
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: List.generate(40, (index) {
        final years = index + 1;
        return DropdownMenuItem<int>(
          value: years,
          child: Text('$years ${years == 1 ? 'year' : 'years'}'),
        );
      }),
      onChanged: (value) {
        setState(() {
          _selectedExperience = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select your experience';
        }
        return null;
      },
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

  Widget _buildLocationDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLocation,
      decoration: InputDecoration(
        labelText: 'Location (Optional)',
        hintText: 'Select your district',
        prefixIcon: const Icon(Icons.location_on, color: Color(0xFF667eea)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: _sriLankanDistricts.map((String district) {
        return DropdownMenuItem<String>(
          value: district,
          child: Text(district),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedLocation = newValue;
          _locationController.text = newValue ?? '';
        });
      },
      validator: (value) {
        // Location is optional - no validation needed
        return null;
      },
    );
  }

  Future<void> _pickDocument(String documentType) async {
    try {
      print('📄 Starting document picker for: $documentType');
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (file != null) {
        print('✅ Document selected: ${file.path}');
        
        // For web compatibility, upload immediately like profile picture
        final imageBytes = await file.readAsBytes();
        
        setState(() {
          switch (documentType) {
            case 'nic':
              _nicDocument = File(file.path);
              break;
            case 'driving':
              _drivingLicenceDocument = File(file.path);
              break;
            case 'police':
              _policeReportDocument = File(file.path);
              break;
          }
        });
        
        // Upload the document immediately for better user experience
        await _uploadDocumentDirectly(documentType, imageBytes);
        
        print('📄 Document uploaded successfully');
      } else {
        print('❌ No document selected');
      }
    } catch (e) {
      print('❌ Error picking document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadDocumentDirectly(String documentType, Uint8List imageBytes) async {
    try {
      print('📤 Uploading document directly to Firebase Storage: $documentType');
      final user = _firebaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Set loading state
      setState(() {
        switch (documentType) {
          case 'nic':
            _isUploadingNic = true;
            break;
          case 'driving':
            _isUploadingDriving = true;
            break;
          case 'police':
            _isUploadingPolice = true;
            break;
        }
      });

      String documentUrl;
      switch (documentType) {
        case 'nic':
          documentUrl = await _firebaseService.uploadDocument(user.uid, 'nic', imageBytes);
          setState(() {
            _nicDocumentUrl = documentUrl;
            _nicDocument = null; // Clear local file after successful upload
            _isUploadingNic = false;
          });
          break;
        case 'driving':
          documentUrl = await _firebaseService.uploadDocument(user.uid, 'driving_licence', imageBytes);
          setState(() {
            _drivingLicenceDocumentUrl = documentUrl;
            _drivingLicenceDocument = null; // Clear local file after successful upload
            _isUploadingDriving = false;
          });
          break;
        case 'police':
          documentUrl = await _firebaseService.uploadDocument(user.uid, 'police_report', imageBytes);
          setState(() {
            _policeReportDocumentUrl = documentUrl;
            _policeReportDocument = null; // Clear local file after successful upload
            _isUploadingPolice = false;
          });
          break;
        default:
          throw Exception('Unknown document type: $documentType');
      }
      
      print('✅ Document uploaded successfully, URL: $documentUrl');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getDocumentTypeName(documentType)} updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error uploading document: $e');
      
      // Clear loading state on error
      setState(() {
        switch (documentType) {
          case 'nic':
            _isUploadingNic = false;
            break;
          case 'driving':
            _isUploadingDriving = false;
            break;
          case 'police':
            _isUploadingPolice = false;
            break;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getDocumentTypeName(String documentType) {
    switch (documentType) {
      case 'nic':
        return 'NIC Document';
      case 'driving':
        return 'Driving Licence';
      case 'police':
        return 'Police Report';
      default:
        return 'Document';
    }
  }

  bool _isDocumentUploading(String title) {
    switch (title) {
      case 'NIC Document':
        return _isUploadingNic;
      case 'Driving Licence':
        return _isUploadingDriving;
      case 'Police Report':
        return _isUploadingPolice;
      default:
        return false;
    }
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? Colors.grey[400] : const Color(0xFF667eea),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Updating...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Text(
          'Update Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
    // Directly open gallery without showing modal
    _pickImage(ImageSource.gallery);
  }


  Future<bool> _testImageUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      print('🔍 Image URL test: ${response.statusCode} - $url');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Image URL test failed: $e');
      return false;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      print('📸 Starting image picker with source: $source');
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        print('✅ Image selected: ${image.path}');
        
        // For web compatibility, we'll store the image bytes directly
        // and upload immediately instead of storing as File
        final imageBytes = await image.readAsBytes();
        
        setState(() {
          _profileImage = File(image.path);
          _isLoadingImage = true;
        });
        
        // Upload the image immediately for web compatibility
        await _uploadImageDirectly(imageBytes);
        
        print('📱 Profile image uploaded successfully');
      } else {
        print('❌ No image selected');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      print('❌ URL parsing error: $e');
      return false;
    }
  }

  Future<void> _downloadImageAsBase64() async {
    if (_profileImageUrl == null || !kIsWeb) return;
    
    try {
      setState(() {
        _isLoadingImage = true;
      });
      
      print('📥 Downloading image as base64: $_profileImageUrl');
      
      // Extract the file path from the URL
      final uri = Uri.parse(_profileImageUrl!);
      final pathSegments = uri.pathSegments;
      
      // Find the path after 'o/' in the URL
      int oIndex = pathSegments.indexOf('o');
      if (oIndex != -1 && oIndex + 1 < pathSegments.length) {
        final filePath = pathSegments.sublist(oIndex + 1).join('/');
        print('📁 Extracted file path: $filePath');
        
        // Try to get a fresh download URL that might work better
        final ref = _firebaseService.getStorageRef().child(filePath);
        final freshUrl = await ref.getDownloadURL();
        print('🔄 Got fresh download URL: $freshUrl');
        
        // Try using the fresh URL with proper headers
        final response = await http.get(
          Uri.parse(freshUrl),
          headers: {
            'Accept': 'image/*',
            'User-Agent': 'Flutter Web App',
            'Origin': 'http://localhost:${Uri.parse(freshUrl).port}',
          },
        ).timeout(const Duration(seconds: 15));
        
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final base64String = base64Encode(bytes);
          
          setState(() {
            _profileImageBase64 = base64String;
            _isLoadingImage = false;
          });
          
          print('✅ Image downloaded as base64 successfully');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image loaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          print('❌ Failed to download image: ${response.statusCode}');
          setState(() {
            _isLoadingImage = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load image: ${response.statusCode}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('❌ Could not extract file path from URL');
        setState(() {
          _isLoadingImage = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not extract file path from URL'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error downloading image as base64: $e');
      setState(() {
        _isLoadingImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileImageWidget() {
    final hasImage = (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) || 
                    _profileImage != null || 
                    _profileImageBase64 != null;
    
    print('🖼️ Image display check: hasImage=$hasImage, _profileImageUrl=$_profileImageUrl, _profileImage=$_profileImage, _profileImageBase64=${_profileImageBase64 != null}');
    
    // Debug: Check if URL contains profile_images path
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      print('🔍 Profile image URL contains profile_images: ${_profileImageUrl!.contains('profile_images')}');
      print('🔍 Full URL: $_profileImageUrl');
    }
    
    return hasImage
        ? ClipOval(
            child: _buildProfileImage(),
          )
        : Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
            child: const Icon(
              Icons.photo_library,
              color: Colors.white,
              size: 40,
            ),
          );
  }

  Widget _buildProfileImage() {
    // For web platforms, use a different approach to handle CORS issues
    if (kIsWeb) {
      return _buildWebProfileImage();
    } else {
      return _buildMobileProfileImage();
    }
  }

  Widget _buildWebProfileImage() {
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
    if (_profileImageBase64 != null && (_profileImageUrl == null || _profileImageUrl!.isEmpty)) {
      return ClipOval(
        child: Image.memory(
          base64Decode(_profileImageBase64!),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error displaying base64 image: $error');
            return _buildWebFallbackImage();
          },
        ),
      );
    }
    
    // For web, try to load the network image first
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _profileImageUrl!,
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
            print('❌ Error loading web image: $error');
            // Show CORS fallback only if there's actually a CORS error
            if (error.toString().contains('CORS') || 
                error.toString().contains('XMLHttpRequest') ||
                error.toString().contains('blocked')) {
              return _buildWebCorsFallbackImage();
            }
            return _buildWebFallbackImage();
          },
        ),
      );
    }
    
    return _buildWebFallbackImage();
  }

  Widget _buildWebFallbackImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 4),
          const Text(
            'Image Uploaded',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Web Platform',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebCorsFallbackImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFED8936), Color(0xFFDD6B20)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 4),
          const Text(
            'CORS Issue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Try Mobile',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileProfileImage() {
    // If we have a local file AND no network URL, show it immediately
    // This prevents showing old local image when new network image is available
    if (_profileImage != null && (_profileImageUrl == null || _profileImageUrl!.isEmpty)) {
      print('📱 Displaying local profile image: ${_profileImage!.path}');
      return Image.file(
        _profileImage!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading local image: $error');
          return _buildMobileFallbackImage();
        },
      );
    }

    // If we have a network URL, load it
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      print('📱 Attempting to load network image: $_profileImageUrl');
      print('📱 URL contains profile_images: ${_profileImageUrl!.contains('profile_images')}');
      
      return Image.network(
        _profileImageUrl!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('✅ Network image loaded successfully');
            return child;
          }
          print('⏳ Loading network image: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
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
          print('❌ Error loading profile image: $error');
          print('❌ Image URL: $_profileImageUrl');
          print('❌ Stack trace: $stackTrace');
          print('❌ URL contains profile_images: ${_profileImageUrl!.contains('profile_images')}');
          
          // Check if it's a ClientException (network issue)
          if (error.toString().contains('ClientException')) {
            print('🌐 ClientException detected - trying alternative approach');
            return _buildNetworkErrorImage();
          }
          
          return _buildMobileFallbackImage();
        },
      );
    }

    // Fallback if no image is available
    print('📱 No image available, showing fallback');
    return _buildMobileFallbackImage();
  }

  Widget _buildMobileFallbackImage() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: const Icon(
        Icons.photo_library,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildNetworkErrorImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFE53E3E), Color(0xFFC53030)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 4),
          Text(
            'Network Error',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testProfileImage() async {
    if (_profileImageUrl == null) return;
    
    try {
      print('🔍 Testing profile image URL: $_profileImageUrl');
      final isAccessible = await _firebaseService.testImageUrl(_profileImageUrl!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAccessible 
                ? '✅ Image URL is accessible' 
                : '❌ Image URL is not accessible'),
            backgroundColor: isAccessible ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error testing profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _forceRefreshImage() async {
    if (_profileImageUrl == null) return;
    
    try {
      print('🔄 Force refreshing profile image');
      setState(() {
        // Force a rebuild by temporarily clearing and restoring the URL
        final tempUrl = _profileImageUrl;
        _profileImageUrl = null;
        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() {
            _profileImageUrl = tempUrl;
          });
        });
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image refreshed'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('❌ Error refreshing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _tryAlternativeImageLoad() async {
    if (_profileImageUrl == null) return;
    
    try {
      print('🔄 Trying alternative image loading method');
      
      // Try to extract the file path from the URL and load it directly from Firebase Storage
      final uri = Uri.parse(_profileImageUrl!);
      final pathSegments = uri.pathSegments;
      
      // Find the path after 'o/' in the URL
      int oIndex = pathSegments.indexOf('o');
      if (oIndex != -1 && oIndex + 1 < pathSegments.length) {
        final filePath = pathSegments.sublist(oIndex + 1).join('/');
        print('📁 Extracted file path: $filePath');
        
        // Try to get the download URL directly from Firebase Storage
        final newUrl = await _firebaseService.getDirectDownloadUrl(filePath);
        if (newUrl != null) {
          print('✅ Got new download URL: $newUrl');
          setState(() {
            _profileImageUrl = newUrl;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image loaded with alternative method'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error with alternative image loading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alternative loading failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageUrl() {
    if (_profileImageUrl == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Image URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your profile image has been uploaded successfully!'),
            const SizedBox(height: 16),
            const Text(
              'Image URL:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              _profileImageUrl!,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Due to web platform limitations, the image may not display directly in the app, but it is successfully stored in Firebase Storage.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
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

  void _showCorsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CORS Issue Explanation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why can\'t I see my profile image?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This is a CORS (Cross-Origin Resource Sharing) issue that occurs when running Flutter web apps locally.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Solutions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Use the mobile app version'),
            const Text('2. Deploy to a web server'),
            const Text('3. Use Chrome with disabled security'),
            const SizedBox(height: 12),
            const Text(
              'The image is uploaded successfully - this is just a display issue in the web browser.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadImageDirectly(Uint8List imageBytes) async {
    try {
      print('📸 Uploading image directly to Firebase Storage');
      final user = _firebaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final imageUrl = await _firebaseService.uploadProfileImage(user.uid, imageBytes);
      
      setState(() {
        _profileImageUrl = imageUrl;
        _isLoadingImage = false;
        // Clear local image so the new network image can be displayed
        _profileImage = null;
        _profileImageBase64 = null;
      });
      
      print('✅ Image uploaded successfully, URL: $imageUrl');
      print('📸 Updated _profileImageUrl in state: $_profileImageUrl');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one language'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one specialty'),
          backgroundColor: Colors.red,
        ),
      );
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
    
    if (_selectedExperience == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your experience'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Starting profile update process');
      final user = _firebaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String? imageUrl = _profileImageUrl;

      // Upload new image if one was selected (optional)
      // Note: For web compatibility, images are uploaded immediately when selected
      // So we only need to upload if _profileImage exists but _profileImageUrl is null
      if (_profileImage != null && _profileImageUrl == null) {
        print('📸 Uploading new profile image');
        final imageBytes = await _profileImage!.readAsBytes();
        imageUrl = await _firebaseService.uploadProfileImage(user.uid, imageBytes);
        print('✅ Profile image uploaded successfully');
        
        // Clear local image after successful upload
        setState(() {
          _profileImage = null;
          _profileImageBase64 = null;
        });
      }

      // Upload identity documents if new ones were selected (all optional)
      String? nicDocumentUrl = _nicDocumentUrl;
      String? drivingLicenceDocumentUrl = _drivingLicenceDocumentUrl;
      String? policeReportDocumentUrl = _policeReportDocumentUrl;

      if (_nicDocument != null) {
        try {
          print('📄 Uploading/updating NIC document');
          final nicBytes = await _nicDocument!.readAsBytes();
          nicDocumentUrl = await _firebaseService.uploadDocument(user.uid, 'nic', nicBytes);
          print('✅ NIC document uploaded/updated successfully');
          
          // Update state with uploaded URL and clear local document
          setState(() {
            _nicDocumentUrl = nicDocumentUrl;
            _nicDocument = null;
          });
        } catch (e) {
          print('❌ Error uploading NIC document: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: Could not upload NIC document: ${e.toString()}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (_drivingLicenceDocument != null) {
        try {
          print('🚗 Uploading/updating driving licence document');
          final drivingBytes = await _drivingLicenceDocument!.readAsBytes();
          drivingLicenceDocumentUrl = await _firebaseService.uploadDocument(user.uid, 'driving_licence', drivingBytes);
          print('✅ Driving licence document uploaded/updated successfully');
          
          // Update state with uploaded URL and clear local document
          setState(() {
            _drivingLicenceDocumentUrl = drivingLicenceDocumentUrl;
            _drivingLicenceDocument = null;
          });
        } catch (e) {
          print('❌ Error uploading driving licence document: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: Could not upload driving licence document: ${e.toString()}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (_policeReportDocument != null) {
        try {
          print('🛡️ Uploading/updating police report document');
          final policeBytes = await _policeReportDocument!.readAsBytes();
          policeReportDocumentUrl = await _firebaseService.uploadDocument(user.uid, 'police_report', policeBytes);
          print('✅ Police report document uploaded/updated successfully');
          
          // Update state with uploaded URL and clear local document
          setState(() {
            _policeReportDocumentUrl = policeReportDocumentUrl;
            _policeReportDocument = null;
          });
        } catch (e) {
          print('❌ Error uploading police report document: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: Could not upload police report document: ${e.toString()}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
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
        'dateOfBirth': Timestamp.fromDate(_dateOfBirth!),
        'age': finalAge,
        'experience': _selectedExperience!,
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'location': _selectedLocation,
        'hourlyRate': int.tryParse(_hourlyRateController.text.trim()) ?? 0,
        'dailyRate': int.tryParse(_dailyRateController.text.trim()) ?? 0,
        'languages': _selectedLanguages,
        'specialties': _selectedSpecialties,
        'profileImageUrl': imageUrl,
        'nicDocumentUrl': nicDocumentUrl,
        'drivingLicenceDocumentUrl': drivingLicenceDocumentUrl,
        'policeReportDocumentUrl': policeReportDocumentUrl,
        'updatedAt': Timestamp.now(),
      };

      print('💾 Updating user profile in Firestore');
      // Update user profile in Firestore
      await _firebaseService.updateUserProfile(user.uid, profileData);
      print('✅ Profile updated successfully in Firestore');

      if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate back to settings page
    Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
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

  Widget _buildDocumentImagePreview(File? file, String? fileUrl) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildDocumentImageWidget(file, fileUrl),
      ),
    );
  }

  Widget _buildDocumentImageWidget(File? file, String? fileUrl) {
    print('🖼️ Building document image widget: file=${file?.path}, fileUrl=$fileUrl');
    
    // If we have a local file AND no network URL, show it immediately
    // Note: Image.file is not supported on web, so we skip local file display on web
    if (file != null && (fileUrl == null || fileUrl.isEmpty) && !kIsWeb) {
      print('📱 Displaying local document image: ${file.path}');
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading local document image: $error');
          return _buildDocumentFallbackImage();
        },
      );
    }

    // If we have a network URL, load it
    if (fileUrl != null && fileUrl.isNotEmpty) {
      print('🌐 Loading network document image: $fileUrl');
      return Image.network(
        fileUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('✅ Network document image loaded successfully');
            return child;
          }
          print('⏳ Loading network document image: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
          return Container(
            color: Colors.grey[100],
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading network document image: $error');
          return _buildDocumentFallbackImage();
        },
      );
    }

    print('📄 No document image available, showing fallback');
    return _buildDocumentFallbackImage();
  }

  Widget _buildDocumentFallbackImage() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Icon(
          Icons.image,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }

  String _getDocumentStatusText(File? file, String? fileUrl) {
    if (file != null) {
      return 'Uploading document...';
    } else if (fileUrl != null && fileUrl.isNotEmpty) {
      return 'Document uploaded successfully - tap to update';
    } else {
      return 'Tap to upload document';
    }
  }

  void _showDocumentOptions(String fileUrl, String documentTitle) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$documentTitle Options',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3748),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.refresh, color: Color(0xFF667eea)),
              title: const Text('Update Document'),
              subtitle: const Text('Replace with a new image'),
              onTap: () {
                Navigator.pop(context);
                _updateDocument(fileUrl, documentTitle);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility, color: Color(0xFF48bb78)),
              title: const Text('View Document'),
              subtitle: const Text('Open in browser'),
              onTap: () {
                Navigator.pop(context);
                _viewDocument(fileUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove Document'),
              subtitle: const Text('Delete this document'),
              onTap: () {
                Navigator.pop(context);
                _confirmRemoveDocument(fileUrl, documentTitle);
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDocument(String fileUrl, String documentTitle) {
    // Determine document type based on URL
    String documentType = 'nic';
    if (fileUrl == _drivingLicenceDocumentUrl) {
      documentType = 'driving';
    } else if (fileUrl == _policeReportDocumentUrl) {
      documentType = 'police';
    }
    
    _pickDocument(documentType);
  }

  void _viewDocument(String fileUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  fileUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Document URL:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              fileUrl,
              style: const TextStyle(fontSize: 12),
            ),
          ],
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

  void _confirmRemoveDocument(String fileUrl, String documentTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Document'),
        content: Text('Are you sure you want to remove your $documentTitle? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearDocument(fileUrl);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _clearDocument(String? fileUrl) {
    if (fileUrl == null) return;
    
    // Determine which document to clear based on the URL
    if (fileUrl == _nicDocumentUrl) {
      setState(() {
        _nicDocumentUrl = null;
        _nicDocument = null;
      });
    } else if (fileUrl == _drivingLicenceDocumentUrl) {
      setState(() {
        _drivingLicenceDocumentUrl = null;
        _drivingLicenceDocument = null;
      });
    } else if (fileUrl == _policeReportDocumentUrl) {
      setState(() {
        _policeReportDocumentUrl = null;
        _policeReportDocument = null;
      });
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document removed. Save profile to apply changes.'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

