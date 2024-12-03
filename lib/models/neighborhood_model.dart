// lib/models/neighborhood_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Neighborhood {
  final String id;
  final String mahalleAdi; // 'mahalle_adi' alanı
  final String districtId;

  Neighborhood({required this.id, required this.mahalleAdi, required this.districtId});

  factory Neighborhood.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Neighborhood(
      id: doc.id, // Firestore belge kimliğini kullanıyoruz
      mahalleAdi: data['mahalle_adi'] ?? '',
      districtId: data['districtId'].toString(),
    );
  }
}