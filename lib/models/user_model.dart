import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final Timestamp? lastSignIn;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.lastSignIn,
  });

  // Firestore'dan dönen belgeyi UserModel'e dönüştürmek için kullanılan metod
  factory UserModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return UserModel(
      uid: doc.id,
      email: data?['email'] ?? '',
      displayName: data?['displayName'] ?? 'Bilinmeyen Kullanıcı',
      photoURL: data?['photoURL'],
      lastSignIn: data?['lastSignIn'],
    );
  }

  // Firestore'a yazma için nesneyi haritaya dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'lastSignIn': lastSignIn,
    };
  }

  // copyWith metodu
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    Timestamp? lastSignIn,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }
}