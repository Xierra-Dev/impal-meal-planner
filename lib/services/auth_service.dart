import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Method to get current user's email
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  // Method to get current user's username (display name)
  Future<String?> getCurrentUsername() async {
    // Try to get username from Firebase Auth first
    String? authUsername = _auth.currentUser?.displayName;

    if (authUsername != null) return authUsername;

    // If not found in Auth, try Firestore
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        var userDoc = await _firestore.collection('users').doc(user.uid).get();
        return userDoc.data()?['displayName'];
      }
    } catch (e) {
      print('Error retrieving username from Firestore: $e');
    }

    return null;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cek apakah email belum diverifikasi
      if (!userCredential.user!.emailVerified) {
        // Logout dan lempar pengecualian
        await signOut();
        throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Silakan verifikasi email Anda terlebih dahulu.'
        );
      }

      // Return UserCredential meskipun email belum diverifikasi
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<bool> waitForEmailVerification({Duration timeout = const Duration(minutes: 3)}) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    final Completer<bool> completer = Completer<bool>();
    final Timer timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });

    // Listen to user changes
    final subscription = _auth.userChanges().listen((User? updatedUser) {
      if (updatedUser?.emailVerified ?? false) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(true);
      }
    });

    try {
      final result = await completer.future;
      return result;
    } finally {
      subscription.cancel();
      timer.cancel(); // Ensure the timer is always cancelled
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Send verification email immediately
      await userCredential.user?.sendEmailVerification();

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'firstName': displayName.split(' ').first,
        'lastName': displayName.split(' ').length > 1 ? displayName.split(' ').last : '',
        'timestamp': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });

      // Tunggu hingga email diverifikasi atau timeout
      bool isVerified = await waitForEmailVerification(timeout: Duration(minutes: 5));
      if (!isVerified) {
        // Jika tidak diverifikasi dalam 5 menit, hapus akun dari Firebase Auth dan Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).delete();
        await userCredential.user?.delete();
        throw FirebaseAuthException(
          code: 'verification-timeout',
          message: 'Email verification timeout. Please register again.',
        );
      }

      return userCredential;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Updated method to retrieve first and last name
  Future<Map<String, String?>> getUserNames() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        var userDoc = await _firestore.collection('users').doc(user.uid).get();
        return {
          'displayName': userDoc.data()?['displayName'],
          'firstName': userDoc.data()?['firstName'],
          'lastName': userDoc.data()?['lastName']
        };
      }
    } catch (e) {
      print('Error retrieving user names: $e');
    }
    return {};
  }

  void _startVerificationTimer(User user) {
    Timer(Duration(minutes: 3), () async {
      // Reload user untuk mendapatkan status terbaru
      await user.reload();

      // Periksa apakah email telah diverifikasi
      if (user.emailVerified) {
        // Update status di Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'emailVerified': true,
        });
      } else {
        // Jika belum diverifikasi, hapus user dari Firestore dan Firebase Auth
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
      }
    });
  }

  // Update user profile
  Future<void> updateUserProfile(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
  }

  // Handle Firebase Auth exceptions
  FirebaseAuthException _handleAuthException(FirebaseAuthException e) {
    return e;
  }

  // Update display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
      } else {
        throw 'No authenticated user found';
      }
    } catch (e) {
      print('Error updating display name: $e');
      rethrow;
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Error sending verification email: $e');
    }
  }

  // Custom method to ensure user can only proceed if email is verified
  Future<void> ensureEmailVerified() async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('Tidak ada pengguna yang login');
    }

    // Reload user to get the latest verification status
    await user.reload();

    if (!user.emailVerified) {
      // Logout user if email is not verified
      await signOut();
      throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Silakan verifikasi email Anda terlebih dahulu.'
      );
    }
  }


  Future<bool> checkUsernameUniqueness(String username) async {
    try {
      // Query Firestore to check if username exists
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking username uniqueness: $e');
      return false;
    }
  }

  // Add this method for Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google Sign In Flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Cek apakah ini first-time login dengan memeriksa dokumen personalization
      bool isFirstTime = await isFirstTimeLogin();

      // Jika first time, buat dokumen user baru
      if (isFirstTime) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'displayName': userCredential.user!.displayName,
          'photoURL': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Update lastLogin untuk existing user
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<bool> isFirstTimeLogin() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return true;

      // Cek apakah dokumen personalization sudah ada
      final personalizationDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('personalization')
          .get();

      return !personalizationDoc.exists;
    } catch (e) {
      print('Error checking first time login: $e');
      return true; // Assume first time if error occurs
    }
  }

  // Add this method to sign out from Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out from Google: $e');
      rethrow;
    }
  }
}

