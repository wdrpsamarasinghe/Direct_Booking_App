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
  
  List<String> _selectedLanguages = [];
  List<String> _selectedSpecialties = [];
  String? _selectedLocation;
  
  DateTime? _dateOfBirth;
  int? _selectedExperience;
  Uint8List? _nicDocument;
  Uint8List? _drivingLicenceDocument;
  Uint8List? _policeReportDocument;
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
          
          // For web platform, download image as base64
          if (kIsWeb && profileImageUrl != null) {
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
          if ((_profileImageUrl != null && _profileImageUrl!.isNotEmpty) || 
              _profileImage != null || 
              _profileImageBase64 != null)
            Column(
              children: [
                TextButton(
                  onPressed: _testProfileImage,
                  child: const Text(
                    'Test Image',
                    style: TextStyle(
                      color: Color(0xFF667eea),
                      fontSize: 12,
                    ),
                  ),
                ),
                if (kIsWeb)
                  Column(
                    children: [
                      TextButton(
                        onPressed: _downloadImageAsBase64,
                        child: Text(
                          _isLoadingImage ? 'Downloading...' : 'Load Image',
                          style: const TextStyle(
                            color: Color(0xFF667eea),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _showImageUrl,
                        child: const Text(
                          'View Image URL',
                          style: TextStyle(
                            color: Color(0xFF667eea),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
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
    required Uint8List? file,
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
        child: Row(
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
                    hasFile ? 'Document uploaded' : subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: hasFile ? const Color(0xFF667eea) : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.check_circle : Icons.upload,
              color: hasFile ? const Color(0xFF667eea) : Colors.grey[400],
            ),
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
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          switch (documentType) {
            case 'nic':
              _nicDocument = bytes;
              break;
            case 'driving':
              _drivingLicenceDocument = bytes;
              break;
            case 'police':
              _policeReportDocument = bytes;
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking document: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      
      final response = await http.get(Uri.parse(_profileImageUrl!));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final base64String = base64Encode(bytes);
        
        setState(() {
          _profileImageBase64 = base64String;
          _isLoadingImage = false;
        });
        
        print('✅ Image downloaded as base64 successfully');
      } else {
        print('❌ Failed to download image: ${response.statusCode}');
        setState(() {
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      print('❌ Error downloading image as base64: $e');
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  Widget _buildProfileImageWidget() {
    final hasImage = (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) || 
                    _profileImage != null || 
                    _profileImageBase64 != null;
    
    print('🖼️ Image display check: hasImage=$hasImage, _profileImageUrl=$_profileImageUrl, _profileImage=$_profileImage, _profileImageBase64=${_profileImageBase64 != null}');
    
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
    
    if (_profileImageBase64 != null) {
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

  Widget _buildMobileProfileImage() {
    // If we have a local file, show it immediately
    if (_profileImage != null) {
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
      return Image.network(
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
          print('❌ Error loading profile image: $error');
          print('❌ Image URL: $_profileImageUrl');
          print('❌ Stack trace: $stackTrace');
          return _buildMobileFallbackImage();
        },
      );
    }
    
    // Fallback if no image is available
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
        // Keep _profileImage for immediate display, it will be cleared on next app restart
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
      }

      // Upload identity documents if new ones were selected (all optional)
      String? nicDocumentUrl = _nicDocumentUrl;
      String? drivingLicenceDocumentUrl = _drivingLicenceDocumentUrl;
      String? policeReportDocumentUrl = _policeReportDocumentUrl;

      if (_nicDocument != null) {
        print('📄 Uploading NIC document');
        nicDocumentUrl = await _firebaseService.uploadProfileImage(
          '${user.uid}_nic_${DateTime.now().millisecondsSinceEpoch}', 
          _nicDocument!
        );
        print('✅ NIC document uploaded successfully');
      }

      if (_drivingLicenceDocument != null) {
        print('🚗 Uploading driving licence document');
        drivingLicenceDocumentUrl = await _firebaseService.uploadProfileImage(
          '${user.uid}_driving_${DateTime.now().millisecondsSinceEpoch}', 
          _drivingLicenceDocument!
        );
        print('✅ Driving licence document uploaded successfully');
      }

      if (_policeReportDocument != null) {
        print('🛡️ Uploading police report document');
        policeReportDocumentUrl = await _firebaseService.uploadProfileImage(
          '${user.uid}_police_${DateTime.now().millisecondsSinceEpoch}', 
          _policeReportDocument!
        );
        print('✅ Police report document uploaded successfully');
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
}

