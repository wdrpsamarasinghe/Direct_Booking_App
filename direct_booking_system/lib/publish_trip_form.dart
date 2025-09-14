import 'package:flutter/material.dart';
import 'services/firebase_service.dart';

class PublishTripForm extends StatefulWidget {
  final VoidCallback? onTripPublished;
  
  const PublishTripForm({Key? key, this.onTripPublished}) : super(key: key);
  
  @override
  _PublishTripFormState createState() => _PublishTripFormState();
}

class _PublishTripFormState extends State<PublishTripForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final _tripTitleController = TextEditingController();
  final _tripDescriptionController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _contactInfoController = TextEditingController();
  
  String _selectedCategory = 'Cultural Tours';
  String _selectedLocation = 'Colombo';
  String _selectedDuration = 'Full Day (8-10 hours)';
  String _selectedGroupType = 'Solo';
  String _selectedBudget = 'LKR 10,000 - 20,000';
  String _selectedExperience = 'Any Experience';
  
  DateTime? _startDate;
  TimeOfDay? _startTime;
  int _adults = 1;
  int _children = 0;
  int _infants = 0;
  
  List<String> _selectedLanguages = ['English'];
  List<String> _selectedSpecialties = ['Historical Tours'];
  List<String> _selectedRequirements = [];
  
  bool _isLoading = false;
  
  final List<String> _categories = [
    'Cultural Tours', 'Adventure Tours', 'Food Tours', 'Nature Tours',
    'Historical Tours', 'Beach Tours', 'Photography Tours', 'Religious Tours'
  ];
  
  final List<String> _locations = [
    'Colombo', 'Kandy', 'Galle', 'Negombo', 'Anuradhapura', 'Polonnaruwa',
    'Sigiriya', 'Nuwara Eliya', 'Ella', 'Mirissa', 'Unawatuna'
  ];
  
  final List<String> _durations = [
    'Half Day (4-6 hours)', 'Full Day (8-10 hours)', '2 Days', '3 Days',
    '4-7 Days', '1 Week+'
  ];
  
  final List<String> _groupTypes = [
    'Solo', 'Couple', 'Family', 'Group'
  ];
  
  final List<String> _budgets = [
    'Under LKR 5,000', 'LKR 5,000 - 10,000', 'LKR 10,000 - 20,000',
    'LKR 20,000 - 50,000', 'Above LKR 50,000', 'Flexible Budget'
  ];
  
  final List<String> _languages = [
    'English', 'Sinhala', 'Tamil', 'French', 'German', 'Spanish', 'Italian'
  ];
  
  final List<String> _experiences = [
    'Any Experience', 'New Guides (0-1 years)', 'Experienced (2-5 years)', 'Expert (5+ years)'
  ];
  
  final List<String> _specialties = [
    'Historical Tours', 'Cultural Tours', 'Nature Tours', 'Adventure Tours',
    'Food Tours', 'Photography Tours', 'Wildlife Tours', 'Religious Tours'
  ];
  
  final List<String> _requirements = [
    'Car/Vehicle Required', 'Public Transport OK', 'Walking Tours Preferred',
    'Air-conditioned Vehicle', 'Wheelchair Accessible', 'Professional Photos',
    'Vegetarian Meals', 'Halal Food', 'No Smoking'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Publish My Trip',
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
            onPressed: _isLoading ? null : _publishTrip,
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
                    'Publish',
                    style: TextStyle(
                      color: Color(0xFF667eea),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Overview Section
              _buildSectionTitle('Trip Overview'),
              const SizedBox(height: 15),
              _buildTripOverviewSection(),
              const SizedBox(height: 30),
              
              // Location & Duration Section
              _buildSectionTitle('Location & Duration'),
              const SizedBox(height: 15),
              _buildLocationDurationSection(),
              const SizedBox(height: 30),
              
              // Group Information Section
              _buildSectionTitle('Group Information'),
              const SizedBox(height: 15),
              _buildGroupInfoSection(),
              const SizedBox(height: 30),
              
              // Budget & Pricing Section
              _buildSectionTitle('Budget & Pricing'),
              const SizedBox(height: 15),
              _buildBudgetSection(),
              const SizedBox(height: 30),
              
              // Languages Section
              _buildSectionTitle('Languages'),
              const SizedBox(height: 15),
              _buildLanguagesSection(),
              const SizedBox(height: 30),
              
              // Special Requirements Section
              _buildSectionTitle('Special Requirements'),
              const SizedBox(height: 15),
              _buildSpecialRequirementsSection(),
              const SizedBox(height: 30),
              
              // Guide Preferences Section
              _buildSectionTitle('Guide Preferences'),
              const SizedBox(height: 15),
              _buildGuidePreferencesSection(),
              const SizedBox(height: 30),
              
              // Additional Information Section
              _buildSectionTitle('Additional Information'),
              const SizedBox(height: 15),
              _buildAdditionalInfoSection(),
              const SizedBox(height: 30),
              
              // Contact & Availability Section
              _buildSectionTitle('Contact & Availability'),
              const SizedBox(height: 15),
              _buildContactSection(),
              const SizedBox(height: 30),
              
              // Publish Button
              _buildPublishButton(),
              const SizedBox(height: 20),
            ],
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

  Widget _buildTripOverviewSection() {
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
          // Trip Title Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _tripTitleController,
                label: 'Trip Title',
                hint: 'Short title (max 14 characters)',
                icon: Icons.title,
                maxLines: 1,
                onChanged: (value) {
                  setState(() {}); // Update character counter
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter trip title';
                  }
                  if (value.length >= 15) {
                    return 'Title should be less than 15 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${_tripTitleController.text.length}/14',
                    style: TextStyle(
                      fontSize: 12,
                      color: _tripTitleController.text.length >= 15 
                          ? Colors.red 
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Trip Description Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _tripDescriptionController,
                label: 'Trip Description',
                hint: 'Brief description (max 19 characters)',
                icon: Icons.description,
                maxLines: 4,
                onChanged: (value) {
                  setState(() {}); // Update character counter
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter trip description';
                  }
                  if (value.length >= 20) {
                    return 'Description should be less than 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${_tripDescriptionController.text.length}/19',
                    style: TextStyle(
                      fontSize: 12,
                      color: _tripDescriptionController.text.length >= 20 
                          ? Colors.red 
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'Trip Category',
            value: _selectedCategory,
            items: _categories,
            onChanged: (value) => setState(() => _selectedCategory = value!),
            icon: Icons.category,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDurationSection() {
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
          _buildDropdownField(
            label: 'Primary Location',
            value: _selectedLocation,
            items: _locations,
            onChanged: (value) => setState(() => _selectedLocation = value!),
            icon: Icons.location_on,
          ),
          const SizedBox(height: 20),
          _buildDatePickerField(),
          const SizedBox(height: 20),
          _buildTimePickerField(),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'Trip Duration',
            value: _selectedDuration,
            items: _durations,
            onChanged: (value) => setState(() => _selectedDuration = value!),
            icon: Icons.schedule,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfoSection() {
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
          _buildDropdownField(
            label: 'Group Type',
            value: _selectedGroupType,
            items: _groupTypes,
            onChanged: (value) => setState(() => _selectedGroupType = value!),
            icon: Icons.group,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: 'Adults',
                  value: _adults,
                  onChanged: (value) => setState(() => _adults = value),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildNumberField(
                  label: 'Children',
                  value: _children,
                  onChanged: (value) => setState(() => _children = value),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildNumberField(
                  label: 'Infants',
                  value: _infants,
                  onChanged: (value) => setState(() => _infants = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection() {
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
          _buildDropdownField(
            label: 'Budget Range',
            value: _selectedBudget,
            items: _budgets,
            onChanged: (value) => setState(() => _selectedBudget = value!),
            icon: Icons.attach_money,
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
            children: _languages.map((language) {
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
      ),
    );
  }

  Widget _buildSpecialRequirementsSection() {
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
            'Special Requirements:',
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
            children: _requirements.map((requirement) {
              final isSelected = _selectedRequirements.contains(requirement);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedRequirements.remove(requirement);
                    } else {
                      _selectedRequirements.add(requirement);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.orange[300]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    requirement,
                    style: TextStyle(
                      color: isSelected ? Colors.orange[700] : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidePreferencesSection() {
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
          _buildDropdownField(
            label: 'Guide Experience Level',
            value: _selectedExperience,
            items: _experiences,
            onChanged: (value) => setState(() => _selectedExperience = value!),
            icon: Icons.work,
          ),
          const SizedBox(height: 20),
          const Text(
            'Preferred Guide Specialties:',
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
            children: _specialties.map((specialty) {
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
                    color: isSelected ? Colors.green[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.green[300]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    specialty,
                    style: TextStyle(
                      color: isSelected ? Colors.green[700] : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
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
            controller: _additionalInfoController,
            label: 'Additional Information (Optional)',
            hint: 'Any other details, interests, or special requests...',
            icon: Icons.info_outline,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
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
            controller: _contactInfoController,
            label: 'Contact Information',
            hint: 'Best way to reach you (WhatsApp, Phone, Email)',
            icon: Icons.contact_phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please provide contact information';
              }
              return null;
            },
          ),
        ],
      ),
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
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    // Safety check for empty items list
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text('No options available for $label'),
      );
    }
    
    // Ensure we have a valid value
    final validValue = items.contains(value) ? value : items.first;
    
    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: InputDecoration(
        labelText: label,
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
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2d3748),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: _selectStartDate,
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
                    'Start Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _startDate != null
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Select start date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _startDate != null ? Colors.black : Colors.grey[500],
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

  Widget _buildTimePickerField() {
    return GestureDetector(
      onTap: _selectStartTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: const Color(0xFF667eea)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferred Start Time',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _startTime != null
                        ? _startTime!.format(context)
                        : 'Select start time',
                    style: TextStyle(
                      fontSize: 16,
                      color: _startTime != null ? Colors.black : Colors.grey[500],
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

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _publishTrip,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667eea),
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
                    'Publishing...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Text(
                'Publish Trip',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _publishTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date'),
          backgroundColor: Colors.red,
        ),
      );
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user info
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to publish a trip'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get tourist profile data
      final touristProfile = await _firebaseService.getUserProfile(currentUser.uid);
      final touristName = touristProfile?['name'] ?? 'Unknown Tourist';

      // Prepare trip data
      final tripData = {
        'title': _tripTitleController.text.trim(),
        'description': _tripDescriptionController.text.trim(),
        'category': _selectedCategory,
        'location': _selectedLocation,
        'startDate': _startDate!,
        'startTime': _startTime?.format(context),
        'duration': _selectedDuration,
        'groupType': _selectedGroupType,
        'adults': _adults,
        'children': _children,
        'infants': _infants,
        'budget': _selectedBudget,
        'languages': _selectedLanguages,
        'requirements': _selectedRequirements,
        'guideExperience': _selectedExperience,
        'guideSpecialties': _selectedSpecialties,
        'additionalInfo': _additionalInfoController.text.trim(),
        'contactInfo': _contactInfoController.text.trim(),
        'touristId': currentUser.uid,
        'touristName': touristName,
        'touristEmail': currentUser.email,
        'status': 'active',
      };

      // Save trip data to Firebase
      await _firebaseService.publishTrip(tripData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip published successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Call the callback to refresh the parent page
        widget.onTripPublished?.call();
        
        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error publishing trip: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing trip: $e'),
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

  @override
  void dispose() {
    _tripTitleController.dispose();
    _tripDescriptionController.dispose();
    _additionalInfoController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }
}
