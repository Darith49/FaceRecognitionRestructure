import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  CollectionReference<Map<String, dynamic>> get _userCollection =>
      _db.collection('users');

  //It return Usermodel because after login we need data from this user like fullname , email , branchId ....
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) return null;

    return getUserByUid(firebaseUser.uid);
  }

  //it void because logout we don't need anydata just signOut
  Future<void> logout() async {
    try {
      await _auth.signOut().timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Error signing out from FirebaseAuth: $e');
    }
    try {
      await _googleSignIn.signOut().timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Error signing out from GoogleSignIn: $e');
    }
  }

  //Forgot Passwrod
  Future<void> resetPassowrd({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  //Sign In With Google
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // On web, use Firebase Auth popup which works directly without GIS client ID
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      try {
        final UserCredential userCredential =
            await _auth.signInWithPopup(googleProvider);
        return userCredential;
      } catch (e) {
        debugPrint('Web Google sign in error: $e');
        final msg = e.toString().toLowerCase();
        if (msg.contains('popup-closed-by-user') ||
            msg.contains('cancelled') ||
            msg.contains('user-cancelled')) {
          throw Exception('Google sign-in was cancelled.');
        }
        rethrow;
      }
    }

    // Native Mobile Flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    //Create Firebase credential from Google Token
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    //Sign in to Firebase with Google credential
    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );

    return userCredential;
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get Firebase ID Token for Django API authentication
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    User? user = _auth.currentUser;
    if (user == null) {
      // Firebase Auth restores state asynchronously upon app launch.
      // Wait briefly for authStateChanges if a user session exists.
      try {
        user = await _auth
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        user = _auth.currentUser;
      }
    }
    if (user == null) return null;
    try {
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('getIdToken error: $e');
      return null;
    }
  }

  //Find User in Firestore by uid
  Future<UserModel?> getUserByUid(String uid) async {
    final doc = await _userCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // Find User in Firestore by email (fallback for Google Sign In)
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final cleanEmail = email.trim();
      final query = await _userCollection
          .where('email', isEqualTo: cleanEmail.toLowerCase())
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return UserModel.fromMap(query.docs.first.data());
      }
      final queryExact = await _userCollection
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      if (queryExact.docs.isNotEmpty) {
        return UserModel.fromMap(queryExact.docs.first.data());
      }
    } catch (e) {
      debugPrint('getUserByEmail error: $e');
    }
    return null;
  }

  // Update profile picture in Firestore
  Future<void> updateProfilePicture(String uid, String profileUrl) async {
    await _userCollection
        .doc(uid)
        .set({'profileUrl': profileUrl}, SetOptions(merge: true));
  }

  // Ensure Firestore user record is linked with the active UID
  Future<void> linkFirestoreUser(String targetUid, UserModel user) async {
    try {
      final data = user.toMap();
      data['uid'] = targetUid;
      await _userCollection.doc(targetUid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('linkFirestoreUser error: $e');
    }
  }
}
