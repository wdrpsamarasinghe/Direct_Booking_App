import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final FirebaseStorage _storage;
  
  FirebaseService() {
    try {
      _storage = FirebaseStorage.instance;
      print('✅ Firebase Storage initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase Storage: $e');
      rethrow;
    }
  }

  // Authentication methods
  Future<UserCredential?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  // Complete signup method that creates user and stores data in Firestore
  Future<UserCredential?> signUpUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the user ID
      String userId = userCredential.user!.uid;

      // Prepare user data for Firestore
      Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileCompleted': false,
        'verificationStatus': 'pending', // Default verification status
      };

      // Store user data in Firestore
      await _firestore.collection('users').doc(userId).set(userData);

      return userCredential;
    } catch (e) {
      print('Error in signUpUser: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  User? getCurrentUser() => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Expose Firestore instance for direct access
  FirebaseFirestore get firestore => _firestore;

  // Admin Dashboard Data Method
  Future<Map<String, dynamic>> getAdminDashboardData() async {
    try {
      print('📊 Fetching admin dashboard data...');
      
      // Get user counts
      final QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      Map<String, int> userCounts = {
        'total': usersSnapshot.docs.length,
        'guides': 0,
        'tourists': 0,
        'admins': 0,
      };
      
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        final role = (userData['role'] ?? '').toString().toLowerCase();
        
        switch (role) {
          case 'guide':
            userCounts['guides'] = userCounts['guides']! + 1;
            break;
          case 'tourist':
            userCounts['tourists'] = userCounts['tourists']! + 1;
            break;
          case 'admin':
            userCounts['admins'] = userCounts['admins']! + 1;
            break;
        }
      }
      
      // Get trip counts
      final QuerySnapshot tripsSnapshot = await _firestore.collection('trips').get();
      Map<String, int> tripCounts = {
        'total': tripsSnapshot.docs.length,
        'active': 0,
        'started': 0,
        'completed': 0,
        'cancelled': 0,
      };
      
      for (var doc in tripsSnapshot.docs) {
        final tripData = doc.data() as Map<String, dynamic>;
        final status = (tripData['status'] ?? '').toString().toLowerCase();
        
        switch (status) {
          case 'active':
            tripCounts['active'] = tripCounts['active']! + 1;
            break;
          case 'started':
            tripCounts['started'] = tripCounts['started']! + 1;
            break;
          case 'completed':
            tripCounts['completed'] = tripCounts['completed']! + 1;
            break;
          case 'cancelled':
            tripCounts['cancelled'] = tripCounts['cancelled']! + 1;
            break;
        }
      }
      
      // Get application counts
      final QuerySnapshot applicationsSnapshot = await _firestore.collection('trip_applications').get();
      Map<String, int> applicationCounts = {
        'total': applicationsSnapshot.docs.length,
        'pending': 0,
        'accepted': 0,
        'rejected': 0,
        'completed': 0,
      };
      
      for (var doc in applicationsSnapshot.docs) {
        final appData = doc.data() as Map<String, dynamic>;
        final status = (appData['status'] ?? '').toString().toLowerCase();
        
        switch (status) {
          case 'pending':
            applicationCounts['pending'] = applicationCounts['pending']! + 1;
            break;
          case 'accepted':
            applicationCounts['accepted'] = applicationCounts['accepted']! + 1;
            break;
          case 'rejected':
            applicationCounts['rejected'] = applicationCounts['rejected']! + 1;
            break;
          case 'completed':
            applicationCounts['completed'] = applicationCounts['completed']! + 1;
            break;
        }
      }
      
      // Get recent users (last 5)
      List<Map<String, dynamic>> recentUsers = [];
      for (var doc in usersSnapshot.docs.take(5)) {
        final userData = doc.data() as Map<String, dynamic>;
        recentUsers.add({
          'id': doc.id,
          'name': userData['name'] ?? 'Unknown',
          'email': userData['email'] ?? 'No email',
          'role': userData['role'] ?? 'user',
          'createdAt': userData['createdAt'],
        });
      }
      
      // Get recent applications (last 5)
      List<Map<String, dynamic>> recentApplications = [];
      for (var doc in applicationsSnapshot.docs.take(5)) {
        final appData = doc.data() as Map<String, dynamic>;
        recentApplications.add({
          'id': doc.id,
          'guideName': appData['guideName'] ?? 'Unknown Guide',
          'tripTitle': appData['tripTitle'] ?? 'Unknown Trip',
          'status': appData['status'] ?? 'pending',
          'appliedAt': appData['appliedAt'],
        });
      }
      
      // Get recent trips (last 5)
      List<Map<String, dynamic>> recentTrips = [];
      for (var doc in tripsSnapshot.docs.take(5)) {
        final tripData = doc.data() as Map<String, dynamic>;
        recentTrips.add({
          'id': doc.id,
          'touristName': tripData['touristName'] ?? 'Unknown Tourist',
          'description': tripData['description'] ?? 'Unknown Trip',
          'status': tripData['status'] ?? 'active',
          'createdAt': tripData['createdAt'],
        });
      }
      
      print('✅ Admin dashboard data fetched successfully');
      print('📊 Users: ${userCounts['total']} total (${userCounts['guides']} guides, ${userCounts['tourists']} tourists, ${userCounts['admins']} admins)');
      print('📊 Trips: ${tripCounts['total']} total (${tripCounts['active']} active, ${tripCounts['started']} started, ${tripCounts['completed']} completed)');
      print('📊 Applications: ${applicationCounts['total']} total (${applicationCounts['pending']} pending, ${applicationCounts['accepted']} accepted)');
      
      return {
        'userCounts': userCounts,
        'tripCounts': tripCounts,
        'applicationCounts': applicationCounts,
        'recentUsers': recentUsers,
        'recentApplications': recentApplications,
        'recentTrips': recentTrips,
      };
    } catch (e) {
      print('❌ Error fetching admin dashboard data: $e');
      rethrow;
    }
  }

  // Firestore methods
  Future<void> addUserData(String userId, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(userId).set(userData);
  }

  Future<DocumentSnapshot> getUserData(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  /// Fetches guide profile data from users collection
  Future<Map<String, dynamic>?> getGuideProfileData(String guideId) async {
    try {
      final doc = await _firestore.collection('users').doc(guideId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error fetching guide profile data: $e');
      return null;
    }
  }

  /// Fetches ongoing trips for a guide (accepted applications)
  Future<List<Map<String, dynamic>>> getOngoingTripsForGuide(String guideId) async {
    try {
      // Get all accepted applications for this guide
      final QuerySnapshot snapshot = await _firestore
          .collection('trip_applications')
          .where('guideId', isEqualTo: guideId)
          .where('status', isEqualTo: 'accepted')
          .get();

      List<Map<String, dynamic>> ongoingTrips = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> applicationData = doc.data() as Map<String, dynamic>;
        applicationData['id'] = doc.id;
        
        // Convert Firestore Timestamps to DateTime
        if (applicationData['appliedAt'] != null) {
          applicationData['appliedAt'] = (applicationData['appliedAt'] as Timestamp).toDate();
        }
        if (applicationData['updatedAt'] != null) {
          applicationData['updatedAt'] = (applicationData['updatedAt'] as Timestamp).toDate();
        }
        if (applicationData['availableFrom'] != null) {
          applicationData['availableFrom'] = (applicationData['availableFrom'] as Timestamp).toDate();
        }
        if (applicationData['availableTo'] != null) {
          applicationData['availableTo'] = (applicationData['availableTo'] as Timestamp).toDate();
        }
        if (applicationData['tripStartDate'] != null) {
          applicationData['tripStartDate'] = (applicationData['tripStartDate'] as Timestamp).toDate();
        }
        if (applicationData['tripEndDate'] != null) {
          applicationData['tripEndDate'] = (applicationData['tripEndDate'] as Timestamp).toDate();
        }

        // Fetch the trip details from trips collection
        final tripId = applicationData['tripId'];
        if (tripId != null) {
          final tripDoc = await _firestore.collection('trips').doc(tripId).get();
          if (tripDoc.exists) {
            Map<String, dynamic> tripData = tripDoc.data() as Map<String, dynamic>;
            tripData['id'] = tripDoc.id;
            
            // Convert trip timestamps
            if (tripData['startDate'] != null) {
              tripData['startDate'] = (tripData['startDate'] as Timestamp).toDate();
            }
            if (tripData['endDate'] != null) {
              tripData['endDate'] = (tripData['endDate'] as Timestamp).toDate();
            }
            if (tripData['createdAt'] != null) {
              tripData['createdAt'] = (tripData['createdAt'] as Timestamp).toDate();
            }

            // Combine application and trip data
            Map<String, dynamic> combinedData = {
              ...tripData,
              ...applicationData,
              'applicationId': doc.id,
            };
            
            ongoingTrips.add(combinedData);
          }
        }
      }
      
      print('Found ${ongoingTrips.length} ongoing trips for guide $guideId');
      return ongoingTrips;
    } catch (e) {
      print('Error fetching ongoing trips for guide: $e');
      return [];
    }
  }

  /// Fetches trips created by a tourist
  Future<List<Map<String, dynamic>>> getTripsByTourist(String touristId) async {
    try {
      // Get all trips created by this tourist
      final QuerySnapshot snapshot = await _firestore
          .collection('trips')
          .where('touristId', isEqualTo: touristId)
          .get();

      List<Map<String, dynamic>> trips = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> tripData = doc.data() as Map<String, dynamic>;
        tripData['id'] = doc.id;
        
        // Convert Firestore Timestamps to DateTime
        if (tripData['startDate'] != null) {
          tripData['startDate'] = (tripData['startDate'] as Timestamp).toDate();
        }
        if (tripData['endDate'] != null) {
          tripData['endDate'] = (tripData['endDate'] as Timestamp).toDate();
        }
        if (tripData['createdAt'] != null) {
          tripData['createdAt'] = (tripData['createdAt'] as Timestamp).toDate();
        }

        trips.add(tripData);
      }
      
      print('Found ${trips.length} trips for tourist $touristId');
      return trips;
    } catch (e) {
      print('Error fetching trips for tourist: $e');
      return [];
    }
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(userId).update(userData);
  }

  // Method to update user role (useful for creating admin users)
  Future<void> updateUserRole(String userId, String newRole) async {
    await _firestore.collection('users').doc(userId).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Storage methods
  Future<String> uploadFile(String path, Uint8List fileBytes) async {
    try {
      print('📤 Uploading file to path: $path');
      print('📤 File size: ${fileBytes.length} bytes');
      
      final ref = _storage.ref().child(path);
      print('📤 Storage reference created: ${ref.fullPath}');
      
      final uploadTask = await ref.putData(fileBytes);
      print('📤 Upload task completed: ${uploadTask.state}');
      
      final downloadUrl = await ref.getDownloadURL();
      print('✅ File uploaded successfully, URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading file: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error details: ${e.toString()}');
      print('❌ Path: $path');
      print('❌ File size: ${fileBytes.length} bytes');
      rethrow;
    }
  }

  // Profile management methods
  Future<void> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...profileData,
        'updatedAt': FieldValue.serverTimestamp(),
        'profileCompleted': true,
      });
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<String> uploadProfileImage(String userId, Uint8List imageBytes) async {
    try {
      final String fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'profile_images/$fileName';
      print('📸 Uploading profile image: $fileName');
      print('📸 Image size: ${imageBytes.length} bytes');
      return await uploadFile(path, imageBytes);
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      rethrow;
    }
  }

  // User verification methods
  Future<void> approveUserVerification(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verificationStatus': 'verified',
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error approving user verification: $e');
      rethrow;
    }
  }

  Future<void> rejectUserVerification(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verificationStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error rejecting user verification: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingVerificationUsers() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('verificationStatus', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> users = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id;
        users.add(userData);
      }
      
      return users;
    } catch (e) {
      print('Error fetching pending verification users: $e');
      return [];
    }
  }

  Future<String> uploadDocument(String userId, String documentType, Uint8List imageBytes) async {
    try {
      // Use conservative naming to avoid Firebase Storage issues
      String sanitizedType;
      String directoryName;
      
      switch (documentType) {
        case 'nic':
          sanitizedType = 'nic';
          directoryName = 'nic_documents';
          break;
        case 'driving_licence':
          sanitizedType = 'driving';
          directoryName = 'driving_documents';
          break;
        case 'police_report':
          sanitizedType = 'police';
          directoryName = 'police_documents';
          break;
        default:
          sanitizedType = documentType.replaceAll('_', '');
          directoryName = '${sanitizedType}_documents';
      }
      
      final String fileName = '${sanitizedType}_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = '$directoryName/$fileName';
      
      print('📄 Uploading $documentType document: $fileName');
      print('📄 Document size: ${imageBytes.length} bytes');
      print('📄 Sanitized type: $sanitizedType');
      print('📄 Directory: $directoryName');
      print('📄 Full path: $path');
      
      // Test storage connectivity first
      final connectivityTest = await testStorageConnectivity();
      if (!connectivityTest) {
        throw Exception('Firebase Storage connectivity test failed');
      }
      
      return await uploadFile(path, imageBytes);
    } catch (e) {
      print('❌ Error uploading $documentType document: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error details: ${e.toString()}');
      
      // Try fallback approach with simpler naming
      if (e.toString().contains('_Namespace') || e.toString().contains('Unsupported operation')) {
        print('🔄 Trying fallback approach with simpler naming...');
        try {
          final String fallbackFileName = 'doc_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final String fallbackPath = 'documents/$fallbackFileName';
          print('📄 Fallback path: $fallbackPath');
          return await uploadFile(fallbackPath, imageBytes);
        } catch (fallbackError) {
          print('❌ Fallback approach also failed: $fallbackError');
          rethrow;
        }
      }
      
      rethrow;
    }
  }

  Future<bool> testStorageConnectivity() async {
    try {
      print('🔍 Testing Firebase Storage connectivity...');
      print('🔍 Storage instance: $_storage');
      print('🔍 Storage app: ${_storage.app.name}');
      
      final ref = _storage.ref().child('test_connectivity.txt');
      print('🔍 Test reference created: ${ref.fullPath}');
      
      await ref.putString('test');
      print('🔍 Test file uploaded successfully');
      
      await ref.delete();
      print('🔍 Test file deleted successfully');
      
      print('✅ Firebase Storage connectivity test passed');
      return true;
    } catch (e) {
      print('❌ Firebase Storage connectivity test failed: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error details: ${e.toString()}');
      return false;
    }
  }

  Future<bool> testImageUrl(String imageUrl) async {
    try {
      print('🔍 Testing image URL: $imageUrl');
      
      // Add headers to handle CORS and other potential issues
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'Accept': 'image/*',
          'User-Agent': 'Flutter App',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        print('✅ Image URL is accessible');
        return true;
      } else {
        print('❌ Image URL returned status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Image URL test failed: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      // Check if it's a specific network error
      if (e.toString().contains('ClientException')) {
        print('🌐 This appears to be a network connectivity issue');
        print('💡 Possible causes:');
        print('   - Network connectivity problems');
        print('   - CORS policy restrictions');
        print('   - Firebase Storage rules blocking access');
        print('   - Firewall or proxy blocking the request');
      }
      
      return false;
    }
  }

  Future<String?> getDirectDownloadUrl(String filePath) async {
    try {
      print('📁 Getting direct download URL for path: $filePath');
      final ref = _storage.ref().child(filePath);
      final downloadUrl = await ref.getDownloadURL();
      print('✅ Direct download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error getting direct download URL: $e');
      return null;
    }
  }

  Reference getStorageRef() {
    return _storage.ref();
  }

  Future<String?> getSignedDownloadUrl(String filePath) async {
    try {
      print('📁 Getting signed download URL for path: $filePath');
      final ref = _storage.ref().child(filePath);
      
      // Try to get a signed URL that might bypass CORS
      final downloadUrl = await ref.getDownloadURL();
      
      // Add a timestamp to make it unique and potentially bypass cache
      final signedUrl = '$downloadUrl&t=${DateTime.now().millisecondsSinceEpoch}';
      print('✅ Signed download URL: $signedUrl');
      return signedUrl;
    } catch (e) {
      print('❌ Error getting signed download URL: $e');
      return null;
    }
  }

  Future<String?> getDocumentDownloadUrl(String documentUrl) async {
    try {
      print('📄 Getting document download URL: $documentUrl');
      
      // If it's already a Firebase Storage URL, try to get a fresh signed URL
      if (documentUrl.contains('firebasestorage.googleapis.com')) {
        // Extract the file path from the URL
        final uri = Uri.parse(documentUrl);
        final pathSegments = uri.pathSegments;
        
        if (pathSegments.length >= 3) {
          // Firebase Storage URL format: /v0/b/{bucket}/o/{path}?{params}
          final bucketIndex = pathSegments.indexOf('b') + 1;
          final objectIndex = pathSegments.indexOf('o') + 1;
          
          if (bucketIndex < pathSegments.length && objectIndex < pathSegments.length) {
            final bucket = pathSegments[bucketIndex];
            final encodedPath = pathSegments[objectIndex];
            final decodedPath = Uri.decodeComponent(encodedPath);
            
            print('📄 Extracted path: $decodedPath');
            
            // Get a fresh download URL
            final ref = _storage.ref().child(decodedPath);
            final freshUrl = await ref.getDownloadURL();
            
            // Add timestamp to bypass cache
            final signedUrl = '$freshUrl&t=${DateTime.now().millisecondsSinceEpoch}';
            print('✅ Fresh document URL: $signedUrl');
            return signedUrl;
          }
        }
      }
      
      // If we can't extract the path or it's not a Firebase URL, return the original URL with timestamp
      final signedUrl = '$documentUrl&t=${DateTime.now().millisecondsSinceEpoch}';
      print('✅ Document URL with timestamp: $signedUrl');
      return signedUrl;
    } catch (e) {
      print('❌ Error getting document download URL: $e');
      return documentUrl; // Return original URL as fallback
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  // Tour Guides methods
  Future<List<Map<String, dynamic>>> getTourGuides() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Tour Guide')
          .where('isActive', isEqualTo: true)
          .where('profileCompleted', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> tourGuides = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> guideData = doc.data() as Map<String, dynamic>;
        guideData['id'] = doc.id; // Add document ID
        tourGuides.add(guideData);
      }
      
      return tourGuides;
    } catch (e) {
      print('Error getting tour guides: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTourGuidesByLocation(String location) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Tour Guide')
          .where('isActive', isEqualTo: true)
          .where('profileCompleted', isEqualTo: true)
          .where('location', isEqualTo: location)
          .get();

      List<Map<String, dynamic>> tourGuides = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> guideData = doc.data() as Map<String, dynamic>;
        guideData['id'] = doc.id;
        tourGuides.add(guideData);
      }
      
      return tourGuides;
    } catch (e) {
      print('Error getting tour guides by location: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchTourGuides(String query) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Tour Guide')
          .where('isActive', isEqualTo: true)
          .where('profileCompleted', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> tourGuides = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> guideData = doc.data() as Map<String, dynamic>;
        guideData['id'] = doc.id;
        
        // Check if the query matches name, location, or specialties
        String name = guideData['name']?.toString().toLowerCase() ?? '';
        String location = guideData['location']?.toString().toLowerCase() ?? '';
        List<dynamic> specialties = guideData['specialties'] ?? [];
        
        if (name.contains(query.toLowerCase()) ||
            location.contains(query.toLowerCase()) ||
            specialties.any((specialty) => 
                specialty.toString().toLowerCase().contains(query.toLowerCase()))) {
          tourGuides.add(guideData);
        }
      }
      
      return tourGuides;
    } catch (e) {
      print('Error searching tour guides: $e');
      rethrow;
    }
  }

  // Trip publishing methods
  Future<void> publishTrip(Map<String, dynamic> tripData) async {
    try {
      await _firestore.collection('trips').add({
        ...tripData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Don't override status and touristId if they're already set
        'status': tripData['status'] ?? 'active',
        'touristId': tripData['touristId'] ?? _auth.currentUser?.uid,
      });
    } catch (e) {
      print('Error publishing trip: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPublishedTrips() async {
    const int maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        print('🔄 [FIREBASE_SERVICE] Attempting to get published trips (attempt ${retryCount + 1}/$maxRetries)');
        
        // Check if user is authenticated
        if (_auth.currentUser?.uid == null) {
          print('❌ [FIREBASE_SERVICE] No authenticated user found');
          throw Exception('User not authenticated');
        }
        
        print('👤 [FIREBASE_SERVICE] Current user ID: ${_auth.currentUser!.uid}');
        
        // Try to get trips with a timeout
        final QuerySnapshot snapshot = await _firestore
            .collection('trips')
            .where('touristId', isEqualTo: _auth.currentUser!.uid)
            .get()
            .timeout(const Duration(seconds: 30));

        print('✅ [FIREBASE_SERVICE] Successfully fetched ${snapshot.docs.length} documents from trips collection');

        List<Map<String, dynamic>> trips = [];
        
        for (var doc in snapshot.docs) {
          try {
            Map<String, dynamic> tripData = doc.data() as Map<String, dynamic>;
            tripData['id'] = doc.id;
            
            // Skip cancelled trips
            if (tripData['status'] == 'cancelled') {
              continue;
            }
            
            // Safely convert Firestore Timestamps to DateTime
            if (tripData['createdAt'] != null) {
              try {
                tripData['createdAt'] = (tripData['createdAt'] as Timestamp).toDate();
              } catch (e) {
                print('⚠️ [FIREBASE_SERVICE] Error converting createdAt timestamp: $e');
                tripData['createdAt'] = DateTime.now();
              }
            }
            if (tripData['updatedAt'] != null) {
              try {
                tripData['updatedAt'] = (tripData['updatedAt'] as Timestamp).toDate();
              } catch (e) {
                print('⚠️ [FIREBASE_SERVICE] Error converting updatedAt timestamp: $e');
                tripData['updatedAt'] = DateTime.now();
              }
            }
            if (tripData['startDate'] != null) {
              try {
                tripData['startDate'] = (tripData['startDate'] as Timestamp).toDate();
              } catch (e) {
                print('⚠️ [FIREBASE_SERVICE] Error converting startDate timestamp: $e');
                tripData['startDate'] = DateTime.now().add(const Duration(days: 1));
              }
            }
            
            trips.add(tripData);
            print('✅ [FIREBASE_SERVICE] Successfully processed trip: ${tripData['id']}');
          } catch (e) {
            print('❌ [FIREBASE_SERVICE] Error processing document ${doc.id}: $e');
            // Continue processing other documents
            continue;
          }
        }
        
        // Sort manually by createdAt descending
        trips.sort((a, b) {
          DateTime? aDate = a['createdAt'] as DateTime?;
          DateTime? bDate = b['createdAt'] as DateTime?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
        
        print('🎯 [FIREBASE_SERVICE] Successfully processed ${trips.length} trips');
        return trips;
        
      } catch (e) {
        retryCount++;
        print('❌ [FIREBASE_SERVICE] Error getting published trips (attempt $retryCount/$maxRetries): $e');
        print('📊 [FIREBASE_SERVICE] Error type: ${e.runtimeType}');
        
        // Check if it's a specific Firestore error
        if (e.toString().contains('INTERNAL ASSERTION FAILED') || 
            e.toString().contains('FIRESTORE') ||
            e.toString().contains('Unexpected state')) {
          print('🔧 [FIREBASE_SERVICE] Detected Firestore internal error, attempting recovery...');
          
          if (retryCount < maxRetries) {
            // Wait before retrying
            await Future.delayed(Duration(seconds: retryCount * 2));
            continue;
          } else {
            // Try fallback approach
            return await _getPublishedTripsFallback();
          }
        } else {
          // For other errors, don't retry
          rethrow;
        }
      }
    }
    
    // This should never be reached, but just in case
    throw Exception('Failed to get published trips after $maxRetries attempts');
  }

  /// Fallback method to get published trips with simpler query
  Future<List<Map<String, dynamic>>> _getPublishedTripsFallback() async {
    try {
      print('🔄 [FIREBASE_SERVICE] Using fallback method to get published trips');
      
      // Get all trips and filter client-side
      final QuerySnapshot snapshot = await _firestore
          .collection('trips')
          .get()
          .timeout(const Duration(seconds: 20));

      List<Map<String, dynamic>> trips = [];
      
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> tripData = doc.data() as Map<String, dynamic>;
          tripData['id'] = doc.id;
          
          // Filter for current user's trips
          if (tripData['touristId'] != _auth.currentUser?.uid) {
            continue;
          }
          
          // Skip cancelled trips
          if (tripData['status'] == 'cancelled') {
            continue;
          }
          
          // Safely convert timestamps
          if (tripData['createdAt'] != null) {
            tripData['createdAt'] = (tripData['createdAt'] as Timestamp).toDate();
          }
          if (tripData['updatedAt'] != null) {
            tripData['updatedAt'] = (tripData['updatedAt'] as Timestamp).toDate();
          }
          if (tripData['startDate'] != null) {
            tripData['startDate'] = (tripData['startDate'] as Timestamp).toDate();
          }
          
          trips.add(tripData);
        } catch (e) {
          print('❌ [FIREBASE_SERVICE] Error processing document in fallback: $e');
          continue;
        }
      }
      
      // Sort manually
      trips.sort((a, b) {
        DateTime? aDate = a['createdAt'] as DateTime?;
        DateTime? bDate = b['createdAt'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      
      print('✅ [FIREBASE_SERVICE] Fallback method successful, found ${trips.length} trips');
      return trips;
      
    } catch (e) {
      print('❌ [FIREBASE_SERVICE] Fallback method also failed: $e');
      // Return empty list as last resort
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllAvailableTrips() async {
    try {
      print('=== STARTING getAllAvailableTrips ===');
      print('Current user: ${_auth.currentUser?.uid}');
      
      // Get ALL trips from the trips collection
      QuerySnapshot snapshot = await _firestore.collection('trips').get();
      print('✅ Query successful! Found ${snapshot.docs.length} documents in trips collection');

      List<Map<String, dynamic>> trips = [];
      
      print('📋 Processing ${snapshot.docs.length} documents...');
      
      for (var doc in snapshot.docs) {
        print('--- Processing Document: ${doc.id} ---');
        Map<String, dynamic> tripData = doc.data() as Map<String, dynamic>;
        tripData['id'] = doc.id;
        
        // Print all fields for debugging
        print('📄 Document fields:');
        tripData.forEach((key, value) {
          print('  $key: $value (${value.runtimeType})');
        });
        
        // Convert Firestore Timestamps to DateTime
        if (tripData['createdAt'] != null) {
          tripData['createdAt'] = (tripData['createdAt'] as Timestamp).toDate();
          print('✅ Converted createdAt timestamp');
        }
        if (tripData['updatedAt'] != null) {
          tripData['updatedAt'] = (tripData['updatedAt'] as Timestamp).toDate();
          print('✅ Converted updatedAt timestamp');
        }
        if (tripData['startDate'] != null) {
          tripData['startDate'] = (tripData['startDate'] as Timestamp).toDate();
          print('✅ Converted startDate timestamp');
        }
        
        trips.add(tripData);
        print('✅ ADDED trip ${doc.id} to results');
        print('--- End Document: ${doc.id} ---\n');
      }
      
      // Filter out trips that the current guide has already applied for
      if (_auth.currentUser != null) {
        print('🔍 Filtering out trips already applied by guide: ${_auth.currentUser!.uid}');
        
        // Get all applications by this guide
        List<Map<String, dynamic>> appliedTrips = await getTripApplicationsByGuide(_auth.currentUser!.uid);
        Set<String> appliedTripIds = appliedTrips.map((app) => app['tripId'] as String).toSet();
        
        print('📝 Found ${appliedTripIds.length} applied trip IDs: $appliedTripIds');
        
        // Filter out applied trips
        List<Map<String, dynamic>> availableTrips = trips.where((trip) {
          String tripId = trip['id'] as String;
          bool isApplied = appliedTripIds.contains(tripId);
          print('  Trip ${tripId}: ${isApplied ? "❌ ALREADY APPLIED" : "✅ AVAILABLE"}');
          return !isApplied;
        }).toList();
        
        print('🎯 FINAL RESULT: Found ${availableTrips.length} available trips (filtered out ${trips.length - availableTrips.length} already applied)');
        print('=== END getAllAvailableTrips ===\n');
        return availableTrips;
      } else {
        print('🎯 FINAL RESULT: Found ${trips.length} trips (no user logged in, no filtering)');
        print('=== END getAllAvailableTrips ===\n');
        return trips;
      }
    } catch (e) {
      print('💥 ERROR in getAllAvailableTrips: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Debug method to get all trips without any filters
  Future<List<Map<String, dynamic>>> getAllTripsDebug() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('trips').get();
      
      List<Map<String, dynamic>> trips = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> tripData = doc.data() as Map<String, dynamic>;
        tripData['id'] = doc.id;
        
        // Convert Firestore Timestamps to DateTime
        if (tripData['createdAt'] != null) {
          tripData['createdAt'] = (tripData['createdAt'] as Timestamp).toDate();
        }
        if (tripData['updatedAt'] != null) {
          tripData['updatedAt'] = (tripData['updatedAt'] as Timestamp).toDate();
        }
        if (tripData['startDate'] != null) {
          tripData['startDate'] = (tripData['startDate'] as Timestamp).toDate();
        }
        
        trips.add(tripData);
        print('Debug - Trip ${doc.id}: $tripData');
      }
      
      print('Debug - Found ${trips.length} total trips in database');
      return trips;
    } catch (e) {
      print('Error getting all trips (debug): $e');
      rethrow;
    }
  }

  // Trip Application methods
  Future<void> submitTripApplication(Map<String, dynamic> applicationData) async {
    try {
      await _firestore.collection('trip_applications').add(applicationData);
      print('Trip application submitted successfully');
    } catch (e) {
      print('Error submitting trip application: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTripApplicationsByGuide(String guideId) async {
    try {
      // Get all applications for this guide without ordering to avoid index requirement
      final QuerySnapshot snapshot = await _firestore
          .collection('trip_applications')
          .where('guideId', isEqualTo: guideId)
          .get();

      List<Map<String, dynamic>> applications = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> applicationData = doc.data() as Map<String, dynamic>;
        applicationData['id'] = doc.id;
        
        // Convert Firestore Timestamps to DateTime
        if (applicationData['appliedAt'] != null) {
          applicationData['appliedAt'] = (applicationData['appliedAt'] as Timestamp).toDate();
        }
        if (applicationData['updatedAt'] != null) {
          applicationData['updatedAt'] = (applicationData['updatedAt'] as Timestamp).toDate();
        }
        if (applicationData['availableFrom'] != null) {
          applicationData['availableFrom'] = (applicationData['availableFrom'] as Timestamp).toDate();
        }
        if (applicationData['availableTo'] != null) {
          applicationData['availableTo'] = (applicationData['availableTo'] as Timestamp).toDate();
        }
        if (applicationData['tripStartDate'] != null) {
          applicationData['tripStartDate'] = (applicationData['tripStartDate'] as Timestamp).toDate();
        }
        if (applicationData['tripEndDate'] != null) {
          applicationData['tripEndDate'] = (applicationData['tripEndDate'] as Timestamp).toDate();
        }
        
        applications.add(applicationData);
      }
      
      // Sort manually by appliedAt descending
      applications.sort((a, b) {
        DateTime? aDate = a['appliedAt'] as DateTime?;
        DateTime? bDate = b['appliedAt'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      
      return applications;
    } catch (e) {
      print('Error getting trip applications by guide: $e');
      rethrow;
    }
  }

  /// Get guide ongoing trips (trips with 'started' status from trips collection)
  Future<List<Map<String, dynamic>>> getGuideOngoingTrips(String guideId) async {
    try {
      print('🔍 Getting ongoing trips for guide: $guideId');
      
      // First, get all applications for this guide to find which trips they're involved in
      List<Map<String, dynamic>> applications = await getTripApplicationsByGuide(guideId);
      print('📊 Found ${applications.length} applications for guide');
      
      // Extract trip IDs where guide has applications
      Set<String> guideTripIds = applications.map((app) => app['tripId'] as String).toSet();
      print('🎯 Guide is involved in ${guideTripIds.length} trips');
      
      List<Map<String, dynamic>> ongoingTrips = [];
      
      // Query trips collection for trips with 'started' status that this guide is involved in
      QuerySnapshot tripsSnapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'started')
          .get();
          
      print('🔍 Found ${tripsSnapshot.docs.length} trips with "started" status');
      
      for (var tripDoc in tripsSnapshot.docs) {
        String tripId = tripDoc.id;
        
        // Only include trips where this guide has an application
        if (!guideTripIds.contains(tripId)) {
          print('⏭️ Skipping trip $tripId - guide not involved');
          continue;
        }
        
        print('✅ Processing started trip: $tripId');
        
        try {
          Map<String, dynamic> tripData = tripDoc.data() as Map<String, dynamic>;
          tripData['id'] = tripDoc.id;
          
          // Convert trip timestamps
          if (tripData['startDate'] != null) {
            tripData['startDate'] = (tripData['startDate'] as Timestamp).toDate();
          }
          if (tripData['endDate'] != null) {
            tripData['endDate'] = (tripData['endDate'] as Timestamp).toDate();
          }
          if (tripData['createdAt'] != null) {
            tripData['createdAt'] = (tripData['createdAt'] as Timestamp).toDate();
          }
          
          // Find the guide's application for this trip
          Map<String, dynamic>? guideApplication;
          for (var app in applications) {
            if (app['tripId'] == tripId) {
              guideApplication = app;
              break;
            }
          }
          
          if (guideApplication == null) {
            print('⚠️ No application found for guide in trip $tripId');
            continue;
          }
          
          // Get tourist name directly from trip document
          String touristName = tripData['touristName'] ?? 'Unknown Tourist';
          print('👤 Tourist name from trip document: $touristName');
          
          // Combine trip, application, and tourist data
          Map<String, dynamic> combinedTrip = {
            ...tripData,
            'applicationId': guideApplication['id'],
            'status': tripData['status'], // Use trip status ('started')
            'appliedAt': guideApplication['appliedAt'],
            'requestMessage': guideApplication['requestMessage'],
            'touristName': touristName, // Use touristName from trips collection
            'touristId': guideApplication['touristId'], // Keep touristId for reference
          };
          
          ongoingTrips.add(combinedTrip);
          print('✅ Added started trip: ${tripData['title']} (ID: $tripId)');
          
        } catch (e) {
          print('❌ Error processing trip $tripId: $e');
          continue;
        }
      }
      
      // Sort by start date (most recent first)
      ongoingTrips.sort((a, b) {
        DateTime? aDate = a['startDate'] as DateTime?;
        DateTime? bDate = b['startDate'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      
      print('🎯 Total ongoing trips for guide: ${ongoingTrips.length}');
      
      // Debug: Log each ongoing trip
      for (int i = 0; i < ongoingTrips.length; i++) {
        final trip = ongoingTrips[i];
        print('📋 Ongoing Trip ${i + 1}: ID=${trip['id']}, Status=${trip['status']}, Title=${trip['title']}');
      }
      
      return ongoingTrips;
      
    } catch (e) {
      print('Error getting guide ongoing trips: $e');
      rethrow;
    }
  }

  /// Get guide completed trips (trips with 'completed' status from trips collection)
  Future<List<Map<String, dynamic>>> getGuideCompletedTrips(String guideId) async {
    try {
      print('🔍 Getting completed trips for guide: $guideId');
      
      // First, get all applications for this guide to find which trips they're involved in
      List<Map<String, dynamic>> applications = await getTripApplicationsByGuide(guideId);
      print('📊 Found ${applications.length} applications for guide');
      
      // Extract trip IDs where guide has applications
      Set<String> guideTripIds = applications.map((app) => app['tripId'] as String).toSet();
      print('🎯 Guide is involved in ${guideTripIds.length} trips');
      
      List<Map<String, dynamic>> completedTrips = [];
      
      // Query trips collection for trips with 'completed' status that this guide is involved in
      QuerySnapshot tripsSnapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'completed')
          .get();
          
      print('🔍 Found ${tripsSnapshot.docs.length} trips with "completed" status');
      
      for (var tripDoc in tripsSnapshot.docs) {
        String tripId = tripDoc.id;
        
        // Only include trips where this guide has an application
        if (!guideTripIds.contains(tripId)) {
          print('⏭️ Skipping trip $tripId - guide not involved');
          continue;
        }
        
        print('✅ Processing completed trip: $tripId');
        
        try {
          Map<String, dynamic> tripData = tripDoc.data() as Map<String, dynamic>;
          tripData['id'] = tripDoc.id;
          
          // Convert trip timestamps
          if (tripData['startDate'] != null) {
            tripData['startDate'] = (tripData['startDate'] as Timestamp).toDate();
          }
          if (tripData['endDate'] != null) {
            tripData['endDate'] = (tripData['endDate'] as Timestamp).toDate();
          }
          if (tripData['createdAt'] != null) {
            tripData['createdAt'] = (tripData['createdAt'] as Timestamp).toDate();
          }
          
          // Find the guide's application for this trip
          Map<String, dynamic>? guideApplication;
          for (var app in applications) {
            if (app['tripId'] == tripId) {
              guideApplication = app;
              break;
            }
          }
          
          if (guideApplication == null) {
            print('⚠️ No application found for guide in trip $tripId');
            continue;
          }
          
          // Get tourist name directly from trip document
          String touristName = tripData['touristName'] ?? 'Unknown Tourist';
          print('👤 Tourist name from trip document: $touristName');
          
          // Combine trip, application, and tourist data
          Map<String, dynamic> combinedTrip = {
            ...tripData,
            'applicationId': guideApplication['id'],
            'status': tripData['status'], // Use trip status ('completed')
            'appliedAt': guideApplication['appliedAt'],
            'requestMessage': guideApplication['requestMessage'],
            'touristName': touristName, // Use touristName from trips collection
            'touristId': guideApplication['touristId'], // Keep touristId for reference
          };
          
          completedTrips.add(combinedTrip);
          print('✅ Added completed trip: ${tripData['title']} (ID: $tripId)');
          
        } catch (e) {
          print('❌ Error processing trip $tripId: $e');
          continue;
        }
      }
      
      // Sort by end date (most recent first)
      completedTrips.sort((a, b) {
        DateTime? aDate = a['endDate'] as DateTime?;
        DateTime? bDate = b['endDate'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      
      print('🎯 Total completed trips for guide: ${completedTrips.length}');
      
      // Debug: Log each completed trip
      for (int i = 0; i < completedTrips.length; i++) {
        final trip = completedTrips[i];
        print('📋 Completed Trip ${i + 1}: ID=${trip['id']}, Status=${trip['status']}, Title=${trip['title']}');
      }
      
      return completedTrips;
      
    } catch (e) {
      print('Error getting guide completed trips: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTripApplicationsByTrip(String tripId) async {
    try {
      // Get all applications for this trip without ordering to avoid index requirement
      final QuerySnapshot snapshot = await _firestore
          .collection('trip_applications')
          .where('tripId', isEqualTo: tripId)
          .get();

      List<Map<String, dynamic>> applications = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> applicationData = doc.data() as Map<String, dynamic>;
        applicationData['id'] = doc.id;
        
        // Convert Firestore Timestamps to DateTime
        if (applicationData['appliedAt'] != null) {
          applicationData['appliedAt'] = (applicationData['appliedAt'] as Timestamp).toDate();
        }
        if (applicationData['updatedAt'] != null) {
          applicationData['updatedAt'] = (applicationData['updatedAt'] as Timestamp).toDate();
        }
        if (applicationData['availableFrom'] != null) {
          applicationData['availableFrom'] = (applicationData['availableFrom'] as Timestamp).toDate();
        }
        if (applicationData['availableTo'] != null) {
          applicationData['availableTo'] = (applicationData['availableTo'] as Timestamp).toDate();
        }
        if (applicationData['tripStartDate'] != null) {
          applicationData['tripStartDate'] = (applicationData['tripStartDate'] as Timestamp).toDate();
        }
        if (applicationData['tripEndDate'] != null) {
          applicationData['tripEndDate'] = (applicationData['tripEndDate'] as Timestamp).toDate();
        }
        
        // Fetch guide verification status
        try {
          DocumentSnapshot guideDoc = await _firestore.collection('users').doc(applicationData['guideId']).get();
          if (guideDoc.exists) {
            Map<String, dynamic> guideData = guideDoc.data() as Map<String, dynamic>;
            applicationData['guideVerificationStatus'] = guideData['verificationStatus'] ?? 'pending';
          } else {
            applicationData['guideVerificationStatus'] = 'pending';
          }
        } catch (e) {
          print('Error fetching guide verification status: $e');
          applicationData['guideVerificationStatus'] = 'pending';
        }
        
        applications.add(applicationData);
      }
      
      // Sort manually by appliedAt descending
      applications.sort((a, b) {
        DateTime? aDate = a['appliedAt'] as DateTime?;
        DateTime? bDate = b['appliedAt'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      
      return applications;
    } catch (e) {
      print('Error getting trip applications by trip: $e');
      rethrow;
    }
  }

  Future<void> updateApplicationStatus(String applicationId, String status, [String? reason]) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (reason != null) {
        updateData['rejectionReason'] = reason;
      }
      
      await _firestore.collection('trip_applications').doc(applicationId).update(updateData);
      print('Application status updated to: $status');
    } catch (e) {
      print('Error updating application status: $e');
      rethrow;
    }
  }

  /// Accept one guide and automatically reject all other pending applications for the same trip
  Future<void> acceptGuideAndRejectOthers(String acceptedApplicationId, String tripId) async {
    try {
      print('🎯 Accepting guide and rejecting others for trip: $tripId');
      
      // Get all applications for this trip
      List<Map<String, dynamic>> allApplications = await getTripApplicationsByTrip(tripId);
      print('Found ${allApplications.length} total applications for trip');
      
      // Find the accepted application
      Map<String, dynamic>? acceptedApplication;
      for (var app in allApplications) {
        if (app['id'] == acceptedApplicationId) {
          acceptedApplication = app;
          break;
        }
      }
      
      if (acceptedApplication == null) {
        throw Exception('Accepted application not found');
      }
      
      // Accept the selected guide
      await updateApplicationStatus(acceptedApplicationId, 'accepted');
      print('✅ Accepted guide: ${acceptedApplication['guideName'] ?? 'Unknown'}');
      
      // Reject all other pending applications
      int rejectedCount = 0;
      for (var app in allApplications) {
        if (app['id'] != acceptedApplicationId && 
            (app['status']?.toLowerCase() == 'pending' || app['status']?.toLowerCase() == 'applied')) {
          await updateApplicationStatus(
            app['id'], 
            'rejected', 
            'Another guide was selected for this trip'
          );
          rejectedCount++;
          print('❌ Rejected guide: ${app['guideName'] ?? 'Unknown'}');
        }
      }
      
      print('🎉 Successfully accepted 1 guide and rejected $rejectedCount others');
      
      // Update trip status to show it has an accepted guide
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'accepted',
        'acceptedGuideId': acceptedApplication['guideId'],
        'acceptedGuideName': acceptedApplication['guideName'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('📝 Updated trip status to accepted');
      
    } catch (e) {
      print('Error in acceptGuideAndRejectOthers: $e');
      rethrow;
    }
  }

  /// Accepts one applicant and automatically rejects all other pending applicants for the same trip
  Future<int> acceptApplicantAndRejectOthers(String acceptedApplicationId, String tripId) async {
    try {
      // Get all applications for this trip
      List<Map<String, dynamic>> allApplications = await getTripApplicationsByTrip(tripId);
      
      // Filter to get only pending applications (excluding the accepted one)
      List<Map<String, dynamic>> pendingApplications = allApplications
          .where((app) => app['status'] == 'pending' && app['id'] != acceptedApplicationId)
          .toList();
      
      int rejectedCount = 0;
      
      // Reject all pending applications
      for (var application in pendingApplications) {
        try {
          await updateApplicationStatus(
            application['id'], 
            'rejected', 
            'Another guide was selected for this trip'
          );
          rejectedCount++;
        } catch (e) {
          print('Error rejecting application ${application['id']}: $e');
        }
      }
      
      // Accept the selected application
      await updateApplicationStatus(acceptedApplicationId, 'accepted');
      
      print('Accepted application $acceptedApplicationId and rejected $rejectedCount other applications');
      return rejectedCount;
    } catch (e) {
      print('Error in acceptApplicantAndRejectOthers: $e');
      rethrow;
    }
  }

  Future<void> deleteTripApplication(String applicationId) async {
    try {
      await _firestore.collection('trip_applications').doc(applicationId).delete();
      print('Trip application deleted successfully');
    } catch (e) {
      print('Error deleting trip application: $e');
      rethrow;
    }
  }

  Future<void> updateTripStatus(String tripId, String status, [String? reason]) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (reason != null) {
        updateData['cancellationReason'] = reason;
      }
      
      await _firestore.collection('trips').doc(tripId).update(updateData);
      print('Trip status updated successfully');
    } catch (e) {
      print('Error updating trip status: $e');
      rethrow;
    }
  }

  /// Start a trip - updates both trip and application status to "started"
  Future<void> startTrip(String tripId, String applicationId) async {
    try {
      // Get current date
      DateTime currentDate = DateTime.now();
      Timestamp startDate = Timestamp.fromDate(currentDate);
      
      print('📅 Setting start date to: ${currentDate.toString()}');
      
      // Update trip status to "started" and set start date
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'started',
        'startDate': startDate,
        'updatedAt': Timestamp.now(),
      });
      
      // Update application status to "started"
      await updateApplicationStatus(applicationId, 'started');
      
      print('✅ Trip started successfully with start date: ${currentDate.toString()}');
    } catch (e) {
      print('❌ Error starting trip: $e');
      rethrow;
    }
  }

  /// Complete a trip - updates both trip and application status to "completed"
  Future<void> completeTrip(String tripId, String applicationId) async {
    try {
      // Get current date
      DateTime currentDate = DateTime.now();
      Timestamp endDate = Timestamp.fromDate(currentDate);
      
      print('📅 Setting end date to: ${currentDate.toString()}');
      
      // Update trip status to "completed" and set end date
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'completed',
        'endDate': endDate,
        'updatedAt': Timestamp.now(),
      });
      
      // Update application status to "completed"
      await updateApplicationStatus(applicationId, 'completed');
      
      print('✅ Trip completed successfully with end date: ${currentDate.toString()}');
    } catch (e) {
      print('❌ Error completing trip: $e');
      rethrow;
    }
  }

  /// Get trips that are ready to start (have accepted applications)
  Future<List<Map<String, dynamic>>> getTripsReadyToStart(String touristId) async {
    try {
      print('🔍 Getting trips ready to start for tourist: $touristId');
      
      // Get all trips published by this tourist that have accepted guides
      QuerySnapshot tripsSnapshot = await _firestore
          .collection('trips')
          .where('touristId', isEqualTo: touristId)
          .where('status', isEqualTo: 'accepted')
          .get();
          
      print('📊 Found ${tripsSnapshot.docs.length} trips with accepted status');

      List<Map<String, dynamic>> tripsReadyToStart = [];

      for (var tripDoc in tripsSnapshot.docs) {
        Map<String, dynamic> tripData = tripDoc.data() as Map<String, dynamic>;
        tripData['id'] = tripDoc.id;

        // Check if this trip has an accepted application
        QuerySnapshot applicationsSnapshot = await _firestore
            .collection('trip_applications')
            .where('tripId', isEqualTo: tripDoc.id)
            .where('status', isEqualTo: 'accepted')
            .get();

        if (applicationsSnapshot.docs.isNotEmpty) {
          // Get the accepted application details
          var acceptedApplication = applicationsSnapshot.docs.first;
          Map<String, dynamic> applicationData = acceptedApplication.data() as Map<String, dynamic>;
          applicationData['applicationId'] = acceptedApplication.id;

          // Get guide profile data
          Map<String, dynamic>? guideProfile = await getGuideProfileData(applicationData['guideId']);
          if (guideProfile != null) {
            applicationData.addAll({
              'guideName': guideProfile['name'],
              'guideEmail': guideProfile['email'],
              'guidePhone': guideProfile['phone'],
              'guideLocation': guideProfile['location'],
              'guideProfileImage': guideProfile['profileImageUrl'],
              'guideExperience': guideProfile['experience'],
              'guideLanguages': guideProfile['languages'],
              'guideSpecialties': guideProfile['specialties'],
            });
          }

          // Combine trip and application data
          Map<String, dynamic> combinedData = {
            ...tripData,
            ...applicationData,
          };

          tripsReadyToStart.add(combinedData);
          print('✅ Added trip to ready to start: ${tripData['title']}');
        }
      }

      print('🎯 Total trips ready to start: ${tripsReadyToStart.length}');
      return tripsReadyToStart;
    } catch (e) {
      print('Error getting trips ready to start: $e');
      rethrow;
    }
  }

  /// Get ongoing trips for a tourist (trips that have been started)
  Future<List<Map<String, dynamic>>> getOngoingTripsForTourist(String touristId) async {
    try {
      // Get all trips published by this tourist that are started
      QuerySnapshot tripsSnapshot = await _firestore
          .collection('trips')
          .where('touristId', isEqualTo: touristId)
          .where('status', isEqualTo: 'started')
          .get();

      List<Map<String, dynamic>> ongoingTrips = [];

      for (var tripDoc in tripsSnapshot.docs) {
        Map<String, dynamic> tripData = tripDoc.data() as Map<String, dynamic>;
        tripData['id'] = tripDoc.id;

        // Get the started application details
        QuerySnapshot applicationsSnapshot = await _firestore
            .collection('trip_applications')
            .where('tripId', isEqualTo: tripDoc.id)
            .where('status', isEqualTo: 'started')
            .get();

        if (applicationsSnapshot.docs.isNotEmpty) {
          var startedApplication = applicationsSnapshot.docs.first;
          Map<String, dynamic> applicationData = startedApplication.data() as Map<String, dynamic>;
          applicationData['applicationId'] = startedApplication.id;

          // Get guide profile data
          Map<String, dynamic>? guideProfile = await getGuideProfileData(applicationData['guideId']);
          if (guideProfile != null) {
            applicationData.addAll({
              'guideName': guideProfile['name'],
              'guideEmail': guideProfile['email'],
              'guidePhone': guideProfile['phone'],
              'guideLocation': guideProfile['location'],
              'guideProfileImage': guideProfile['profileImageUrl'],
              'guideExperience': guideProfile['experience'],
              'guideLanguages': guideProfile['languages'],
              'guideSpecialties': guideProfile['specialties'],
            });
          }

          // Combine trip and application data
          Map<String, dynamic> combinedData = {
            ...tripData,
            ...applicationData,
          };

          ongoingTrips.add(combinedData);
        }
      }

      return ongoingTrips;
    } catch (e) {
      print('Error getting ongoing trips for tourist: $e');
      rethrow;
    }
  }

  // Method to check if guide has already applied for a trip
  Future<bool> hasGuideAppliedForTrip(String guideId, String tripId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('trip_applications')
          .where('guideId', isEqualTo: guideId)
          .where('tripId', isEqualTo: tripId)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if guide has applied for trip: $e');
      return false;
    }
  }

  // Method to create a test trip for debugging
  Future<void> createTestTrip() async {
    try {
      final testTripData = {
        'description': 'Test Trip - Colombo City Tour',
        'category': 'City Tour',
        'location': 'Colombo',
        'startDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'startTime': '9:00 AM',
        'duration': '4 hours',
        'groupType': 'Couple',
        'adults': 2,
        'children': 0,
        'infants': 0,
        'budget': 'LKR 15,000',
        'languages': ['English'],
        'requirements': ['Photography'],
        'guideExperience': 'Intermediate',
        'guideSpecialties': ['Cultural Tours'],
        'additionalInfo': 'Looking for a knowledgeable guide',
        'contactInfo': 'Available via WhatsApp',
        'touristId': 'test_tourist_id',
        'touristName': 'Test Tourist',
        'touristEmail': 'test@example.com',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('trips').add(testTripData);
      print('Test trip created successfully');
    } catch (e) {
      print('Error creating test trip: $e');
      rethrow;
    }
  }

  // Method to test if the specific trip from your example exists
  Future<void> testSpecificTrip() async {
    try {
      print('🔍 Testing for specific trip...');
      QuerySnapshot snapshot = await _firestore.collection('trips').get();
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> tripData = doc.data() as Map<String, dynamic>;
        
        // Check if this matches your trip
        if (tripData['touristName'] == 'Ann Thomas' && 
            tripData['description']?.toString().contains('trip description') == true) {
          print('🎯 FOUND YOUR TRIP!');
          print('Document ID: ${doc.id}');
          print('Tourist Name: ${tripData['touristName']}');
          print('Description: ${tripData['description']}');
          print('Status: ${tripData['status']}');
          print('Location: ${tripData['location']}');
          return;
        }
      }
      
      print('❌ Your specific trip not found in database');
    } catch (e) {
      print('Error testing specific trip: $e');
    }
  }

  // Method to get ALL trips without any filtering (for debugging)
  Future<List<Map<String, dynamic>>> getAllTripsUnfiltered() async {
    try {
      print('🔍 Getting ALL trips without any filtering...');
      QuerySnapshot snapshot = await _firestore.collection('trips').get();
      print('Found ${snapshot.docs.length} total documents');
      
      List<Map<String, dynamic>> allTrips = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> tripData = doc.data() as Map<String, dynamic>;
        tripData['id'] = doc.id;
        
        // Convert timestamps
        if (tripData['createdAt'] != null) {
          tripData['createdAt'] = (tripData['createdAt'] as Timestamp).toDate();
        }
        if (tripData['updatedAt'] != null) {
          tripData['updatedAt'] = (tripData['updatedAt'] as Timestamp).toDate();
        }
        if (tripData['startDate'] != null) {
          tripData['startDate'] = (tripData['startDate'] as Timestamp).toDate();
        }
        
        allTrips.add(tripData);
        print('Added trip: ${tripData['touristName']} - ${tripData['description']} - ${tripData['status']}');
      }
      
      print('🎯 Returning ${allTrips.length} trips (NO FILTERING)');
      return allTrips;
    } catch (e) {
      print('Error getting unfiltered trips: $e');
      rethrow;
    }
  }

  /// Get comprehensive tour notifications for a guide
  Future<Map<String, List<Map<String, dynamic>>>> getGuideTourNotifications(String guideId) async {
    try {
      print('🔔 Getting tour notifications for guide: $guideId');
      
      // Get all applications by this guide
      List<Map<String, dynamic>> applications = await getTripApplicationsByGuide(guideId);
      print('Found ${applications.length} applications for guide');
      
      Map<String, List<Map<String, dynamic>>> notifications = {
        'pending': [],
        'ongoing': [],
        'completed': [],
        'rejected': [],
      };
      
      for (var application in applications) {
        String tripId = application['tripId'] as String;
        String status = application['status'] as String;
        
        // Get trip details
        DocumentSnapshot tripDoc = await _firestore.collection('trips').doc(tripId).get();
        if (!tripDoc.exists) continue;
        
        Map<String, dynamic> tripData = tripDoc.data() as Map<String, dynamic>;
        tripData['id'] = tripDoc.id;
        
        // Convert timestamps
        if (tripData['createdAt'] != null) {
          tripData['createdAt'] = (tripData['createdAt'] as Timestamp).toDate();
        }
        if (tripData['startDate'] != null) {
          tripData['startDate'] = (tripData['startDate'] as Timestamp).toDate();
        }
        if (tripData['endDate'] != null) {
          tripData['endDate'] = (tripData['endDate'] as Timestamp).toDate();
        }
        
        // Combine application and trip data
        Map<String, dynamic> notificationData = {
          ...tripData,
          ...application,
          'applicationId': application['id'],
          'notificationType': 'tour_application',
          'notificationTime': application['appliedAt'],
        };
        
        // Determine category based on status and dates
        DateTime now = DateTime.now();
        DateTime? startDate = tripData['startDate'] as DateTime?;
        DateTime? endDate = tripData['endDate'] as DateTime?;
        
        String category = 'pending';
        if (status == 'accepted') {
          category = 'pending'; // Accepted but waiting for tourist to start
        } else if (status == 'started') {
          if (endDate != null && now.isAfter(endDate)) {
            category = 'completed';
          } else {
            category = 'ongoing'; // Trip is actively ongoing
          }
        } else if (status == 'completed') {
          category = 'completed';
        } else if (status == 'rejected') {
          category = 'rejected';
        } else {
          category = 'pending';
        }
        
        notifications[category]!.add(notificationData);
      }
      
      // Sort each category by notification time (most recent first)
      for (var category in notifications.keys) {
        notifications[category]!.sort((a, b) {
          DateTime? aTime = a['notificationTime'] as DateTime?;
          DateTime? bTime = b['notificationTime'] as DateTime?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
      }
      
      print('📊 Notification summary:');
      print('  Pending: ${notifications['pending']!.length}');
      print('  Ongoing: ${notifications['ongoing']!.length}');
      print('  Completed: ${notifications['completed']!.length}');
      print('  Rejected: ${notifications['rejected']!.length}');
      
      return notifications;
    } catch (e) {
      print('Error getting guide tour notifications: $e');
      return {
        'pending': [],
        'ongoing': [],
        'completed': [],
        'rejected': [],
      };
    }
  }

  // Review and Rating Methods
  
  /// Create a review for a guide after completing a trip
  Future<void> createReview({
    required String tripId,
    required String guideId,
    required String touristId,
    required String applicationId,
    required int rating,
    required String reviewText,
    required String tripTitle,
    required String guideName,
  }) async {
    try {
      print('🔍 Creating review for trip: $tripId by tourist: $touristId');
      
      // Check if review already exists for this trip
      QuerySnapshot existingReview = await _firestore
          .collection('reviews')
          .where('tripId', isEqualTo: tripId)
          .where('touristId', isEqualTo: touristId)
          .limit(1)
          .get();

      if (existingReview.docs.isNotEmpty) {
        throw Exception('You have already reviewed this trip');
      }

      // Get tourist's name from users collection
      String touristName = 'Tourist'; // Default fallback
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(touristId)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          touristName = userData['name'] ?? userData['fullName'] ?? 'Tourist';
          print('📝 Tourist name from users collection: $touristName');
        } else {
          print('⚠️ User document not found for tourist: $touristId');
        }
      } catch (e) {
        print('❌ Error fetching tourist name: $e');
      }

      // Create the review document
      Map<String, dynamic> reviewData = {
        'tripId': tripId,
        'applicationId': applicationId,
        'guideId': guideId,
        'touristId': touristId,
        'rating': rating,
        'reviewText': reviewText,
        'tripTitle': tripTitle,
        'guideName': guideName,
        'touristName': touristName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await _firestore.collection('reviews').add(reviewData);
      print('✅ Review created successfully with tourist name: $touristName');
    } catch (e) {
      print('❌ Error creating review: $e');
      rethrow;
    }
  }

  /// Get all reviews for a specific guide
  Future<List<Map<String, dynamic>>> getGuideReviews(String guideId) async {
    try {
      print('🔍 Fetching reviews for guide: $guideId');
      
      // First, get all reviews for this guide (without composite index)
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('guideId', isEqualTo: guideId)
          .get();

      List<Map<String, dynamic>> reviews = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> reviewData = doc.data() as Map<String, dynamic>;
        reviewData['id'] = doc.id;
        
        // Filter for active reviews only
        if (reviewData['isActive'] == true) {
          // Convert timestamps
          if (reviewData['createdAt'] != null) {
            reviewData['createdAt'] = (reviewData['createdAt'] as Timestamp).toDate();
          }
          if (reviewData['updatedAt'] != null) {
            reviewData['updatedAt'] = (reviewData['updatedAt'] as Timestamp).toDate();
          }
          
          reviews.add(reviewData);
        }
      }
      
      // Sort by createdAt in descending order (newest first)
      reviews.sort((a, b) {
        DateTime aDate = a['createdAt'] as DateTime;
        DateTime bDate = b['createdAt'] as DateTime;
        return bDate.compareTo(aDate);
      });
      
      print('✅ Found ${reviews.length} active reviews for guide: $guideId');
      return reviews;
    } catch (e) {
      print('❌ Error getting guide reviews: $e');
      rethrow;
    }
  }

  /// Get average rating for a guide
  Future<double> getGuideAverageRating(String guideId) async {
    try {
      print('🔍 Calculating average rating for guide: $guideId');
      
      // Get all reviews for this guide (without composite index)
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('guideId', isEqualTo: guideId)
          .get();

      if (snapshot.docs.isEmpty) {
        print('📊 No reviews found for guide: $guideId');
        return 0.0;
      }

      double totalRating = 0;
      int activeReviewCount = 0;
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> reviewData = doc.data() as Map<String, dynamic>;
        
        // Only count active reviews
        if (reviewData['isActive'] == true) {
          totalRating += (reviewData['rating'] as int).toDouble();
          activeReviewCount++;
        }
      }

      if (activeReviewCount == 0) {
        print('📊 No active reviews found for guide: $guideId');
        return 0.0;
      }

      double averageRating = totalRating / activeReviewCount;
      print('📊 Average rating for guide $guideId: $averageRating (from $activeReviewCount reviews)');
      return averageRating;
    } catch (e) {
      print('❌ Error getting guide average rating: $e');
      return 0.0;
    }
  }

  /// Get review count for a guide
  Future<int> getGuideReviewCount(String guideId) async {
    try {
      print('🔍 Counting reviews for guide: $guideId');
      
      // Get all reviews for this guide (without composite index)
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('guideId', isEqualTo: guideId)
          .get();

      int activeReviewCount = 0;
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> reviewData = doc.data() as Map<String, dynamic>;
        
        // Only count active reviews
        if (reviewData['isActive'] == true) {
          activeReviewCount++;
        }
      }
      
      print('📊 Found $activeReviewCount active reviews for guide: $guideId');
      return activeReviewCount;
    } catch (e) {
      print('❌ Error getting guide review count: $e');
      return 0;
    }
  }

  /// Check if a tourist has already reviewed a specific trip
  Future<bool> hasTouristReviewedTrip(String tripId, String touristId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('tripId', isEqualTo: tripId)
          .where('touristId', isEqualTo: touristId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if tourist reviewed trip: $e');
      return false;
    }
  }

  /// Get reviews written by a tourist
  Future<List<Map<String, dynamic>>> getTouristReviews(String touristId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('touristId', isEqualTo: touristId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> reviews = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> reviewData = doc.data() as Map<String, dynamic>;
        reviewData['id'] = doc.id;
        
        // Convert timestamps
        if (reviewData['createdAt'] != null) {
          reviewData['createdAt'] = (reviewData['createdAt'] as Timestamp).toDate();
        }
        if (reviewData['updatedAt'] != null) {
          reviewData['updatedAt'] = (reviewData['updatedAt'] as Timestamp).toDate();
        }
        
        reviews.add(reviewData);
      }
      
      return reviews;
    } catch (e) {
      print('Error getting tourist reviews: $e');
      rethrow;
    }
  }

  // Enhanced Guide Notification System
  
  /// Get comprehensive notifications for guides including reviews, payments, reminders, etc.
  Future<Map<String, List<Map<String, dynamic>>>> getComprehensiveGuideNotifications(String guideId) async {
    try {
      print('🔔 Getting comprehensive notifications for guide: $guideId');
      
      Map<String, List<Map<String, dynamic>>> allNotifications = {
        'urgent': [],      // High priority notifications
        'tours': [],       // Tour-related notifications
        'reviews': [],     // Review notifications
        'payments': [],    // Payment notifications
        'reminders': [],   // Trip reminders
        'system': [],      // System notifications
      };

      // 1. Get tour application notifications
      Map<String, List<Map<String, dynamic>>> tourNotifications = await getGuideTourNotifications(guideId);
      
      // Add tour notifications to appropriate categories
      for (var category in tourNotifications.keys) {
        for (var notification in tourNotifications[category]!) {
          Map<String, dynamic> enhancedNotification = {
            ...notification,
            'notificationType': 'tour_application',
            'priority': _getTourNotificationPriority(notification['status']),
          };
          
          if (enhancedNotification['priority'] == 'high') {
            allNotifications['urgent']!.add(enhancedNotification);
          } else {
            allNotifications['tours']!.add(enhancedNotification);
          }
        }
      }

      // 2. Get new review notifications
      List<Map<String, dynamic>> reviewNotifications = await _getNewReviewNotifications(guideId);
      allNotifications['reviews']!.addAll(reviewNotifications);

      // 3. Get payment notifications
      List<Map<String, dynamic>> paymentNotifications = await _getPaymentNotifications(guideId);
      allNotifications['payments']!.addAll(paymentNotifications);

      // 4. Get trip reminders
      List<Map<String, dynamic>> reminderNotifications = await _getTripReminderNotifications(guideId);
      allNotifications['reminders']!.addAll(reminderNotifications);

      // 5. Get system notifications
      List<Map<String, dynamic>> systemNotifications = await _getSystemNotifications(guideId);
      allNotifications['system']!.addAll(systemNotifications);

      // Sort all categories by priority and time
      for (var category in allNotifications.keys) {
        allNotifications[category]!.sort((a, b) {
          // First sort by priority
          int priorityComparison = _getPriorityWeight(b['priority'] ?? 'medium').compareTo(_getPriorityWeight(a['priority'] ?? 'medium'));
          if (priorityComparison != 0) return priorityComparison;
          
          // Then by time (most recent first)
          DateTime? aTime = a['notificationTime'] as DateTime?;
          DateTime? bTime = b['notificationTime'] as DateTime?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
      }

      print('📊 Comprehensive notification summary:');
      print('  Urgent: ${allNotifications['urgent']!.length}');
      print('  Tours: ${allNotifications['tours']!.length}');
      print('  Reviews: ${allNotifications['reviews']!.length}');
      print('  Payments: ${allNotifications['payments']!.length}');
      print('  Reminders: ${allNotifications['reminders']!.length}');
      print('  System: ${allNotifications['system']!.length}');

      return allNotifications;
    } catch (e) {
      print('Error getting comprehensive guide notifications: $e');
      return {
        'urgent': [],
        'tours': [],
        'reviews': [],
        'payments': [],
        'reminders': [],
        'system': [],
      };
    }
  }

  /// Get new review notifications for guides
  Future<List<Map<String, dynamic>>> _getNewReviewNotifications(String guideId) async {
    try {
      // Get recent reviews (last 7 days)
      DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('guideId', isEqualTo: guideId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> notifications = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> reviewData = doc.data() as Map<String, dynamic>;
        
        // Convert timestamp
        DateTime? createdAt = reviewData['createdAt'] != null 
            ? (reviewData['createdAt'] as Timestamp).toDate() 
            : null;
            
        if (createdAt != null && createdAt.isAfter(weekAgo)) {
          notifications.add({
            'id': doc.id,
            'notificationType': 'new_review',
            'title': 'New Review Received!',
            'message': '${reviewData['touristName']} left a ${reviewData['rating']}-star review for "${reviewData['tripTitle']}"',
            'rating': reviewData['rating'],
            'touristName': reviewData['touristName'],
            'tripTitle': reviewData['tripTitle'],
            'reviewText': reviewData['reviewText'],
            'notificationTime': createdAt,
            'priority': reviewData['rating'] >= 4 ? 'medium' : 'high', // Low ratings are high priority
            'icon': Icons.star,
            'color': reviewData['rating'] >= 4 ? Colors.green : Colors.orange,
            'actionRequired': reviewData['rating'] < 3, // Respond to low ratings
          });
        }
      }
      
      return notifications;
    } catch (e) {
      print('Error getting new review notifications: $e');
      return [];
    }
  }

  /// Get payment notifications for guides
  Future<List<Map<String, dynamic>>> _getPaymentNotifications(String guideId) async {
    try {
      // This would typically come from a payments collection
      // For now, we'll create some mock payment notifications
      List<Map<String, dynamic>> notifications = [];
      
      // Check for recent completed trips that might have payments
      List<Map<String, dynamic>> applications = await getTripApplicationsByGuide(guideId);
      
      for (var application in applications) {
        if (application['status'] == 'completed') {
          DateTime? completedAt = application['completedAt'] != null 
              ? (application['completedAt'] as Timestamp).toDate() 
              : null;
              
          if (completedAt != null && completedAt.isAfter(DateTime.now().subtract(const Duration(days: 3)))) {
            notifications.add({
              'id': 'payment_${application['id']}',
              'notificationType': 'payment_processed',
              'title': 'Payment Processed',
              'message': 'Payment for "${application['tripTitle'] ?? 'your trip'}" has been processed and will be transferred within 3-5 business days',
              'amount': application['dailyRate'] ?? 'N/A',
              'tripTitle': application['tripTitle'],
              'notificationTime': completedAt,
              'priority': 'medium',
              'icon': Icons.payment,
              'color': Colors.green,
              'actionRequired': false,
            });
          }
        }
      }
      
      return notifications;
    } catch (e) {
      print('Error getting payment notifications: $e');
      return [];
    }
  }

  /// Get trip reminder notifications
  Future<List<Map<String, dynamic>>> _getTripReminderNotifications(String guideId) async {
    try {
      List<Map<String, dynamic>> notifications = [];
      
      // Get upcoming trips (next 3 days)
      List<Map<String, dynamic>> applications = await getTripApplicationsByGuide(guideId);
      
      for (var application in applications) {
        if (application['status'] == 'accepted' || application['status'] == 'started') {
          DateTime? startDate = application['startDate'] != null 
              ? (application['startDate'] as Timestamp).toDate() 
              : null;
              
          if (startDate != null) {
            Duration timeUntilTrip = startDate.difference(DateTime.now());
            
            // Reminder 1 day before
            if (timeUntilTrip.inDays == 1 && timeUntilTrip.inHours > 0) {
              notifications.add({
                'id': 'reminder_1day_${application['id']}',
                'notificationType': 'trip_reminder',
                'title': 'Trip Tomorrow!',
                'message': 'You have "${application['tripTitle'] ?? 'a trip'}" starting tomorrow. Please prepare and confirm with the tourist.',
                'tripTitle': application['tripTitle'],
                'startDate': startDate,
                'notificationTime': DateTime.now(),
                'priority': 'high',
                'icon': Icons.schedule,
                'color': Colors.orange,
                'actionRequired': true,
              });
            }
            
            // Reminder 2 hours before
            if (timeUntilTrip.inHours == 2 && timeUntilTrip.inMinutes > 0) {
              notifications.add({
                'id': 'reminder_2hr_${application['id']}',
                'notificationType': 'trip_reminder',
                'title': 'Trip Starting Soon!',
                'message': 'Your trip "${application['tripTitle'] ?? 'Trip'}" starts in 2 hours. Please contact the tourist to confirm meeting details.',
                'tripTitle': application['tripTitle'],
                'startDate': startDate,
                'notificationTime': DateTime.now(),
                'priority': 'urgent',
                'icon': Icons.warning,
                'color': Colors.red,
                'actionRequired': true,
              });
            }
          }
        }
      }
      
      return notifications;
    } catch (e) {
      print('Error getting trip reminder notifications: $e');
      return [];
    }
  }

  /// Get system notifications
  Future<List<Map<String, dynamic>>> _getSystemNotifications(String guideId) async {
    try {
      // This would typically come from a system_notifications collection
      // For now, we'll create some important system notifications
      List<Map<String, dynamic>> notifications = [];
      
      // Check guide's profile completion
      DocumentSnapshot guideDoc = await _firestore.collection('users').doc(guideId).get();
      if (guideDoc.exists) {
        Map<String, dynamic> guideData = guideDoc.data() as Map<String, dynamic>;
        
        if (!(guideData['profileCompleted'] ?? false)) {
          notifications.add({
            'id': 'profile_incomplete',
            'notificationType': 'system',
            'title': 'Complete Your Profile',
            'message': 'Your profile is incomplete. Complete it to get more bookings and improve your visibility.',
            'notificationTime': DateTime.now(),
            'priority': 'high',
            'icon': Icons.person_add,
            'color': Colors.blue,
            'actionRequired': true,
            'actionUrl': '/profile/edit',
          });
        }
        
        // Check for low ratings
        double averageRating = await getGuideAverageRating(guideId);
        if (averageRating > 0 && averageRating < 3.0) {
          notifications.add({
            'id': 'low_rating_warning',
            'notificationType': 'system',
            'title': 'Rating Alert',
            'message': 'Your average rating is ${averageRating.toStringAsFixed(1)}. Consider improving your service quality to get better ratings.',
            'averageRating': averageRating,
            'notificationTime': DateTime.now(),
            'priority': 'high',
            'icon': Icons.star_half,
            'color': Colors.orange,
            'actionRequired': true,
          });
        }
        
        // Monthly performance summary
        DateTime now = DateTime.now();
        if (now.day == 1) { // First day of month
          notifications.add({
            'id': 'monthly_summary_${now.year}_${now.month}',
            'notificationType': 'system',
            'title': 'Monthly Performance',
            'message': 'Check your monthly performance summary including earnings, bookings, and ratings.',
            'notificationTime': DateTime.now(),
            'priority': 'medium',
            'icon': Icons.analytics,
            'color': Colors.purple,
            'actionRequired': false,
          });
        }
      }
      
      return notifications;
    } catch (e) {
      print('Error getting system notifications: $e');
      return [];
    }
  }

  /// Get priority level for tour notifications
  String _getTourNotificationPriority(String status) {
    switch (status) {
      case 'accepted':
        return 'high'; // Tourist accepted, guide should prepare
      case 'started':
        return 'urgent'; // Trip is active
      case 'completed':
        return 'low'; // Trip finished
      case 'rejected':
        return 'low'; // Application rejected
      default:
        return 'medium'; // Pending applications
    }
  }

  /// Get priority weight for sorting
  int _getPriorityWeight(String priority) {
    switch (priority) {
      case 'urgent':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  /// Test Firebase connection and diagnose issues
  Future<Map<String, dynamic>> testFirebaseConnection() async {
    Map<String, dynamic> results = {
      'auth': false,
      'firestore': false,
      'storage': false,
      'errors': [],
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      print('🔍 [FIREBASE_SERVICE] Starting Firebase connection test...');

      // Test Authentication
      try {
        final user = _auth.currentUser;
        results['auth'] = user != null;
        print('✅ [FIREBASE_SERVICE] Auth test: ${user != null ? "PASSED" : "FAILED"}');
        if (user == null) {
          results['errors'].add('No authenticated user found');
        }
      } catch (e) {
        results['errors'].add('Auth test failed: $e');
        print('❌ [FIREBASE_SERVICE] Auth test failed: $e');
      }

      // Test Firestore
      try {
        final testDoc = await _firestore
            .collection('_test')
            .doc('connection_test')
            .get()
            .timeout(const Duration(seconds: 10));
        results['firestore'] = true;
        print('✅ [FIREBASE_SERVICE] Firestore test: PASSED');
      } catch (e) {
        results['errors'].add('Firestore test failed: $e');
        print('❌ [FIREBASE_SERVICE] Firestore test failed: $e');
      }

      // Test Storage
      try {
        final testRef = _storage.ref().child('_test/connection_test.txt');
        await testRef.putString('test').timeout(const Duration(seconds: 10));
        await testRef.delete();
        results['storage'] = true;
        print('✅ [FIREBASE_SERVICE] Storage test: PASSED');
      } catch (e) {
        results['errors'].add('Storage test failed: $e');
        print('❌ [FIREBASE_SERVICE] Storage test failed: $e');
      }

      // Test specific trips collection
      try {
        final tripsSnapshot = await _firestore
            .collection('trips')
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));
        results['trips_collection'] = true;
        print('✅ [FIREBASE_SERVICE] Trips collection test: PASSED (${tripsSnapshot.docs.length} docs)');
      } catch (e) {
        results['errors'].add('Trips collection test failed: $e');
        print('❌ [FIREBASE_SERVICE] Trips collection test failed: $e');
      }

    } catch (e) {
      results['errors'].add('General connection test failed: $e');
      print('❌ [FIREBASE_SERVICE] General connection test failed: $e');
    }

    print('🎯 [FIREBASE_SERVICE] Connection test completed:');
    print('  Auth: ${results['auth']}');
    print('  Firestore: ${results['firestore']}');
    print('  Storage: ${results['storage']}');
    print('  Errors: ${results['errors'].length}');

    return results;
  }

  /// Clear Firebase cache and reset connection
  Future<void> resetFirebaseConnection() async {
    try {
      print('🔄 [FIREBASE_SERVICE] Resetting Firebase connection...');
      
      // Clear any cached data
      await _firestore.clearPersistence();
      print('✅ [FIREBASE_SERVICE] Firestore cache cleared');
      
      // Reinitialize storage
      _storage = FirebaseStorage.instance;
      print('✅ [FIREBASE_SERVICE] Storage reinitialized');
      
      print('🎯 [FIREBASE_SERVICE] Firebase connection reset completed');
    } catch (e) {
      print('❌ [FIREBASE_SERVICE] Error resetting Firebase connection: $e');
      rethrow;
    }
  }
}



