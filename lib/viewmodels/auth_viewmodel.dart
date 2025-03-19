import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userProfile;  // ✅ Stores Firestore user data

  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;

  // Sign Up
  Future<bool> signUp(String email, String password, String fullName, String phoneNumber) async {
    _user = await _authService.signUp(email, password, fullName, phoneNumber);
    if (_user != null) {
      await fetchUserProfile();
    }
    notifyListeners();
    return _user != null;
  }

  // ✅ Ensure signIn method exists
  Future<bool> signIn(String email, String password) async {
    _user = await _authService.signIn(email, password);
    if (_user != null) {
      await fetchUserProfile();
    }
    notifyListeners();
    return _user != null;
  }

  // ✅ Ensure resetPassword method exists
  Future<bool> resetPassword(String email) async {
    return await _authService.resetPassword(email);
  }

  // ✅ Fetch User Profile from Firestore
  Future<void> fetchUserProfile() async {
    if (_user != null) {
      _userProfile = await _authService.getUserProfile(_user!.uid);
      notifyListeners();
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
        await _authService.updateUserProfile(_user!.uid, _userProfile?["fullName"] ?? "", _userProfile?["phoneNumber"] ?? "");
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
