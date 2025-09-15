import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'publish_trip_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'components/verification_badge.dart';

class TouristTrips extends StatefulWidget {
  const TouristTrips({Key? key}) : super(key: key);

  @override
  State<TouristTrips> createState() => _TouristTripsState();
}

class _TouristTripsState extends State<TouristTrips> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _publishedTrips = [];
  bool _isLoading = true;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    print('🔄 [TOURIST_TRIPS] Starting to load published trips data...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📡 [TOURIST_TRIPS] Calling Firebase service to get published trips...');
      // Fetch only published trips from Firebase
      List<Map<String, dynamic>> trips = await _firebaseService.getPublishedTrips();
      print('✅ [TOURIST_TRIPS] Successfully fetched ${trips.length} published trips from Firebase');
      
      // Log each trip for debugging
      for (int i = 0; i < trips.length; i++) {
        final trip = trips[i];
        print('📋 [TOURIST_TRIPS] Trip ${i + 1}: ID=${trip['id']}, Title=${trip['title']}, Status=${trip['status']}, TouristId=${trip['touristId']}');
      }
    
      setState(() {
        _publishedTrips = trips;
        _isLoading = false;
      });
      print('🎯 [TOURIST_TRIPS] Data loading completed successfully. UI updated with ${_publishedTrips.length} trips.');
    } catch (e) {
      print('❌ [TOURIST_TRIPS] Error loading trips: $e');
      print('📊 [TOURIST_TRIPS] Stack trace: ${StackTrace.current}');
      setState(() {
        _errorMessage = 'Failed to load trips: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Refresh data when returning to the page
  Future<void> _refreshData() async {
    print('🔄 [TOURIST_TRIPS] Manual refresh triggered by user...');
    await _loadData();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      body: SafeArea(
        child: Column(
          children: [
            // Publish My Trip Section
            _buildPublishTripSection(),
            
            // My Published Trips Section
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorState()
                      : RefreshIndicator(
                          onRefresh: _refreshData,
                          child: _buildPublishedTripsList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishTripSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_location_alt,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Publish My Trip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share your travel plans and let tour guides bid for your trip',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPublishTripDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF667eea),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Publish Trip',
                style: TextStyle(
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

  Widget _buildPublishedTripsList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF667eea),
      child: _publishedTrips.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _publishedTrips.length,
              itemBuilder: (context, index) {
                final trip = _publishedTrips[index];
                return _buildPublishedTripCard(trip);
              },
            ),
    );
  }

  Widget _buildPublishedTripCard(Map<String, dynamic> trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trip_origin,
                  color: Color(0xFF667eea),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip['title']?.toString() ?? trip['description']?.toString() ?? 'Untitled Trip',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d3748),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip['category']?.toString() ?? 'No category',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(trip['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trip['status']?.toString() ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(trip['status']),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Trip Details Row
          Row(
            children: [
              Expanded(
                child: _buildTripDetail(
                  Icons.location_on,
                  'Location',
                  trip['location']?.toString() ?? 'Unknown Location',
                ),
              ),
              Expanded(
                child: _buildTripDetail(
                  Icons.calendar_today,
                  'Date',
                  _formatDate(trip['startDate']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildTripDetail(
                  Icons.access_time,
                  'Duration',
                  trip['duration']?.toString() ?? 'Not specified',
                ),
              ),
              Expanded(
                child: _buildTripDetail(
                  Icons.attach_money,
                  'Budget',
                  trip['budget']?.toString() ?? 'No budget set',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Languages
          if (trip['languages'] != null && (trip['languages'] as List).isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Languages:',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (trip['languages'] as List<dynamic>)
                      .map<Widget>((language) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        language.toString(),
                        style: const TextStyle(
                          color: Color(0xFF667eea),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewApplicants(trip),
                  icon: const Icon(Icons.people, size: 16),
                  label: const Text('View Applicants'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF667eea)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _cancelTrip(trip),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Cancel Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No date set';
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Invalid date';
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trip_origin_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No trips published yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Publish your first trip to get started',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red[200]!, width: 2),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 60,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Issue',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We\'re having trouble loading your trips. This might be a temporary network issue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            
            // Action buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Show troubleshooting tips
                      _showTroubleshootingTips();
                    },
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Troubleshooting Tips'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF667eea)),
                      foregroundColor: const Color(0xFF667eea),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Technical details (collapsible)
            ExpansionTile(
              title: Text(
                'Technical Details',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    _errorMessage ?? 'No error details available',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTroubleshootingTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: const Color(0xFF667eea)),
            const SizedBox(width: 8),
            const Text('Troubleshooting Tips'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTipItem(
                Icons.wifi,
                'Check Internet Connection',
                'Make sure you have a stable internet connection. Try switching between WiFi and mobile data.',
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                Icons.refresh,
                'Restart the App',
                'Close the app completely and reopen it. This can resolve temporary connection issues.',
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                Icons.update,
                'Update the App',
                'Make sure you\'re using the latest version of the app. Updates often include bug fixes.',
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                Icons.support_agent,
                'Contact Support',
                'If the problem persists, contact our support team for assistance.',
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                Icons.bug_report,
                'Run Connection Test',
                'Test your connection to our servers to identify specific issues.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _runConnectionTest();
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF667eea)),
              foregroundColor: const Color(0xFF667eea),
            ),
            child: const Text('Test Connection'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF667eea),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3748),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _runConnectionTest() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
            SizedBox(height: 16),
            Text(
              'Testing connection...',
              style: TextStyle(
                color: Color(0xFF667eea),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      print('🔍 [TOURIST_TRIPS] Running connection test...');
      final testResults = await _firebaseService.testFirebaseConnection();
      print('✅ [TOURIST_TRIPS] Connection test completed');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show results
      if (mounted) {
        _showConnectionTestResults(testResults);
      }
    } catch (e) {
      print('❌ [TOURIST_TRIPS] Connection test failed: $e');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConnectionTestResults(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              results['errors'].isEmpty ? Icons.check_circle : Icons.warning,
              color: results['errors'].isEmpty ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Connection Test Results'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTestResultItem(
                'Authentication',
                results['auth'] ?? false,
                'User login status',
              ),
              const SizedBox(height: 12),
              _buildTestResultItem(
                'Firestore Database',
                results['firestore'] ?? false,
                'Database connection',
              ),
              const SizedBox(height: 12),
              _buildTestResultItem(
                'File Storage',
                results['storage'] ?? false,
                'File upload/download',
              ),
              const SizedBox(height: 12),
              _buildTestResultItem(
                'Trips Collection',
                results['trips_collection'] ?? false,
                'Trips data access',
              ),
              
              if (results['errors'].isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Issues Found:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                ...results['errors'].map<Widget>((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $error',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 12,
                    ),
                  ),
                )).toList(),
              ],
            ],
          ),
        ),
        actions: [
          if (results['errors'].isNotEmpty)
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _resetConnection();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                foregroundColor: Colors.orange,
              ),
              child: const Text('Reset Connection'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Loading Trips'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultItem(String title, bool passed, String description) {
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.error,
          color: passed ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _resetConnection() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
            SizedBox(height: 16),
            Text(
              'Resetting connection...',
              style: TextStyle(
                color: Color(0xFF667eea),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      print('🔄 [TOURIST_TRIPS] Resetting Firebase connection...');
      await _firebaseService.resetFirebaseConnection();
      print('✅ [TOURIST_TRIPS] Connection reset completed');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection reset successfully. Try loading trips again.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [TOURIST_TRIPS] Connection reset failed: $e');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection reset failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPublishTripDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: PublishTripForm(
          onTripPublished: () {
            // Refresh data when trip is published
            _loadData();
          },
        ),
      ),
    );
  }

  void _viewApplicants(Map<String, dynamic> trip) async {
    print('👥 [TOURIST_TRIPS] Starting to view applicants for trip: ${trip['id']}');
    print('📋 [TOURIST_TRIPS] Trip details: Title=${trip['title']}, Status=${trip['status']}');
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
        ),
      );

      print('📡 [TOURIST_TRIPS] Calling Firebase service to get applicants for trip ${trip['id']}...');
      // Fetch applicants for this trip
      List<Map<String, dynamic>> applicants = await _firebaseService.getTripApplicationsByTrip(trip['id']);
      print('✅ [TOURIST_TRIPS] Successfully fetched ${applicants.length} applicants from Firebase');
      
      // Log each applicant for debugging
      for (int i = 0; i < applicants.length; i++) {
        final applicant = applicants[i];
        print('👤 [TOURIST_TRIPS] Applicant ${i + 1}: ID=${applicant['id']}, GuideId=${applicant['guideId']}, Status=${applicant['status']}, DailyRate=${applicant['dailyRate']}');
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show applicants modal
      if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.people,
                        color: Color(0xFF667eea),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tour Guide Applicants',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d3748),
                            ),
                          ),
                          Text(
                            '${trip['title']?.toString() ?? trip['description']?.toString() ?? 'Trip'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Applicants List
              Expanded(
                child: applicants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No applicants yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tour guides will appear here when they apply',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: applicants.length,
                        itemBuilder: (context, index) {
                          final applicant = applicants[index];
                          return _buildApplicantCard(applicant);
                        },
                      ),
              ),
            ],
          ),
        ),
      );
      }
    } catch (e) {
      print('❌ [TOURIST_TRIPS] Error loading applicants for trip ${trip['id']}: $e');
      print('📊 [TOURIST_TRIPS] Stack trace: ${StackTrace.current}');
      
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading applicants: $e'),
          backgroundColor: Colors.red,
        ),
      );
      }
    }
  }

  Widget _buildApplicantCard(Map<String, dynamic> applicant) {
    return GestureDetector(
      onTap: () => _viewApplicantProfile(applicant),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
                child: applicant['guideProfileImage'] != null
                    ? ClipOval(
                        child: Image.network(
                          applicant['guideProfileImage'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 25,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserNameWithVerification(
                      name: applicant['guideName']?.toString() ?? 'Unknown Guide',
                      verificationStatus: applicant['guideVerificationStatus']?.toString() ?? 'pending',
                      nameStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d3748),
                      ),
                      badgeSize: 14,
                      showBadgeText: true,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      applicant['guideLocation']?.toString() ?? 'Unknown Location',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(applicant['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  applicant['status']?.toString() ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(applicant['status']),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Pricing
          Row(
            children: [
              Expanded(
                child: _buildApplicantDetail(
                  Icons.attach_money,
                  'Daily Rate',
                  'LKR ${applicant['dailyRate']?.toString() ?? '0'}',
                ),
              ),
              Expanded(
                child: _buildApplicantDetail(
                  Icons.access_time,
                  'Hourly Rate',
                  'LKR ${applicant['hourlyRate']?.toString() ?? '0'}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Request Message
          if (applicant['requestMessage'] != null && applicant['requestMessage'].toString().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request Message:',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  applicant['requestMessage'].toString(),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 12),
          
          // Action Buttons based on status
          _buildApplicantActions(applicant),
        ],
      ),
      ),
    );
  }

  Widget _buildApplicantActions(Map<String, dynamic> applicant) {
    String status = applicant['status']?.toString().toLowerCase() ?? 'pending';
    
    if (status == 'accepted') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Guide accepted! Trip is ready to start.',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _viewApplicantProfile(applicant),
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('View Guide Profile'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF667eea)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      );
    } else if (status == 'rejected') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Application rejected',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _viewApplicantProfile(applicant),
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('View Profile'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      );
    } else {
      // Pending status - show accept/reject buttons
      return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectApplicant(applicant),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptApplicant(applicant),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
      );
    }
  }

  Widget _buildDetailedApplicantActions(Map<String, dynamic> applicant) {
    String status = applicant['status']?.toString().toLowerCase() ?? 'pending';
    
    if (status == 'accepted') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guide Accepted!',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This guide has been accepted for your trip. You can now start the trip when ready.',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 14,
                        ),
          ),
        ],
      ),
      ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF667eea)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    } else if (status == 'rejected') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application Rejected',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This application has been rejected.',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    } else {
      // Pending status - show accept/reject buttons
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _rejectApplicant(applicant);
              },
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _acceptApplicant(applicant);
              },
              icon: const Icon(Icons.check),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildApplicantDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _viewApplicantProfile(Map<String, dynamic> applicant) async {
    print('👤 [TOURIST_TRIPS] Starting to view applicant profile...');
    print('📋 [TOURIST_TRIPS] Applicant ID: ${applicant['id']}, Guide ID: ${applicant['guideId']}');
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
        ),
      ),
    );

    try {
      // Debug: Print applicant data to see what's being passed
      print('🔍 [TOURIST_TRIPS] Applicant data received:');
      print('  Guide ID: ${applicant['guideId']}');
      print('  Guide Name: ${applicant['guideName']}');
      print('  Message (old field): ${applicant['message']}');
      print('  RequestMessage (correct field): ${applicant['requestMessage']}');
      print('  Status: ${applicant['status']}');
      print('  Daily Rate: ${applicant['dailyRate']}');
      print('  All applicant keys: ${applicant.keys.toList()}');
      
      print('📡 [TOURIST_TRIPS] Calling Firebase service to get guide details for ID: ${applicant['guideId']}...');
      // Fetch detailed guide information from users collection
      DocumentSnapshot userDoc = await _firebaseService.getUserData(applicant['guideId']);
      Map<String, dynamic>? guideDetails = userDoc.exists ? userDoc.data() as Map<String, dynamic>? : null;
      
      // Debug: Print guide details
      if (guideDetails != null) {
        print('✅ [TOURIST_TRIPS] Guide details fetched successfully:');
        print('  Experience: ${guideDetails['experience']}');
        print('  Specialties: ${guideDetails['specialties']}');
        print('  Languages: ${guideDetails['languages']}');
        print('  Name: ${guideDetails['name']}');
        print('  Email: ${guideDetails['email']}');
      } else {
        print('⚠️ [TOURIST_TRIPS] No guide details found for ID: ${applicant['guideId']}');
      }
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      print('🎯 [TOURIST_TRIPS] Showing applicant profile modal...');
      // Show detailed profile modal
      if (mounted) {
        _showApplicantProfileModal(context, applicant, guideDetails);
      }
    } catch (e) {
      print('❌ [TOURIST_TRIPS] Error loading guide details for applicant ${applicant['id']}: $e');
      print('📊 [TOURIST_TRIPS] Stack trace: ${StackTrace.current}');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading guide details: $e'),
          backgroundColor: Colors.red,
        ),
        );
      }
    }
  }

  void _showApplicantProfileModal(BuildContext context, Map<String, dynamic> applicant, Map<String, dynamic>? guideDetails) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                    ),
                    child: applicant['guideProfileImage'] != null
                        ? ClipOval(
                            child: Image.network(
                              applicant['guideProfileImage'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Guide Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserNameWithVerification(
                          name: applicant['guideName']?.toString() ?? 'Unknown Guide',
                          verificationStatus: applicant['guideVerificationStatus']?.toString() ?? 'pending',
                          nameStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3748),
                          ),
                          badgeSize: 18,
                          showBadgeText: true,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              applicant['guideLocation']?.toString() ?? 'Unknown Location',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(applicant['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Status: ${applicant['status']?.toString() ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(applicant['status']),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Proposal Section
                    _buildProfileSection(
                      'Proposal Details',
                      Icons.description,
                      [
                        _buildInfoRow('Daily Rate', 'LKR ${applicant['dailyRate']?.toString() ?? '0'}'),
                        _buildInfoRow('Hourly Rate', 'LKR ${applicant['hourlyRate']?.toString() ?? '0'}'),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Request Message - Always show this section
                      _buildProfileSection(
                      'Request Message',
                        Icons.message,
                        [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                            applicant['requestMessage']?.toString().isNotEmpty == true 
                                ? applicant['requestMessage'].toString()
                                : 'No message provided by the guide',
                              style: TextStyle(
                              color: applicant['requestMessage']?.toString().isNotEmpty == true 
                                  ? Colors.grey[700]
                                  : Colors.grey[500],
                                fontSize: 14,
                                height: 1.4,
                              fontStyle: applicant['requestMessage']?.toString().isNotEmpty == true 
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Guide Experience
                    _buildProfileSection(
                      'Guide Experience',
                      Icons.work_outline,
                      [
                        _buildInfoRow('Years of Experience', '${guideDetails?['experience']?.toString() ?? 'Not specified'} years'),
                        _buildInfoRow('Specialties', _formatList(guideDetails?['specialties'])),
                        _buildInfoRow('Languages', _formatList(guideDetails?['languages'])),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Trip Details
                    _buildProfileSection(
                      'Trip Information',
                      Icons.trip_origin,
                      [
                        _buildInfoRow('Trip Description', applicant['tripDescription']?.toString() ?? 'Not specified'),
                        _buildInfoRow('Trip Location', applicant['tripLocation']?.toString() ?? 'Not specified'),
                        _buildInfoRow('Trip Start Date', _formatDate(applicant['tripStartDate'])),
                        _buildInfoRow('Applied On', _formatDate(applicant['appliedAt'])),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Action Buttons based on status
                    _buildDetailedApplicantActions(applicant),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF667eea), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3748),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2d3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatList(dynamic list) {
    if (list == null) return 'Not specified';
    if (list is List) {
      return list.isEmpty ? 'Not specified' : list.join(', ');
    }
    return list.toString();
  }

  void _acceptApplicant(Map<String, dynamic> applicant) async {
    print('✅ [TOURIST_TRIPS] Starting to accept applicant: ${applicant['id']}');
    print('📋 [TOURIST_TRIPS] Guide: ${applicant['guideName']}, Trip: ${applicant['tripId']}');
    
    try {
      // Show confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Accept Guide'),
          content: Text(
            'Are you sure you want to accept ${applicant['guideName'] ?? 'this guide'}? '
            'This will automatically reject all other pending applications for this trip.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        print('❌ [TOURIST_TRIPS] User cancelled accepting applicant');
        return;
      }

      print('📡 [TOURIST_TRIPS] User confirmed acceptance. Calling Firebase service...');
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Accept the guide and reject all others
      await _firebaseService.acceptGuideAndRejectOthers(
        applicant['id'], 
        applicant['tripId']
      );
      print('✅ [TOURIST_TRIPS] Successfully accepted guide and rejected others');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${applicant['guideName'] ?? 'Guide'} accepted successfully! '
              'All other applications have been automatically rejected.'
            ),
          backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
        ),
      );
      }
      
      // Refresh the applicants list
      if (mounted) {
      Navigator.pop(context);
      _viewApplicants({'id': applicant['tripId'], 'description': 'Trip'});
      }
    } catch (e) {
      print('❌ [TOURIST_TRIPS] Error accepting applicant ${applicant['id']}: $e');
      print('📊 [TOURIST_TRIPS] Stack trace: ${StackTrace.current}');
      
      // Close loading dialog if it's open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting applicant: $e'),
          backgroundColor: Colors.red,
        ),
      );
      }
    }
  }

  void _rejectApplicant(Map<String, dynamic> applicant) async {
    print('❌ [TOURIST_TRIPS] Starting to reject applicant: ${applicant['id']}');
    print('📋 [TOURIST_TRIPS] Guide: ${applicant['guideName']}, Trip: ${applicant['tripId']}');
    
    try {
      print('📡 [TOURIST_TRIPS] Calling Firebase service to update application status to rejected...');
      await _firebaseService.updateApplicationStatus(applicant['id'], 'Rejected');
      print('✅ [TOURIST_TRIPS] Successfully rejected applicant');
      
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Applicant rejected'),
          backgroundColor: Colors.orange,
        ),
      );
      }
      
      // Refresh the applicants list
      if (mounted) {
      Navigator.pop(context);
        print('🔄 [TOURIST_TRIPS] Refreshing applicants list...');
      _viewApplicants({'id': applicant['tripId'], 'description': 'Trip'});
      }
    } catch (e) {
      print('❌ [TOURIST_TRIPS] Error rejecting applicant ${applicant['id']}: $e');
      print('📊 [TOURIST_TRIPS] Stack trace: ${StackTrace.current}');
      
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting applicant: $e'),
          backgroundColor: Colors.red,
        ),
      );
      }
    }
  }

  void _cancelTrip(Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (context) => CancelTripDialog(
        trip: trip,
        onConfirm: (reason) async {
          Navigator.pop(context); // Close dialog
          await _confirmCancelTrip(trip, reason);
        },
      ),
    );
  }

  Future<void> _confirmCancelTrip(Map<String, dynamic> trip, String reason) async {
    try {
      // Show loading with progress message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
              SizedBox(height: 16),
              Text(
                'Cancelling trip and notifying guides...',
                style: TextStyle(
                  color: Color(0xFF667eea),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );

      // Get all pending applications for this trip
      List<Map<String, dynamic>> applications = await _firebaseService.getTripApplicationsByTrip(trip['id']);
      List<Map<String, dynamic>> pendingApplications = applications.where((app) => app['status'] == 'Pending').toList();

      // Update trip status to cancelled with reason
      await _firebaseService.updateTripStatus(trip['id'], 'cancelled', reason);

      // Auto-reject all pending applications
      int rejectedCount = 0;
      for (var application in pendingApplications) {
        try {
          await _firebaseService.updateApplicationStatus(application['id'], 'Rejected', reason);
          rejectedCount++;
        } catch (e) {
          print('Error rejecting application ${application['id']}: $e');
        }
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message with details
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rejectedCount > 0 
              ? 'Trip cancelled successfully. $rejectedCount pending applications were automatically rejected.'
              : 'Trip cancelled successfully.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      }

      // Refresh the trips list
      if (mounted) _loadData();
    } catch (e) {
      print('❌ [TOURIST_TRIPS] Error cancelling trip ${trip['id']}: $e');
      print('📊 [TOURIST_TRIPS] Stack trace: ${StackTrace.current}');
      
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
      }
    }
  }

}

class CancelTripDialog extends StatefulWidget {
  final Map<String, dynamic> trip;
  final Function(String) onConfirm;

  const CancelTripDialog({
    Key? key,
    required this.trip,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<CancelTripDialog> createState() => _CancelTripDialogState();
}

class _CancelTripDialogState extends State<CancelTripDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String _selectedReason = 'Change of plans';

  final List<String> _predefinedReasons = [
    'Change of plans',
    'Found another guide',
    'Trip no longer needed',
    'Budget constraints',
    'Schedule conflict',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cancel, color: Colors.red[600], size: 24),
          const SizedBox(width: 8),
          const Text('Cancel Trip'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel "${widget.trip['title']?.toString() ?? widget.trip['description']?.toString() ?? 'this trip'}"?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Cancellation Reason:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2d3748),
              ),
            ),
            const SizedBox(height: 8),
            
            // Predefined reasons dropdown
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _predefinedReasons.map((reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReason = value!;
                  if (value != 'Other') {
                    _reasonController.clear();
                  }
                });
              },
            ),
            
            const SizedBox(height: 12),
            
            // Custom reason field (only if "Other" is selected)
            if (_selectedReason == 'Other')
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  hintText: 'Please specify the reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 3,
                validator: (value) {
                  if (_selectedReason == 'Other' && (value == null || value.trim().isEmpty)) {
                    return 'Please provide a reason for cancellation';
                  }
                  return null;
                },
              ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All pending applications will be automatically rejected.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Trip'),
        ),
        ElevatedButton(
          onPressed: () {
            String reason = _selectedReason == 'Other' 
                ? _reasonController.text.trim()
                : _selectedReason;
            
            if (reason.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please provide a cancellation reason'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            widget.onConfirm(reason);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancel Trip'),
        ),
      ],
    );
  }
}
