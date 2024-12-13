// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 Future<void> loadUserData() async {
  if (_isLoading) return; // Prevent multiple concurrent loads
  _isLoading = true;

  final User? user = _auth.currentUser;
  if (user != null) {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromDocument(doc);
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  _isLoading = false;
  notifyListeners();
}

  void updateUserModel(UserModel updatedUser) {
    _userModel = updatedUser;
    notifyListeners();
  }
}