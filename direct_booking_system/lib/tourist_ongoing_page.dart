import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tourist_trips.dart';
import 'components/review_modal.dart';

class TouristOngoingPage extends StatefulWidget {
  const TouristOngoingPage({Key? key}) : super(key: key);

  @override
  State<TouristOngoingPage> createState() => _TouristOngoingPageState();
}

class _TouristOngoingPageState extends State<TouristOngoingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Map<String, dynamic>> _tripsReadyToStart = [];
  List<Map<String, dynamic>> _ongoingTrips = [];
  List<Map<String, dynamic>> _tripHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTripsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTripsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load trips data from Firebase
      final currentUser = _firebaseService.currentUser;
      if (currentUser != null) {
        print('Loading trips for tourist: ${currentUser.uid}');
        
        // Get trips ready to start (accepted applications)
        _tripsReadyToStart = await _firebaseService.getTripsReadyToStart(currentUser.uid);
        
        // Get ongoing trips (started trips)
        _ongoingTrips = await _firebaseService.getOngoingTripsForTourist(currentUser.uid);
        
        // For now, trip history is the same as ongoing trips
        // In the future, you might want to separate completed trips
        _tripHistory = List.from(_ongoingTrips);
        
        print('Loaded ${_tripsReadyToStart.length} trips ready to start');
        print('Loaded ${_ongoingTrips.length} ongoing trips');
        print('Loaded ${_tripHistory.length} trip history items');
      }
    } catch (e) {
      print('Error loading trips data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showReviewModal(Map<String, dynamic> trip) async {
    try {
      // Check if user has already reviewed this trip
      final currentUser = _firebaseService.getCurrentUser();
      if (currentUser == null) return;

      bool hasReviewed = await _firebaseService.hasTouristReviewedTrip(
        trip['id'], 
        currentUser.uid
      );

      if (hasReviewed) {
        // User already reviewed this trip, don't show modal
        return;
      }

      // Prepare guide info for the review modal
      Map<String, dynamic> guideInfo = {
        'id': trip['guideId'],
        'name': trip['guideName'],
        'location': trip['guideLocation'],
        'profileImage': trip['guideProfileImage'],
      };

      // Show review modal
      bool? reviewSubmitted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ReviewModal(
          trip: trip,
          guideInfo: guideInfo,
        ),
      );

      if (reviewSubmitted == true) {
        // Review was submitted successfully
        print('Review submitted for trip: ${trip['id']}');
      }
    } catch (e) {
      print('Error showing review modal: $e');
      // Don't show error to user, just log it
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Trips',
          style: TextStyle(
            color: Color(0xFF2d3748),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF667eea),
          labelColor: const Color(0xFF667eea),
          unselectedLabelColor: Colors.grey[600],
          tabs: const [
            Tab(text: 'Ready to Start'),
            Tab(text: 'Ongoing'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isLoading ? _buildLoadingTab() : _buildReadyToStartTab(),
          _isLoading ? _buildLoadingTab() : _buildOngoingTripsTab(),
          _isLoading ? _buildLoadingTab() : _buildTripHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildLoadingTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading trips...',
            style: TextStyle(
              color: Color(0xFF667eea),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyToStartTab() {
    if (_tripsReadyToStart.isEmpty) {
      return _buildEmptyState(
        icon: Icons.play_circle_outline,
        title: 'No Trips Ready to Start',
        subtitle: 'You don\'t have any trips ready to start at the moment',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTripsData,
      color: const Color(0xFF667eea),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tripsReadyToStart.length,
        itemBuilder: (context, index) {
          final trip = _tripsReadyToStart[index];
          return _buildReadyToStartTripCard(trip);
        },
      ),
    );
  }

  Widget _buildOngoingTripsTab() {
    if (_ongoingTrips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.trip_origin_outlined,
        title: 'No Ongoing Trips',
        subtitle: 'You don\'t have any ongoing trips at the moment',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTripsData,
      color: const Color(0xFF667eea),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ongoingTrips.length,
        itemBuilder: (context, index) {
          final trip = _ongoingTrips[index];
          return _buildOngoingTripCard(trip);
        },
      ),
    );
  }

  Widget _buildTripHistoryTab() {
    if (_tripHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_outlined,
        title: 'No Trip History',
        subtitle: 'You haven\'t completed any trips yet',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTripsData,
      color: const Color(0xFF667eea),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tripHistory.length,
        itemBuilder: (context, index) {
          final trip = _tripHistory[index];
          return _buildHistoryTripCard(trip);
        },
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReadyToStartTripCard(Map<String, dynamic> trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                    ),
                  ),
                  child: const Icon(
                    Icons.play_circle,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['title']?.toString() ?? 'Trip Title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d3748),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip['location']?.toString() ?? 'Location',
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
                    color: _isTripStartDateToday(trip) 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isTripStartDateToday(trip) 
                          ? Colors.green.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _isTripStartDateToday(trip) ? 'Start Today' : 'Ready to Start',
                    style: TextStyle(
                      color: _isTripStartDateToday(trip) ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Guide Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                    ),
                    child: trip['guideProfileImage'] != null
                        ? ClipOval(
                            child: Image.network(
                              trip['guideProfileImage'],
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Guide: ${trip['guideName']?.toString() ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3748),
                          ),
                        ),
                        Text(
                          trip['guideLocation']?.toString() ?? 'Unknown Location',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Trip Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildDetailRow(Icons.calendar_today, 'Start Date', 
                    trip['startDate'] != null ? _formatDate(trip['startDate']) : 'Not specified'),
                _buildDetailRow(Icons.calendar_today, 'End Date', 
                    trip['endDate'] != null ? _formatDate(trip['endDate']) : 'Not specified'),
                _buildDetailRow(Icons.access_time, 'Duration', trip['duration']?.toString() ?? 'Not specified'),
                _buildDetailRow(Icons.attach_money, 'Guide Rate', 'LKR ${trip['dailyRate']?.toString() ?? '0'}/day'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTripDetails(trip),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF667eea)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTripStartDateToday(trip) ? () => _startTrip(trip) : null,
                    icon: Icon(
                      _isTripStartDateToday(trip) ? Icons.play_arrow : Icons.schedule,
                      size: 18,
                    ),
                    label: Text(_isTripStartDateToday(trip) ? 'Start Trip' : 'Not Today'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTripStartDateToday(trip) ? Colors.green[600] : Colors.grey[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Date Information
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isTripStartDateToday(trip) 
                    ? Colors.green[50]
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isTripStartDateToday(trip) 
                      ? Colors.green[200]!
                      : Colors.blue[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isTripStartDateToday(trip) ? Icons.check_circle : Icons.info,
                    color: _isTripStartDateToday(trip) ? Colors.green[600] : Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isTripStartDateToday(trip)
                          ? 'Trip starts today! You can start your trip now.'
                          : 'Trip starts on ${_formatDate(trip['startDate'])}. You can start it on that date.',
                      style: TextStyle(
                        color: _isTripStartDateToday(trip) ? Colors.green[700] : Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingTripCard(Map<String, dynamic> trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                  child: const Icon(
                    Icons.trip_origin,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['title']?.toString() ?? 'Trip Title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d3748),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip['location']?.toString() ?? 'Location',
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Ongoing',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Guide Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                    ),
                    child: trip['guideProfileImage'] != null
                        ? ClipOval(
                            child: Image.network(
                              trip['guideProfileImage'],
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Guide: ${trip['guideName']?.toString() ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3748),
                          ),
                        ),
                        Text(
                          trip['guideLocation']?.toString() ?? 'Unknown Location',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Trip Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildDetailRow(Icons.calendar_today, 'Start Date', 
                    trip['startDate'] != null ? _formatDate(trip['startDate']) : 'Not specified'),
                _buildDetailRow(Icons.calendar_today, 'End Date', 
                    trip['endDate'] != null ? _formatDate(trip['endDate']) : 'Not specified'),
                _buildDetailRow(Icons.access_time, 'Duration', trip['duration']?.toString() ?? 'Not specified'),
                _buildDetailRow(Icons.people, 'Group Type', trip['groupType']?.toString() ?? 'Not specified'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTripDetails(trip),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF667eea)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _completeTrip(trip),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Complete Trip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTripCard(Map<String, dynamic> trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.grey, Colors.grey],
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['title']?.toString() ?? 'Trip Title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d3748),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip['location']?.toString() ?? 'Location',
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
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Trip Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildDetailRow(Icons.calendar_today, 'Start Date', 
                    trip['startDate'] != null ? _formatDate(trip['startDate']) : 'Not specified'),
                _buildDetailRow(Icons.calendar_today, 'End Date', 
                    trip['endDate'] != null ? _formatDate(trip['endDate']) : 'Not specified'),
                _buildDetailRow(Icons.access_time, 'Duration', trip['duration']?.toString() ?? 'Not specified'),
                _buildDetailRow(Icons.people, 'Group Type', trip['groupType']?.toString() ?? 'Not specified'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTripDetails(trip),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF667eea)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReviewModal(trip),
                    icon: const Icon(Icons.star_outline, size: 18),
                    label: const Text('Review'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amber),
                      foregroundColor: Colors.amber[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewTripSummary(trip),
                    icon: const Icon(Icons.summarize_outlined, size: 18),
                    label: const Text('Summary'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      foregroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2d3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not specified';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Invalid date';
    }
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _showTripDetails(Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Details',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trip['title']?.toString() ?? 'Trip Title',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
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
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip Information
                    _buildProfileSection(
                      'Trip Information',
                      Icons.trip_origin,
                      [
                        _buildInfoRow('Title', trip['title']?.toString() ?? 'Not specified'),
                        _buildInfoRow('Location', trip['location']?.toString() ?? 'Not specified'),
                        _buildInfoRow('Start Date', trip['startDate'] != null ? _formatDate(trip['startDate']) : 'Not specified'),
                        _buildInfoRow('End Date', trip['endDate'] != null ? _formatDate(trip['endDate']) : 'Not specified'),
                        _buildInfoRow('Duration', trip['duration']?.toString() ?? 'Not specified'),
                        _buildInfoRow('Group Type', trip['groupType']?.toString() ?? 'Not specified'),
                        _buildInfoRow('Languages Required', trip['languages'] != null ? (trip['languages'] as List<dynamic>).join(', ') : 'Not specified'),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Trip Description
                    if (trip['description'] != null && trip['description'].toString().isNotEmpty)
                      _buildProfileSection(
                        'Trip Description',
                        Icons.description,
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
                              trip['description'].toString(),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    
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

  /// Check if the trip start date matches today's date
  bool _isTripStartDateToday(Map<String, dynamic> trip) {
    try {
      // Get the trip start date
      DateTime? tripStartDate;
      
      if (trip['startDate'] != null) {
        if (trip['startDate'] is DateTime) {
          tripStartDate = trip['startDate'] as DateTime;
        } else if (trip['startDate'] is Timestamp) {
          tripStartDate = (trip['startDate'] as Timestamp).toDate();
        }
      }
      
      if (tripStartDate == null) {
        print('⚠️ Trip start date is null for trip: ${trip['title']}');
        return false;
      }
      
      // Get today's date (without time)
      DateTime today = DateTime.now();
      DateTime todayDateOnly = DateTime(today.year, today.month, today.day);
      DateTime tripDateOnly = DateTime(tripStartDate.year, tripStartDate.month, tripStartDate.day);
      
      bool isToday = tripDateOnly.isAtSameMomentAs(todayDateOnly);
      
      print('📅 Date check for trip: ${trip['title']}');
      print('  Trip start date: $tripStartDate');
      print('  Today: $today');
      print('  Trip date only: $tripDateOnly');
      print('  Today date only: $todayDateOnly');
      print('  Is today: $isToday');
      
      return isToday;
    } catch (e) {
      print('❌ Error checking trip start date: $e');
      return false;
    }
  }

  void _startTrip(Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.play_circle, color: Colors.green[600], size: 24),
            const SizedBox(width: 8),
            const Text('Start Trip'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you ready to start "${trip['title']?.toString() ?? 'this trip'}" with ${trip['guideName']?.toString() ?? 'your guide'}?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Once started, your guide will be notified and the trip will be marked as ongoing.',
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _confirmStartTrip(trip);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Trip'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmStartTrip(Map<String, dynamic> trip) async {
    try {
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
                'Starting trip...',
                style: TextStyle(
                  color: Color(0xFF667eea),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );

      // Start the trip
      await _firebaseService.startTrip(trip['id'], trip['applicationId']);

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip "${trip['title']?.toString() ?? 'Trip'}" started successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Refresh the data
      _loadTripsData();
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _completeTrip(Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 24),
            const SizedBox(width: 8),
            const Text('Complete Trip'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you ready to complete "${trip['title']?.toString() ?? 'this trip'}"?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Once completed, the trip will be moved to your history and your guide will be notified.',
                      style: TextStyle(
                        color: Colors.blue[700],
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _confirmCompleteTrip(trip);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete Trip'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCompleteTrip(Map<String, dynamic> trip) async {
    try {
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
                'Completing trip...',
                style: TextStyle(
                  color: Color(0xFF667eea),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );

      // Complete the trip
      await _firebaseService.completeTrip(trip['id'], trip['applicationId']);

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip "${trip['title']?.toString() ?? 'Trip'}" completed successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Show review modal
      await _showReviewModal(trip);

      // Refresh the data
      _loadTripsData();
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewApplicants(Map<String, dynamic> trip) {
    // Navigate to the tourist trips page to view applicants
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TouristTrips(),
      ),
    );
  }

  void _viewTripSummary(Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trip Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trip: ${trip['title']?.toString() ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Location: ${trip['location']?.toString() ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Duration: ${trip['duration']?.toString() ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Status: Completed'),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
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
              '$label:',
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
                fontWeight: FontWeight.w500,
                color: Color(0xFF2d3748),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
