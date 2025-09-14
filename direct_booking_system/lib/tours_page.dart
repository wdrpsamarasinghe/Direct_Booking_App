import 'package:flutter/material.dart';

class ToursPage extends StatefulWidget {
  const ToursPage({Key? key}) : super(key: key);

  @override
  State<ToursPage> createState() => _ToursPageState();
}

class _ToursPageState extends State<ToursPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Draft', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Filter Tabs
            _buildFilterTabs(),
            
            // Tours List
            Expanded(
              child: _buildToursList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle create new tour
        },
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Text(
            'My Tours',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3748),
            ),
          ),
          const Spacer(),
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
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Handle search
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF667eea) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4a5568),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToursList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildTourCard(
          title: 'Historic City Walk',
          description: 'Explore the rich history of our beautiful city with guided tours through ancient landmarks.',
          duration: '2 hours',
          price: '\$45',
          rating: 4.8,
          bookings: 127,
          status: 'Active',
          image: 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=400',
          isActive: true,
        ),
        const SizedBox(height: 16),
        _buildTourCard(
          title: 'Mountain Adventure',
          description: 'Experience breathtaking views and thrilling hikes through scenic mountain trails.',
          duration: '6 hours',
          price: '\$120',
          rating: 4.9,
          bookings: 89,
          status: 'Active',
          image: 'https://images.unsplash.com/photo-1464822759844-d150baec0134?w=400',
          isActive: true,
        ),
        const SizedBox(height: 16),
        _buildTourCard(
          title: 'Food & Culture Tour',
          description: 'Discover local cuisine and cultural traditions in this immersive food experience.',
          duration: '3 hours',
          price: '\$75',
          rating: 4.7,
          bookings: 156,
          status: 'Draft',
          image: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400',
          isActive: false,
        ),
        const SizedBox(height: 16),
        _buildTourCard(
          title: 'Sunset Beach Walk',
          description: 'Relaxing evening walk along pristine beaches with stunning sunset views.',
          duration: '1.5 hours',
          price: '\$35',
          rating: 4.6,
          bookings: 203,
          status: 'Completed',
          image: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400',
          isActive: false,
        ),
      ],
    );
  }

  Widget _buildTourCard({
    required String title,
    required String description,
    required String duration,
    required String price,
    required double rating,
    required int bookings,
    required String status,
    required String image,
    required bool isActive,
  }) {
    return Container(
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
          // Tour Image
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: DecorationImage(
                image: NetworkImage(image),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Status Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                // Price Badge
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tour Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d3748),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFed8936),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2d3748),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Stats Row
                Row(
                  children: [
                    _buildStatItem(
                      icon: Icons.access_time,
                      text: duration,
                    ),
                    const SizedBox(width: 20),
                    _buildStatItem(
                      icon: Icons.people,
                      text: '$bookings bookings',
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Handle edit tour
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF667eea),
                          side: const BorderSide(color: Color(0xFF667eea)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle view details
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF48bb78);
      case 'draft':
        return const Color(0xFFed8936);
      case 'completed':
        return const Color(0xFF667eea);
      default:
        return Colors.grey;
    }
  }
}

