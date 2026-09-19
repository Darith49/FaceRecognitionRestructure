import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  //Find User in Firestore by uid
  Future<UserModel?> getUserByUid(String uid) async {
    final doc = await _userCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }
}
