import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'services/firebase_service.dart';

class TestNotificationsPage extends StatefulWidget {
  const TestNotificationsPage({Key? key}) : super(key: key);

  @override
  State<TestNotificationsPage> createState() => _TestNotificationsPageState();
}

class _TestNotificationsPageState extends State<TestNotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseService _firebaseService = FirebaseService();
  
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Notification Features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3748),
              ),
            ),
            const SizedBox(height: 20),
            
            // Test Trip Reminder
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testTripReminder,
              icon: const Icon(Icons.schedule),
              label: const Text('Test Trip Reminder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            
            // Test New Application
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testNewApplication,
              icon: const Icon(Icons.tour),
              label: const Text('Test New Application'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            
            // Test Application Status
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testApplicationStatus,
              icon: const Icon(Icons.check_circle),
              label: const Text('Test Application Accepted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            
            // Test New Review
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testNewReview,
              icon: const Icon(Icons.star),
              label: const Text('Test New Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            
            // Test Payment Notification
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testPaymentNotification,
              icon: const Icon(Icons.payment),
              label: const Text('Test Payment Processed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            
            // Check Notification Status
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkNotificationStatus,
              icon: const Icon(Icons.info),
              label: const Text('Check Notification Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testTripReminder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.showTripReminder(
        tripId: 'test_trip_001',
        tripTitle: 'Colombo City Tour',
        touristName: 'John Smith',
        startTime: DateTime.now().add(const Duration(minutes: 5)),
        reminderType: '2_hours',
      );

      _showSuccessMessage('Trip reminder notification sent!');
    } catch (e) {
      _showErrorMessage('Error sending trip reminder: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testNewApplication() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.showNewApplicationNotification(
        tripId: 'test_trip_002',
        tripTitle: 'Kandy Cultural Experience',
        touristName: 'Maria Garcia',
        applicationId: 'test_app_001',
      );

      _showSuccessMessage('New application notification sent!');
    } catch (e) {
      _showErrorMessage('Error sending application notification: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testApplicationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.showApplicationStatusNotification(
        tripId: 'test_trip_003',
        tripTitle: 'Galle Fort Exploration',
        status: 'accepted',
        applicationId: 'test_app_002',
      );

      _showSuccessMessage('Application status notification sent!');
    } catch (e) {
      _showErrorMessage('Error sending status notification: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testNewReview() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.showNewReviewNotification(
        tripId: 'test_trip_004',
        tripTitle: 'Sigiriya Rock Fortress',
        touristName: 'Sarah Johnson',
        rating: 5,
        reviewText: 'Amazing tour! The guide was very knowledgeable and friendly.',
      );

      _showSuccessMessage('New review notification sent!');
    } catch (e) {
      _showErrorMessage('Error sending review notification: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testPaymentNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.showPaymentNotification(
        tripId: 'test_trip_005',
        tripTitle: 'Ella Scenic Train Ride',
        amount: 'LKR 10,000',
        status: 'processed',
      );

      _showSuccessMessage('Payment notification sent!');
    } catch (e) {
      _showErrorMessage('Error sending payment notification: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkNotificationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool isEnabled = await _notificationService.areNotificationsEnabled();
      String? fcmToken = _notificationService.fcmToken;
      
      String message = 'Notifications: ${isEnabled ? "Enabled" : "Disabled"}\n';
      message += 'FCM Token: ${fcmToken ?? "Not available"}';
      
      _showInfoMessage(message);
    } catch (e) {
      _showErrorMessage('Error checking notification status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Status'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
