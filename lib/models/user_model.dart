// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final Timestamp? lastSignIn;
  final String city;         // Şehir ID'si
  final String district;     // İlçe ID'si
  final String neighborhood; // Mahalle ID'si

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.lastSignIn,
    this.city = "Seçilmemiş",
    this.district = "Seçilmemiş",
    this.neighborhood = "Seçilmemiş",
  });

  factory UserModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Bilinmeyen Kullanıcı',
      photoURL: data['photoURL'],
      lastSignIn: data['lastSignIn'],
      city: data['city'] ?? 'Seçilmemiş',
      district: data['district'] ?? 'Seçilmemiş',
      neighborhood: data['neighborhood'] ?? 'Seçilmemiş',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'lastSignIn': lastSignIn,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
    };
  }

  UserModel copyWith({
    String? email,
    String? displayName,
    String? photoURL,
    Timestamp? lastSignIn,
    String? city,
    String? district,
    String? neighborhood,
  }) {
    return UserModel(
      uid: this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      city: city ?? this.city,
      district: district ?? this.district,
      neighborhood: neighborhood ?? this.neighborhood,
    );
  }
}