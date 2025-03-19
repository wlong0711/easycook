import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;  // ✅ Firestore instance
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Sign Up & Store User in Firestore
  Future<User?> signUp(String email, String password, String fullName, String phoneNumber) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // ✅ Store user info in Firestore
      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "fullName": fullName,
          "email": email,
          "phoneNumber": phoneNumber,  // ✅ Added phone number
          "profilePic": "",  // Placeholder (can be updated later)
        });
      }

      return user;
    } catch (e) {
      print("Sign Up Error: $e");
      return null;
    }
  }

  // ✅ Sign In Function (Ensure it's named correctly)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Sign In Error: $e");
      return null;
    }
  }

  // ✅ Password Reset Function
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print("Password Reset Error: $e");
      return false;
    }
  }

  // Fetch User Profile Data from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(uid).get();
      return userDoc.exists ? userDoc.data() as Map<String, dynamic> : null;
    } catch (e) {
      print("Fetch User Profile Error: $e");
      return null;
    }
  }

  // ✅ Update User Profile (Firestore)
  Future<void> updateUserProfile(String uid, String fullName, String phoneNumber) async {
    await _firestore.collection("users").doc(uid).update({
      "fullName": fullName,
      "phoneNumber": phoneNumber,
    });
  }

  // ✅ Upload Profile Picture to Firebase Storage
  Future<String?> uploadProfilePicture(String uid, File imageFile) async {
    try {
      Reference ref = _storage.ref().child("profile_pictures/$uid.jpg");
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Profile Picture Upload Error: $e");
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
