import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class FirebaseService {
  // Authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Storage
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Login with faculty ID and password
  Future<UserCredential> loginWithFacultyId(
      String facultyId, String password) async {
    try {
      // First find the user's email by faculty ID
      final snapshot = await _firestore
          .collection('faculty')
          .where('facultyId', isEqualTo: facultyId)
          .get();

      if (snapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No faculty found with this ID.',
        );
      }

      final facultyData = snapshot.docs.first.data();
      final email = facultyData['email'];

      if (email == null) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Email not found for this faculty ID.',
        );
      }

      // Sign in with email and password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      await _firestore
          .collection('faculty')
          .doc(userCredential.user!.uid)
          .update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // Store user data in SharedPreferences
      final userData = {
        'name': facultyData['name'],
        'email': email,
        'facultyId': facultyId,
        'department': facultyData['department'],
        'type': 'faculty',
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', json.encode(userData));

      return userCredential;
    } catch (e) {
      if (e is FirebaseAuthException) {
        rethrow;
      }
      throw FirebaseAuthException(
        code: 'login-failed',
        message: 'Failed to login: $e',
      );
    }
  }

  // Login with student registration number and password
  Future<UserCredential> loginWithRegNumber(
      String regNumber, String password) async {
    try {
      // First find the user's email by registration number
      final snapshot = await _firestore
          .collection('students')
          .where('regNumber', isEqualTo: regNumber)
          .get();

      if (snapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No student found with this registration number.',
        );
      }

      final email = snapshot.docs.first.data()['email'];

      // Now sign in with email and password
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Register faculty
  Future<UserCredential> registerFaculty({
    required String name,
    required String email,
    required String password,
    required String facultyId,
    required String department,
  }) async {
    try {
      // Create the user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store additional faculty data
      await _firestore.collection('faculty').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'facultyId': facultyId,
        'department': department,
        'type': 'faculty',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Register student
  Future<UserCredential> registerStudent({
    required String name,
    required String regNumber,
    required String email,
    required String password,
  }) async {
    try {
      // First check if registration number already exists
      final querySnapshot = await _firestore
          .collection('students')
          .where('regNumber', isEqualTo: regNumber)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw 'Registration number already exists';
      }

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in Firestore
      await _firestore
          .collection('students')
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'regNumber': regNumber,
        'email': email,
        'type': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw 'Failed to register student: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      // Check in faculty collection first
      DocumentSnapshot facultyDoc =
          await _firestore.collection('faculty').doc(user.uid).get();

      if (facultyDoc.exists) {
        return facultyDoc.data() as Map<String, dynamic>;
      }

      // If not in faculty, check students collection
      DocumentSnapshot studentDoc =
          await _firestore.collection('students').doc(user.uid).get();

      if (studentDoc.exists) {
        return studentDoc.data() as Map<String, dynamic>;
      }

      throw Exception('User data not found.');
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      String collectionName =
          userData['type'] == 'faculty' ? 'faculty' : 'students';

      await _firestore
          .collection(collectionName)
          .doc(user.uid)
          .update(userData);
    } catch (e) {
      rethrow;
    }
  }

  // Upload profile image and get download URL
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      final storageRef = _storage.ref().child('profile_images/${user.uid}.jpg');

      // For web platform, handling is different
      if (kIsWeb) {
        final Uint8List bytes = await imageFile.readAsBytes();
        await storageRef.putData(bytes);
      } else {
        await storageRef.putFile(imageFile);
      }

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Update user profile with image URL
      final userData = await getUserData();
      userData['profileImageUrl'] = downloadUrl;
      await updateUserProfile(userData);

      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Create a new post with optional media
  Future<void> createPost({
    required String title,
    required String content,
    File? mediaFile,
    String? mediaType,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      // Get user data to check role
      DocumentSnapshot facultyDoc =
          await _firestore.collection('faculty').doc(user.uid).get();
      DocumentSnapshot studentDoc =
          await _firestore.collection('students').doc(user.uid).get();
      DocumentSnapshot publicDoc =
          await _firestore.collection('public_users').doc(user.uid).get();

      String userRole;
      String userName;

      if (facultyDoc.exists) {
        userRole = 'faculty';
        userName = (facultyDoc.data() as Map<String, dynamic>)['name'] ?? '';
      } else if (studentDoc.exists) {
        userRole = 'student';
        userName = (studentDoc.data() as Map<String, dynamic>)['name'] ?? '';
      } else if (publicDoc.exists) {
        userRole = 'public';
        userName = 'Public User';
      } else {
        throw Exception('User role not found.');
      }

      // Check if user has permission to upload media
      if (mediaFile != null && userRole != 'faculty') {
        throw Exception('Only faculty members can upload media content.');
      }

      // Prepare post data
      final postRef = _firestore.collection('posts').doc();
      final postData = {
        'title': title,
        'content': content,
        'authorId': user.uid,
        'authorName': userName,
        'authorType': userRole,
        'mediaType': mediaType,
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Handle media upload based on platform
      if (mediaFile != null && mediaType != null && userRole == 'faculty') {
        if (kIsWeb) {
          // Web platform: Use base64 encoding
          try {
            // Try to get stored base64 data from SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            final base64Data = prefs.getString('lastPostMediaBase64');

            if (base64Data != null) {
              // Store base64 data directly in Firestore for web
              postData['mediaBase64'] = base64Data;

              // Clean up after use
              await prefs.remove('lastPostMediaBase64');
              await prefs.remove('lastPostMediaType');
            } else {
              // If we don't have base64 data, try to read from file
              try {
                final bytes = await mediaFile.readAsBytes();
                final base64String = base64Encode(bytes);
                postData['mediaBase64'] = base64String;
              } catch (e) {
                print('Error encoding file to base64: $e');
              }
            }
          } catch (e) {
            print('Error handling web media: $e');
          }
        } else {
          // Native platforms (Android/iOS): Use Firebase Storage
          try {
            final storageRef =
                _storage.ref().child('post_media/${postRef.id}.$mediaType');

            // Check if the file exists
            bool fileExists = await mediaFile.exists();
            if (!fileExists) {
              throw Exception('Media file does not exist');
            }

            // Check file size (limit to 10MB)
            final fileSize = await mediaFile.length();
            if (fileSize > 10 * 1024 * 1024) {
              throw Exception('File size must be less than 10MB');
            }

            // Check file type
            if (!['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov']
                .contains(mediaType.toLowerCase())) {
              throw Exception(
                  'Unsupported file type. Allowed types: jpg, jpeg, png, gif, mp4, mov');
            }

            // Upload to Firebase Storage
            await storageRef.putFile(mediaFile);
            final downloadUrl = await storageRef.getDownloadURL();
            postData['mediaUrl'] = downloadUrl;

            // For Android/iOS, also store the media path for local access
            postData['mediaPath'] = mediaFile.path;
          } catch (e) {
            print('Error uploading media to Firebase Storage: $e');
            throw Exception('Failed to upload media: $e');
          }
        }
      }

      // Save post to Firestore
      await postRef.set(postData);
    } catch (e) {
      print('Error in createPost: $e');
      rethrow;
    }
  }

  // Get all posts
  Stream<QuerySnapshot> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Like/unlike a post
  Future<void> togglePostLike(String postId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      // Reference to the post
      final postRef = _firestore.collection('posts').doc(postId);

      // Check if user already liked this post
      final likeRef = _firestore
          .collection('postLikes')
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: user.uid)
          .limit(1);

      final snapshot = await likeRef.get();

      // Using a transaction to ensure counts are accurate
      await _firestore.runTransaction((transaction) async {
        // Get the current post data
        final postDoc = await transaction.get(postRef);
        final currentLikes = postDoc.data()?['likes'] ?? 0;

        if (snapshot.docs.isEmpty) {
          // User hasn't liked this post yet, add like
          final newLikeRef = _firestore.collection('postLikes').doc();
          transaction.set(newLikeRef, {
            'postId': postId,
            'userId': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Increment like count
          transaction.update(postRef, {'likes': currentLikes + 1});
        } else {
          // User already liked this post, remove like
          transaction.delete(snapshot.docs.first.reference);

          // Decrement like count
          transaction.update(postRef, {'likes': currentLikes - 1});
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  // Add a job posting
  Future<void> addJobPosting({
    required String title,
    required String company,
    required String location,
    required String package,
    String? url,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      // Ensure user is faculty
      final userData = await getUserData();
      if (userData['type'] != 'faculty') {
        throw Exception('Only faculty members can add job postings.');
      }

      // Create job document
      await _firestore.collection('jobs').add({
        'title': title,
        'company': company,
        'location': location,
        'package': package,
        'url': url,
        'postedBy': user.uid,
        'postedByName': userData['name'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get all job postings
  Stream<QuerySnapshot> getJobPostings() {
    return _firestore
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add placed student
  Future<void> addPlacedStudent({
    required String name,
    required String company,
    required String package,
    required String batch,
    File? imageFile,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      // Ensure user is faculty
      final userData = await getUserData();
      if (userData['type'] != 'faculty') {
        throw Exception('Only faculty members can add placed students.');
      }

      // Create placed student document
      final studentRef = _firestore.collection('placedStudents').doc();

      final studentData = {
        'name': name,
        'company': company,
        'package': package,
        'batch': batch,
        'addedBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Upload image if provided
      if (imageFile != null) {
        final storageRef =
            _storage.ref().child('placed_students/${studentRef.id}.jpg');

        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          await storageRef.putData(bytes);
        } else {
          await storageRef.putFile(imageFile);
        }

        // Get download URL and add to student data
        final downloadUrl = await storageRef.getDownloadURL();
        studentData['imageUrl'] = downloadUrl;
      }

      // Save placed student to Firestore
      await studentRef.set(studentData);
    } catch (e) {
      rethrow;
    }
  }

  // Get all placed students
  Stream<QuerySnapshot> getPlacedStudents() {
    return _firestore
        .collection('placedStudents')
        .orderBy('batch', descending: true)
        .snapshots();
  }

  // Add student login method
  Future<void> loginStudent({
    required String regNumber,
    required String password,
  }) async {
    try {
      // First get the email associated with this registration number
      final querySnapshot = await _firestore
          .collection('students')
          .where('regNumber', isEqualTo: regNumber)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'Student with this registration number not found';
      }

      final studentData = querySnapshot.docs.first.data();
      final email = studentData['email'];

      if (email == null) {
        throw 'Email not found for this registration number';
      }

      // Login with email and password
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      await _firestore
          .collection('students')
          .doc(querySnapshot.docs.first.id)
          .update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to login: $e';
    }
  }

  Future<void> registerPublicUser({
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store additional user data in Firestore
      await _firestore
          .collection('public_users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'mobileNumber': mobileNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'public',
      });
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> loginPublicUser({
    required String mobileNumber,
    required String password,
  }) async {
    try {
      // First, find the user's email using their mobile number
      final userQuery = await _firestore
          .collection('public_users')
          .where('mobileNumber', isEqualTo: mobileNumber)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw 'No user found with this mobile number';
      }

      final userData = userQuery.docs.first.data();
      final email = userData['email'] as String;

      // Sign in with email and password
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email/mobile number';
        case 'wrong-password':
          return 'Wrong password provided';
        case 'email-already-in-use':
          return 'Email is already in use';
        case 'invalid-email':
          return 'Invalid email address';
        case 'weak-password':
          return 'Password is too weak';
        case 'operation-not-allowed':
          return 'Operation not allowed';
        case 'user-disabled':
          return 'User has been disabled';
        default:
          return 'An error occurred: ${error.message}';
      }
    }
    return error.toString();
  }

  // Check if user has permission to create content
  Future<Map<String, dynamic>> getUserPermissions() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      // Check user role in different collections
      DocumentSnapshot facultyDoc =
          await _firestore.collection('faculty').doc(user.uid).get();
      DocumentSnapshot studentDoc =
          await _firestore.collection('students').doc(user.uid).get();
      DocumentSnapshot publicDoc =
          await _firestore.collection('public_users').doc(user.uid).get();

      String userRole;
      Map<String, dynamic> permissions;

      if (facultyDoc.exists) {
        userRole = 'faculty';
        permissions = {
          'canUploadMedia': true,
          'canCreatePosts': true,
          'canEditContent': true,
          'canDeleteContent': true,
          'canManageUsers': true,
        };
      } else if (studentDoc.exists) {
        userRole = 'student';
        permissions = {
          'canUploadMedia': false,
          'canCreatePosts': true,
          'canEditContent': false,
          'canDeleteContent': false,
          'canManageUsers': false,
        };
      } else if (publicDoc.exists) {
        userRole = 'public';
        permissions = {
          'canUploadMedia': false,
          'canCreatePosts': true,
          'canEditContent': false,
          'canDeleteContent': false,
          'canManageUsers': false,
        };
      } else {
        throw Exception('User role not found.');
      }

      return {
        'role': userRole,
        'permissions': permissions,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Add a new job posting
  Future<void> addJob({
    required String title,
    required String company,
    required String location,
    required String experience,
    required String salaryRange,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      // Ensure user is faculty
      final userData = await getUserData();
      if (userData['type'] != 'faculty') {
        throw Exception('Only faculty members can post jobs.');
      }

      // Create job document
      await _firestore.collection('jobs').add({
        'title': title,
        'company': company,
        'location': location,
        'experience': experience,
        'salaryRange': salaryRange,
        'postedBy': user.uid,
        'postedByName': userData['name'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get all job postings
  Stream<QuerySnapshot> getJobs() {
    return _firestore
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
