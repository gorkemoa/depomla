// lib/models/district_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class District {
  final String id;
  final String ilceAdi; // 'ilce_adi' alanı
  final String cityId;

  District({required this.id, required this.ilceAdi, required this.cityId});

  factory District.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return District(
      id: doc.id, // Firestore belge kimliğini kullanıyoruz
      ilceAdi: data['ilce_adi'] ?? '',
      cityId: data['cityId'].toString(),
    );
  }
}