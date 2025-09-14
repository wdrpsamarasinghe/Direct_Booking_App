import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'trip_application_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuideTripsPage extends StatefulWidget {
  const GuideTripsPage({Key? key}) : super(key: key);

  @override
  State<GuideTripsPage> createState() => _GuideTripsPageState();
}

class _GuideTripsPageState extends State<GuideTripsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Map<String, dynamic>> _availableTrips = [];
  List<Map<String, dynamic>> _myTrips = [];
  List<Map<String, dynamic>> _requestedTrips = [];
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
      // Load available trips from Firebase trips collection
      print('Loading available trips from Firebase...');
      List<Map<String, dynamic>> availableTrips = await _firebaseService.getAllAvailableTrips();
      print('Loaded ${availableTrips.length} trips from Firebase');
      
      // Log if no trips found in Firebase
      if (availableTrips.isEmpty) {
        print('No trips found in Firebase - showing empty state');
      }
      
      // Load applied trips from Firebase
      List<Map<String, dynamic>> appliedTrips = [];
      List<Map<String, dynamic>> ongoingTrips = [];
      final currentUser = _firebaseService.currentUser;
      if (currentUser != null) {
        print('Loading applied trips for guide: ${currentUser.uid}');
        appliedTrips = await _firebaseService.getTripApplicationsByGuide(currentUser.uid);
        print('Loaded ${appliedTrips.length} applied trips');
        
        // Debug: Log each application status
        for (int i = 0; i < appliedTrips.length; i++) {
          final app = appliedTrips[i];
          print('📋 Applied Trip ${i + 1}: ID=${app['id']}, Status=${app['status']}, TripTitle=${app['tripDescription'] ?? app['tripTitle']}');
        }
        
        print('Loading ongoing trips for guide: ${currentUser.uid}');
        ongoingTrips = await _firebaseService.getOngoingTripsForGuide(currentUser.uid);
        print('Loaded ${ongoingTrips.length} ongoing trips');
      }
      
      setState(() {
        _availableTrips = availableTrips;
        _myTrips = ongoingTrips; // Populate with ongoing trips
        _requestedTrips = appliedTrips; // Use real applied trips data
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading trips data: $e');
      
      // On error, show empty state
      setState(() {
        _availableTrips = [];
        _myTrips = [];
        _requestedTrips = [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getSampleAvailableTrips() {
    return [
      {
        'id': 'trip_001',
        'touristName': 'John Smith',
        'touristImage': null,
        'tripTitle': 'Colombo City Tour',
        'location': 'Colombo',
        'startDate': DateTime.now().add(const Duration(days: 2)),
        'endDate': DateTime.now().add(const Duration(days: 3)),
        'duration': '2 days',
        'budget': 15000,
        'currency': 'LKR',
        'participants': 2,
        'languages': ['English'],
        'specialRequirements': 'Vegetarian meals preferred',
        'description': 'Explore the vibrant city of Colombo with its colonial architecture, bustling markets, and cultural sites.',
        'postedDate': DateTime.now().subtract(const Duration(hours: 2)),
        'status': 'open',
      },
      {
        'id': 'trip_002',
        'touristName': 'Maria Garcia',
        'touristImage': null,
        'tripTitle': 'Kandy Cultural Experience',
        'location': 'Kandy',
        'startDate': DateTime.now().add(const Duration(days: 5)),
        'endDate': DateTime.now().add(const Duration(days: 6)),
        'duration': '1 day',
        'budget': 8000,
        'currency': 'LKR',
        'participants': 1,
        'languages': ['English', 'Spanish'],
        'specialRequirements': 'Visit Temple of the Tooth',
        'description': 'Immerse yourself in Kandy\'s rich cultural heritage, including the sacred Temple of the Tooth.',
        'postedDate': DateTime.now().subtract(const Duration(hours: 5)),
        'status': 'open',
      },
      {
        'id': 'trip_003',
        'touristName': 'David Wilson',
        'touristImage': null,
        'tripTitle': 'Galle Fort Exploration',
        'location': 'Galle',
        'startDate': DateTime.now().add(const Duration(days: 7)),
        'endDate': DateTime.now().add(const Duration(days: 8)),
        'duration': '1 day',
        'budget': 12000,
        'currency': 'LKR',
        'participants': 3,
        'languages': ['English'],
        'specialRequirements': 'Photography tour',
        'description': 'Discover the historic Galle Fort with its Dutch colonial architecture and stunning ocean views.',
        'postedDate': DateTime.now().subtract(const Duration(hours: 1)),
        'status': 'open',
      },
    ];
  }

  List<Map<String, dynamic>> _getSampleMyTrips() {
    return [
      {
        'id': 'trip_004',
        'touristName': 'Sarah Johnson',
        'touristImage': null,
        'tripTitle': 'Sigiriya Rock Fortress',
        'location': 'Sigiriya',
        'startDate': DateTime.now().add(const Duration(days: 3)),
        'endDate': DateTime.now().add(const Duration(days: 4)),
        'duration': '1 day',
        'budget': 18000,
        'currency': 'LKR',
        'participants': 2,
        'languages': ['English'],
        'specialRequirements': 'Early morning start',
        'description': 'Climb the ancient Sigiriya Rock Fortress and explore its fascinating history.',
        'status': 'confirmed',
        'confirmedDate': DateTime.now().subtract(const Duration(days: 1)),
        'touristPhone': '+94 77 123 4567',
        'touristEmail': 'sarah.johnson@email.com',
      },
      {
        'id': 'trip_005',
        'touristName': 'Michael Brown',
        'touristImage': null,
        'tripTitle': 'Ella Scenic Train Ride',
        'location': 'Ella',
        'startDate': DateTime.now().add(const Duration(days: 10)),
        'endDate': DateTime.now().add(const Duration(days: 11)),
        'duration': '1 day',
        'budget': 10000,
        'currency': 'LKR',
        'participants': 1,
        'languages': ['English'],
        'specialRequirements': 'Train booking assistance',
        'description': 'Experience the scenic train journey to Ella with breathtaking mountain views.',
        'status': 'pending',
        'appliedDate': DateTime.now().subtract(const Duration(hours: 3)),
        'touristPhone': '+94 71 987 6543',
        'touristEmail': 'michael.brown@email.com',
      },
    ];
  }

  List<Map<String, dynamic>> _getSampleRequestedTrips() {
    return [
      {
        'id': 'trip_006',
        'touristName': 'Emma Davis',
        'touristImage': null,
        'tripTitle': 'Nuwara Eliya Tea Plantation Tour',
        'location': 'Nuwara Eliya',
        'startDate': DateTime.now().add(const Duration(days: 6)),
        'endDate': DateTime.now().add(const Duration(days: 7)),
        'duration': '1 day',
        'budget': 14000,
        'currency': 'LKR',
        'participants': 2,
        'languages': ['English'],
        'specialRequirements': 'Tea tasting experience',
        'description': 'Explore the beautiful tea plantations of Nuwara Eliya and learn about tea production.',
        'status': 'requested',
        'requestedDate': DateTime.now().subtract(const Duration(hours: 2)),
        'applicationStatus': 'pending',
        'touristPhone': '+94 76 555 1234',
        'touristEmail': 'emma.davis@email.com',
      },
      {
        'id': 'trip_007',
        'touristName': 'James Wilson',
        'touristImage': null,
        'tripTitle': 'Mirissa Whale Watching',
        'location': 'Mirissa',
        'startDate': DateTime.now().add(const Duration(days: 8)),
        'endDate': DateTime.now().add(const Duration(days: 9)),
        'duration': '1 day',
        'budget': 16000,
        'currency': 'LKR',
        'participants': 4,
        'languages': ['English', 'French'],
        'specialRequirements': 'Early morning boat trip',
        'description': 'Experience whale watching in Mirissa with professional boat services.',
        'status': 'requested',
        'requestedDate': DateTime.now().subtract(const Duration(hours: 5)),
        'applicationStatus': 'pending',
        'touristPhone': '+94 75 444 5678',
        'touristEmail': 'james.wilson@email.com',
      },
      {
        'id': 'trip_008',
        'touristName': 'Lisa Anderson',
        'touristImage': null,
        'tripTitle': 'Anuradhapura Ancient City',
        'location': 'Anuradhapura',
        'startDate': DateTime.now().add(const Duration(days: 12)),
        'endDate': DateTime.now().add(const Duration(days: 13)),
        'duration': '1 day',
        'budget': 13000,
        'currency': 'LKR',
        'participants': 1,
        'languages': ['English'],
        'specialRequirements': 'Historical knowledge required',
        'description': 'Discover the ancient city of Anuradhapura with its sacred Buddhist sites.',
        'status': 'requested',
        'requestedDate': DateTime.now().subtract(const Duration(hours: 1)),
        'applicationStatus': 'pending',
        'touristPhone': '+94 78 333 9999',
        'touristEmail': 'lisa.anderson@email.com',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      appBar: AppBar(
        title: const Text(
          'My Trips',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              print('Manual refresh triggered');
              _loadTripsData();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: () async {
              print('Debug button pressed');
              try {
                final debugTrips = await _firebaseService.getAllTripsDebug();
                print('Debug: Found ${debugTrips.length} total trips in database');
                for (var trip in debugTrips) {
                  print('Debug trip: ${trip['id']} - ${trip['description']} - ${trip['touristName']} - ${trip['status']}');
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Debug: Found ${debugTrips.length} trips in database. Check console for details.'),
                    backgroundColor: Colors.blue,
                  ),
                );
              } catch (e) {
                print('Debug error: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Debug error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            tooltip: 'Debug',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white),
            onPressed: () async {
              print('Create test trip button pressed');
              try {
                await _firebaseService.createTestTrip();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test trip created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Refresh the trips data
                _loadTripsData();
              } catch (e) {
                print('Error creating test trip: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating test trip: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            tooltip: 'Create Test Trip',
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () async {
              print('Test specific trip button pressed');
              try {
                await _firebaseService.testSpecificTrip();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Check console for specific trip test results'),
                    backgroundColor: Colors.blue,
                  ),
                );
              } catch (e) {
                print('Error testing specific trip: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error testing specific trip: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            tooltip: 'Test Specific Trip',
          ),
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: () async {
              print('Test unfiltered trips button pressed');
              try {
                final unfilteredTrips = await _firebaseService.getAllTripsUnfiltered();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Found ${unfilteredTrips.length} trips (unfiltered). Check console for details.'),
                    backgroundColor: Colors.purple,
                  ),
                );
              } catch (e) {
                print('Error testing unfiltered trips: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error testing unfiltered trips: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            tooltip: 'Test Unfiltered Trips',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.search),
              text: 'Available Trips',
            ),
            Tab(
              icon: Icon(Icons.assignment),
              text: 'My Trips',
            ),
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Applied',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isLoading ? _buildLoadingTab() : _buildAvailableTripsTab(),
          _isLoading ? _buildLoadingTab() : _buildMyTripsTab(),
          _isLoading ? _buildLoadingTab() : _buildRequestedTripsTab(),
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

  Widget _buildAvailableTripsTab() {
    if (_availableTrips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'No Available Trips',
        subtitle: 'No trips are currently available in your area',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTripsData,
      color: const Color(0xFF667eea),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableTrips.length,
        itemBuilder: (context, index) {
          final trip = _availableTrips[index];
          return _buildAvailableTripCard(trip);
        },
      ),
    );
  }

  Widget _buildMyTripsTab() {
    if (_myTrips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_outlined,
        title: 'No Ongoing Trips',
        subtitle: 'You don\'t have any ongoing trips at the moment',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTripsData,
      color: const Color(0xFF667eea),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myTrips.length,
        itemBuilder: (context, index) {
          final trip = _myTrips[index];
          return _buildMyTripCard(trip);
        },
      ),
    );
  }

  Widget _buildRequestedTripsTab() {
    if (_requestedTrips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.pending_actions_outlined,
        title: 'No Requested Trips',
        subtitle: 'You haven\'t applied for any trips yet',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTripsData,
      color: const Color(0xFF667eea),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requestedTrips.length,
        itemBuilder: (context, index) {
          final trip = _requestedTrips[index];
          return _buildRequestedTripCard(trip);
        },
      ),
    );
  }

  Widget _buildAvailableTripCard(Map<String, dynamic> trip) {
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
                // Tourist Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                  ),
                  child: trip['touristImage'] != null
                      ? ClipOval(
                          child: Image.network(
                            trip['touristImage'],
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
                
                // Trip Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['description']?.toString() ?? 'Trip Description',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by ${trip['touristName']?.toString() ?? 'Unknown Tourist'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Budget
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      trip['budget']?.toString() ?? 'Flexible',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667eea),
                      ),
                    ),
                    Text(
                      'Budget',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Trip Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildDetailRow(Icons.location_on, 'Location', 
                    trip['location']?.toString() ?? 'Not specified'),
                _buildDetailRow(Icons.calendar_today, 'Date', 
                    trip['startDate'] != null ? _formatDate(trip['startDate']) : 'Not specified'),
                _buildDetailRow(Icons.access_time, 'Duration', 
                    trip['duration']?.toString() ?? 'Not specified'),
                _buildDetailRow(Icons.people, 'Group Type', 
                    trip['groupType']?.toString() ?? 'Not specified'),
                _buildDetailRow(Icons.language, 'Languages', 
                    trip['languages'] != null ? (trip['languages'] as List<dynamic>).join(', ') : 'Not specified'),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              trip['description']?.toString() ?? 'No description available',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showTripDetails(trip),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('View Details'),
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
                      child: OutlinedButton.icon(
                        onPressed: () => _viewTouristProfile(trip),
                        icon: const Icon(Icons.person_outline, size: 18),
                        label: const Text('View Tourist'),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _applyForTrip(trip),
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Apply for Trip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildMyTripCard(Map<String, dynamic> trip) {
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
                // Trip Icon
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
                
                // Trip Info
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
                        'with ${trip['touristName']?.toString() ?? 'Tourist'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
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
          
          // Trip Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildDetailRow(Icons.location_on, 'Location', trip['location']?.toString() ?? 'Not specified'),
                _buildDetailRow(Icons.calendar_today, 'Start Date', 
                    trip['startDate'] != null ? _formatDate(trip['startDate']) : 'Not specified'),
                _buildDetailRow(Icons.calendar_today, 'End Date', 
                    trip['endDate'] != null ? _formatDate(trip['endDate']) : 'Not specified'),
                _buildDetailRow(Icons.access_time, 'Duration', trip['duration']?.toString() ?? 'Not specified'),
                _buildDetailRow(Icons.attach_money, 'Daily Rate', 'LKR ${trip['dailyRate']?.toString() ?? '0'}'),
                _buildDetailRow(Icons.schedule, 'Applied On', 
                    trip['appliedAt'] != null ? _formatDate(trip['appliedAt']) : 'Not specified'),
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
                    onPressed: () => _showOngoingTripDetails(trip),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Trip Details'),
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
                    onPressed: () => _contactTourist(trip),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Contact Tourist'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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

  Widget _buildRequestedTripCard(Map<String, dynamic> application) {
    // Handle both old sample data structure and new application data structure
    final tripTitle = application['tripDescription']?.toString() ?? 
                     application['tripTitle']?.toString() ?? 
                     'Trip Application';
    final touristName = application['touristName']?.toString() ?? 'Unknown Tourist';
    final location = application['tripLocation']?.toString() ?? 
                     application['location']?.toString() ?? 
                     'Not specified';
    final appliedDate = application['appliedAt'] ?? application['requestedDate'];
    final status = application['status']?.toString() ?? 'pending';
    final dailyRate = application['dailyRate']?.toString() ?? '0';
    final hourlyRate = application['hourlyRate']?.toString() ?? '0';

    // Debug: Log the status being processed
    print('🎨 [GUIDE_TRIPS] Processing application ${application['id']} with status: "$status"');

    Color statusColor;
    String statusText;
    
    switch (status.toLowerCase()) {
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'Accepted';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      case 'started':
        statusColor = Colors.blue;
        statusText = 'Started';
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusText = 'Completed';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status.toUpperCase(); // Show actual status if unknown
    }

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
                // Tourist Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                  ),
                  child: application['touristImage'] != null
                      ? ClipOval(
                          child: Image.network(
                            application['touristImage'],
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
                
                // Trip Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tripTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by $touristName',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
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
                _buildDetailRow(Icons.location_on, 'Location', location),
                if (application['tripStartDate'] != null)
                  _buildDetailRow(Icons.calendar_today, 'Trip Date', 
                      _formatDate(application['tripStartDate'])),
                _buildDetailRow(Icons.attach_money, 'Daily Rate', 'LKR $dailyRate'),
                _buildDetailRow(Icons.access_time, 'Hourly Rate', 'LKR $hourlyRate'),
                if (appliedDate != null)
                  _buildDetailRow(Icons.schedule, 'Applied', 
                      _formatTimeAgo(appliedDate)),
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
                    onPressed: () => _showApplicationDetails(application),
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
                // Only show withdraw button if application is not rejected
                if (application['status']?.toString().toLowerCase() != 'rejected') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _withdrawApplication(application),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Withdraw'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
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
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
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

  String _formatTimeAgo(dynamic date) {
    if (date == null) return 'Unknown';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Invalid date';
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
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
                          trip['description']?.toString() ?? 'Trip Description',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${trip['touristName']?.toString() ?? 'Unknown Tourist'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
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
                    _buildDetailSection('Trip Information', [
                      _buildInfoRow('Location', trip['location']?.toString() ?? 'Not specified'),
                      _buildInfoRow('Start Date', trip['startDate'] != null ? _formatDate(trip['startDate']) : 'Not specified'),
                      _buildInfoRow('Duration', trip['duration']?.toString() ?? 'Not specified'),
                      _buildInfoRow('Group Type', trip['groupType']?.toString() ?? 'Not specified'),
                      _buildInfoRow('Budget', trip['budget']?.toString() ?? 'Flexible'),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    _buildDetailSection('Requirements', [
                      Text(
                        trip['description']?.toString() ?? 'No description available',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      if (trip['requirements'] != null && (trip['requirements'] as List).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Special Requirements: ${(trip['requirements'] as List<dynamic>).join(', ')}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (trip['additionalInfo'] != null && trip['additionalInfo'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Additional Info: ${trip['additionalInfo']}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ]),
                    
                    if (trip['touristEmail'] != null)
                      _buildDetailSection('Contact Information', [
                        _buildInfoRow('Email', trip['touristEmail']?.toString() ?? 'Not available'),
                        if (trip['contactInfo'] != null && trip['contactInfo'].toString().isNotEmpty)
                          _buildInfoRow('Contact Info', trip['contactInfo']?.toString() ?? 'Not available'),
                      ]),
                    
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2d3748),
          ),
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

  void _viewTouristProfile(Map<String, dynamic> trip) async {
    // Show loading dialog while fetching tourist profile data
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
        ),
      ),
    );

    // Fetch tourist profile data from users collection
    DocumentSnapshot? touristProfile;
    try {
      touristProfile = await _firebaseService.getUserData(trip['touristId']);
      if (touristProfile?.exists == true) {
        print('Tourist profile fetched successfully from users collection: ${touristProfile!.data()}');
      } else {
        print('Tourist profile not found in users collection for ID: ${trip['touristId']}');
      }
    } catch (e) {
      print('Error fetching tourist profile from users collection: $e');
    }

    // Close loading dialog
    Navigator.pop(context);

    // Show the profile modal with tourist data
    if (!mounted) return;
    
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
                  // Tourist Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green[100],
                    backgroundImage: touristProfile?.data() != null && 
                        (touristProfile!.data() as Map<String, dynamic>)['profileImageUrl'] != null
                        ? NetworkImage((touristProfile.data() as Map<String, dynamic>)['profileImageUrl'])
                        : null,
                    child: touristProfile?.data() == null || 
                        (touristProfile!.data() as Map<String, dynamic>)['profileImageUrl'] == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.green,
                            size: 40,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  
                  // Tourist Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          touristProfile?.data() != null 
                              ? (touristProfile!.data() as Map<String, dynamic>)['name']?.toString() ?? 'Unknown Tourist'
                              : 'Unknown Tourist',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trip Requester',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
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
                child: _buildTouristProfileContent(touristProfile, trip),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyForTrip(Map<String, dynamic> trip) async {
    // Check if guide has already applied for this trip
    final currentUser = _firebaseService.currentUser;
    if (currentUser != null) {
      final hasApplied = await _firebaseService.hasGuideAppliedForTrip(currentUser.uid, trip['id']);
      if (hasApplied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already applied for this trip'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Navigate to application form
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripApplicationForm(
          trip: trip,
          onApplicationSubmitted: () {
            // Reload trips data after successful application
            _loadTripsData();
          },
        ),
      ),
    );

    // If application was submitted successfully, update the UI
    if (result == true) {
      // Move trip from available to requested (for immediate UI feedback)
      setState(() {
        _availableTrips.removeWhere((t) => t['id'] == trip['id']);
        _requestedTrips.add({
          ...trip,
          'status': 'requested',
          'requestedDate': DateTime.now(),
          'applicationStatus': 'pending',
        });
      });
    }
  }

  void _contactTourist(Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${trip['touristName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactInfo(Icons.phone, 'Phone', trip['touristPhone']),
            const SizedBox(height: 12),
            _buildContactInfo(Icons.email, 'Email', trip['touristEmail']),
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

  Widget _buildContactInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF667eea)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF667eea)),
          ),
        ),
      ],
    );
  }

  void _showApplicationDetails(Map<String, dynamic> application) {
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
                          'Application Details',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trip: ${application['tripDescription']?.toString() ?? 'Unknown Trip'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
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
                    _buildDetailSection('Application Information', [
                      _buildInfoRow('Status', application['status']?.toString() ?? 'Pending'),
                      _buildInfoRow('Applied Date', application['appliedAt'] != null ? _formatDate(application['appliedAt']) : 'Unknown'),
                      _buildInfoRow('Daily Rate', 'LKR ${application['dailyRate']?.toString() ?? '0'}'),
                      _buildInfoRow('Hourly Rate', 'LKR ${application['hourlyRate']?.toString() ?? '0'}'),
                      _buildInfoRow('Total Cost', 'LKR ${application['totalTripCost']?.toString() ?? '0'}'),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    _buildDetailSection('Professional Information', [
                      _buildInfoRow('Experience', application['experience']?.toString() ?? 'Not specified'),
                      _buildInfoRow('Specializations', (application['specializations'] as List<dynamic>?)?.join(', ') ?? 'Not specified'),
                      _buildInfoRow('Languages', (application['languages'] as List<dynamic>?)?.join(', ') ?? 'Not specified'),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    _buildDetailSection('Proposed Itinerary', [
                      Text(
                        application['proposedItinerary']?.toString() ?? 'No itinerary provided',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    _buildDetailSection('Why Perfect for This Trip', [
                      Text(
                        application['whyPerfect']?.toString() ?? 'No explanation provided',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ]),
                    
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

  void _withdrawApplication(Map<String, dynamic> application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Application'),
        content: Text('Are you sure you want to withdraw your application for "${application['tripDescription']?.toString() ?? 'this trip'}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Delete application from Firebase
                await _firebaseService.deleteTripApplication(application['id']);
                
                // Remove from local state
                setState(() {
                  _requestedTrips.removeWhere((t) => t['id'] == application['id']);
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Application withdrawn for "${application['tripDescription']?.toString() ?? 'the trip'}"'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error withdrawing application: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  Widget _buildTouristProfileContent(DocumentSnapshot? touristProfile, Map<String, dynamic> trip) {
    final Map<String, dynamic>? profileData = touristProfile?.data() as Map<String, dynamic>?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show message if tourist profile not found
        if (touristProfile?.exists != true)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tourist Profile Not Available',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unable to fetch tourist profile from the database. You can still apply for this trip.',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Tourist Information
        _buildProfileSection(
          'Tourist Information',
          Icons.person,
          [
            _buildInfoRow('Name', profileData?['name']?.toString() ?? 'Not specified'),
            _buildInfoRow('Email', profileData?['email']?.toString() ?? 'Not specified'),
            _buildInfoRow('Phone', profileData?['phone']?.toString() ?? 'Not specified'),
            if (profileData?['nationality'] != null && profileData!['nationality'].toString().isNotEmpty)
              _buildInfoRow('Nationality', profileData!['nationality'].toString()),
            if (profileData?['age'] != null && profileData!['age'].toString().isNotEmpty)
              _buildInfoRow('Age', profileData!['age'].toString()),
            if (profileData?['gender'] != null && profileData!['gender'].toString().isNotEmpty)
              _buildInfoRow('Gender', profileData!['gender'].toString()),
            if (profileData?['occupation'] != null && profileData!['occupation'].toString().isNotEmpty)
              _buildInfoRow('Occupation', profileData!['occupation'].toString()),
            if (profileData?['languages'] != null && profileData!['languages'] is List)
              _buildInfoRow('Languages', (profileData!['languages'] as List).join(', ')),
            if (profileData?['interests'] != null && profileData!['interests'] is List)
              _buildInfoRow('Interests', (profileData!['interests'] as List).join(', ')),
            if (profileData?['bio'] != null && profileData!['bio'].toString().isNotEmpty)
              _buildInfoRow('Bio', profileData!['bio'].toString()),
            if (profileData?['createdAt'] != null)
              _buildInfoRow('Member Since', _formatDate(profileData!['createdAt'])),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Trip Information
        _buildProfileSection(
          'Trip Details',
          Icons.trip_origin,
          [
            _buildInfoRow('Trip Title', trip['title']?.toString() ?? 'Not specified'),
            _buildInfoRow('Location', trip['location']?.toString() ?? 'Not specified'),
            _buildInfoRow('Start Date', trip['startDate'] != null ? _formatDate(trip['startDate']) : 'Not specified'),
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
        
        // Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _applyForTrip(trip);
            },
            icon: const Icon(Icons.send),
            label: const Text('Apply for this Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
          ),
        ),
        
        const SizedBox(height: 20),
      ],
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

  void _showOngoingTripDetails(Map<String, dynamic> trip) {
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
                          'Ongoing Trip Details',
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
                    
                    // Application Details
                    _buildProfileSection(
                      'Application Details',
                      Icons.assignment,
                      [
                        _buildInfoRow('Daily Rate', 'LKR ${trip['dailyRate']?.toString() ?? '0'}'),
                        _buildInfoRow('Hourly Rate', 'LKR ${trip['hourlyRate']?.toString() ?? '0'}'),
                        _buildInfoRow('Applied On', trip['appliedAt'] != null ? _formatDate(trip['appliedAt']) : 'Not specified'),
                        _buildInfoRow('Status', 'Accepted'),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Tourist Information
                    _buildProfileSection(
                      'Tourist Information',
                      Icons.person,
                      [
                        _buildInfoRow('Name', trip['touristName']?.toString() ?? 'Not specified'),
                        _buildInfoRow('Email', trip['touristEmail']?.toString() ?? 'Not specified'),
                        if (trip['touristPhone'] != null && trip['touristPhone'].toString().isNotEmpty)
                          _buildInfoRow('Phone', trip['touristPhone'].toString()),
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
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _contactTourist(trip);
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Contact Tourist'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                      ),
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

}
