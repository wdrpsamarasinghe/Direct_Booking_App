import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'components/notification_badge.dart';

class GuideNotificationsPage extends StatefulWidget {
  const GuideNotificationsPage({Key? key}) : super(key: key);

  @override
  State<GuideNotificationsPage> createState() => _GuideNotificationsPageState();
}

class _GuideNotificationsPageState extends State<GuideNotificationsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  
  List<Map<String, dynamic>> _tourNotifications = [];
  bool _isLoading = true;
  int _totalUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser != null) {
        print('🔔 Loading tour notifications for guide: ${currentUser.uid}');
        
        // Get only tour-related notifications
        Map<String, List<Map<String, dynamic>>> tourNotificationsMap = 
            await _firebaseService.getGuideTourNotifications(currentUser.uid);
        
        // Flatten all tour notifications into a single list
        List<Map<String, dynamic>> tourNotifications = [];
        for (var category in tourNotificationsMap.values) {
          tourNotifications.addAll(category);
        }
        
        // Sort by notification time (newest first)
        tourNotifications.sort((a, b) {
          DateTime timeA = a['notificationTime'] is Timestamp 
              ? (a['notificationTime'] as Timestamp).toDate()
              : a['notificationTime'] as DateTime;
          DateTime timeB = b['notificationTime'] is Timestamp 
              ? (b['notificationTime'] as Timestamp).toDate()
              : b['notificationTime'] as DateTime;
          return timeB.compareTo(timeA);
        });
        
        // Calculate total unread count
        int totalUnread = 0;
        for (var notification in tourNotifications) {
          if (!(notification['isRead'] ?? false)) {
            totalUnread++;
          }
        }
        
        setState(() {
          _tourNotifications = tourNotifications;
          _totalUnreadCount = totalUnread;
          _isLoading = false;
        });
        
        print('📊 Loaded ${tourNotifications.length} tour notifications');
        print('🔴 Total unread: $totalUnread');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Error loading notifications: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7fafc),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Tour Notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_totalUnreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _totalUnreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read, color: Colors.white),
            onPressed: _markAllAsRead,
            tooltip: 'Mark All as Read',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
            )
          : _tourNotifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Tour Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll receive notifications when tourists apply for your tours or when there are updates to your trips.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF667eea),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tourNotifications.length,
        itemBuilder: (context, index) {
          final notification = _tourNotifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] ?? false;
    final priority = notification['priority'] ?? 'normal';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isRead 
            ? null 
            : Border.all(color: const Color(0xFF667eea).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getNotificationColor(priority).withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            _getNotificationIcon(notification['notificationType']),
            color: _getNotificationColor(priority),
            size: 24,
          ),
        ),
        title: Text(
          notification['title'] ?? 'Tour Notification',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
            color: const Color(0xFF2d3748),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification['message'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _getTimeAgo(notification['notificationTime']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF667eea),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () => _markAsRead(notification),
      ),
    );
  }

  Color _getNotificationColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return const Color(0xFFF44336);
      case 'medium':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF667eea);
    }
  }

  IconData _getNotificationIcon(String? notificationType) {
    switch (notificationType) {
      case 'trip_application':
        return Icons.person_add;
      case 'trip_update':
        return Icons.update;
      case 'trip_reminder':
        return Icons.schedule;
      case 'trip_started':
        return Icons.play_arrow;
      case 'trip_completed':
        return Icons.check_circle;
      default:
        return Icons.tour;
    }
  }

  String _getTimeAgo(dynamic notificationTime) {
    if (notificationTime == null) return 'Just now';
    
    DateTime time;
    if (notificationTime is Timestamp) {
      time = notificationTime.toDate();
    } else if (notificationTime is DateTime) {
      time = notificationTime;
    } else {
      return 'Just now';
    }
    
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    try {
      // For now, just mark locally since we don't have a Firebase method
      // In a real app, you would update the notification in Firebase
      setState(() {
        notification['isRead'] = true;
        _totalUnreadCount = _calculateUnreadCount();
      });
      
      print('✅ Marked notification as read: ${notification['title']}');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking notification as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      // Mark all notifications as read locally
      for (var notification in _tourNotifications) {
        if (!(notification['isRead'] ?? false)) {
          notification['isRead'] = true;
        }
      }
      
      setState(() {
        _totalUnreadCount = 0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Color(0xFF48bb78),
        ),
      );
      
      print('✅ Marked all notifications as read');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking all notifications as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _calculateUnreadCount() {
    int count = 0;
    for (var notification in _tourNotifications) {
      if (!(notification['isRead'] ?? false)) {
        count++;
      }
    }
    return count;
  }
}