// lib/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String photoURL;
  final Timestamp? lastSignIn;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoURL,
    this.lastSignIn,
  });

  factory UserModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? 'Kullanıcı',
      email: data['email'] ?? '',
      photoURL: data['photoURL'] ?? '',
      lastSignIn: data['lastSignIn'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'lastSignIn': lastSignIn,
    };
  }
}