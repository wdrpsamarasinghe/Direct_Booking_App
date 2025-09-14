import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';

class TripApplicationForm extends StatefulWidget {
  final Map<String, dynamic> trip;
  final VoidCallback? onApplicationSubmitted;

  const TripApplicationForm({
    Key? key,
    required this.trip,
    this.onApplicationSubmitted,
  }) : super(key: key);

  @override
  State<TripApplicationForm> createState() => _TripApplicationFormState();
}

class _TripApplicationFormState extends State<TripApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  
  // Controllers
  final _requestMessageController = TextEditingController();

  // Form fields
  double _dailyRate = 0.0;
  double _hourlyRate = 0.0;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _calculateTotalCost();
  }

  @override
  void dispose() {
    _requestMessageController.dispose();
    super.dispose();
  }

  void _calculateTotalCost() {
    // Simple calculation - just use daily rate
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      appBar: AppBar(
        title: const Text(
          'Apply for Trip',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTripSummary(),
                    const SizedBox(height: 24),
                    _buildPricingSection(),
                    const SizedBox(height: 24),
                    _buildRequestMessageSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTripSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Summary',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.trip['description']?.toString() ?? 'Trip Description',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'by ${widget.trip['touristName']?.toString() ?? 'Unknown Tourist'}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                widget.trip['location']?.toString() ?? 'Not specified',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                widget.trip['startDate'] != null 
                    ? _formatDate(widget.trip['startDate'])
                    : 'Not specified',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Name',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                'Pre-filled from profile',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2d3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contact',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                'Pre-filled from profile',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2d3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Photo',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                'Pre-filled from profile',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2d3748),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildPricingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: Color(0xFF667eea)),
              const SizedBox(width: 8),
              Text(
                'Pricing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            'Daily Rate (LKR)',
            _dailyRate,
            (value) {
              setState(() => _dailyRate = value);
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a daily rate';
              }
              final parsed = double.tryParse(value);
              if (parsed == null || parsed <= 0) {
                return 'Please enter a valid daily rate';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            'Hourly Rate (LKR)',
            _hourlyRate,
            (value) {
              setState(() => _hourlyRate = value);
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an hourly rate';
              }
              final parsed = double.tryParse(value);
              if (parsed == null || parsed <= 0) {
                return 'Please enter a valid hourly rate';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequestMessageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.message, color: Color(0xFF667eea)),
              const SizedBox(width: 8),
              Text(
                'Request Message',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _requestMessageController,
            decoration: InputDecoration(
              hintText: 'Write your application message here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF667eea)),
              ),
              contentPadding: EdgeInsets.all(16),
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a request message';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }





  Widget _buildNumberField(
    String label,
    double value,
    Function(double) onChanged, {
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value.toString(),
        enabled: enabled,
        keyboardType: TextInputType.number,
        validator: validator,
        onChanged: (value) {
          final parsed = double.tryParse(value);
          if (parsed != null) {
            onChanged(parsed);
          }
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF667eea)),
          ),
        ),
      ),
    );
  }



  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitApplication,
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
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Submit Application',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user data
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userData = await _firebaseService.getUserData(currentUser.uid);
      final userProfile = userData.data() as Map<String, dynamic>?;

      // Prepare application data
      final applicationData = {
        'tripId': widget.trip['id'],
        'guideId': currentUser.uid,
        'guideName': userProfile?['name'] ?? 'Unknown Guide',
        'guideEmail': userProfile?['email'] ?? currentUser.email,
        'guidePhone': userProfile?['phone'] ?? '',
        'guideImage': userProfile?['profileImage'] ?? '',
        
        // Essential Information
        'dailyRate': _dailyRate,
        'hourlyRate': _hourlyRate,
        'requestMessage': _requestMessageController.text.trim(),
        
        // Application Status
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        
        // Trip Information (for reference)
        'tripDescription': widget.trip['description'],
        'tripLocation': widget.trip['location'],
        'tripStartDate': widget.trip['startDate'],
        'touristName': widget.trip['touristName'],
        'touristEmail': widget.trip['touristEmail'],
      };

      // Store application in Firebase
      await _firebaseService.submitTripApplication(applicationData);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Call callback if provided
        widget.onApplicationSubmitted?.call();
        
        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting application: $e'),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
