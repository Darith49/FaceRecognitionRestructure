import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  //Forgot Passwrod
  Future<void> resetPassowrd({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  //Sign In With Google
  Future<UserCredential> signInWithGoogle() async {
    //Show google account picker
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    //Create Firebase credentail from Google Token
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    //Sign in to Firebase with Google credential
    UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await userCredential.user?.delete();
      await logout();
      throw Exception(
        'It not allow to Signup please contact to sonarseang@gmail 😝😝😝',
      );
    }

    return userCredential;
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get Firebase ID Token for Django API authentication
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  //Find User in Firestore by uid
  Future<UserModel?> getUserByUid(String uid) async {
    final doc = await _userCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }
}
