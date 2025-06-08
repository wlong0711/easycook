import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userProfile;  // ✅ Stores Firestore user data

  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;

  // Sign Up
  Future<bool> signUp(String email, String password, String fullName, String phoneNumber) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user?.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
      });

      _user = userCredential.user;   // ✅ Add this
      notifyListeners();             // ✅ Optional
      return true;
    } catch (e) {
      print("SignUp Error: $e");
      return false;
    }
  }

  // ✅ Ensure signIn method exists
  Future<bool> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (!userCredential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before logging in.',
        );
      }

      _user = userCredential.user; // ✅ FIX: set the current user
      await fetchUserProfile();    // ✅ Optionally load the profile
      notifyListeners();           // ✅ Notify any listeners to rebuild
      return true;
    } catch (e) {
      print("Login Error: $e");
      return false;
    }
  }

  // ✅ Ensure resetPassword method exists
  Future<bool> resetPassword(String email) async {
    return await _authService.resetPassword(email);
  }

  // ✅ Fetch User Profile from Firestore
  Future<void> fetchUserProfile() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists) {
        _userProfile = doc.data();
        notifyListeners(); // ✅ Critical!
      } else {
        print("⚠️ User profile not found in Firestore.");
      }
    }
  } catch (e) {
    print("Fetch User Profile Error: $e");
  }
}


  // ✅ Update Profile (Firestore)
  Future<void> updateUserProfile(String fullName, String phoneNumber) async {
    if (_user != null) {
      await _authService.updateUserProfile(_user!.uid, fullName, phoneNumber);
      await fetchUserProfile();  // Refresh UI
    }
  }

  // ✅ Upload Profile Picture
  Future<void> updateProfilePicture(File imageFile) async {
    if (_user != null) {
      String? imageUrl = await _authService.uploadProfilePicture(_user!.uid, imageFile);
      if (imageUrl != null) {
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
          "profilePic": imageUrl, // ✅ Save image URL in Firestore
        });

        _userProfile?["profilePic"] = imageUrl;
        notifyListeners();
      }
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _userProfile = null;
    notifyListeners();
  }
}
