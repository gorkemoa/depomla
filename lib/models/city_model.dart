// lib/models/city_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class City {
  final String id;
  final String sehirAdi; // 'sehir_adi' alanı

  City({required this.id, required this.sehirAdi});

  factory City.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return City(
      id: doc.id, // Firestore belge kimliğini kullanıyoruz
      sehirAdi: data['sehir_adi'] ?? '',
    );
  }
}