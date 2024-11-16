import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Yeni ilan ekle
  Future<void> addListing(Map<String, dynamic> listingData) async {
    try {
      await _firestore.collection('listings').add(listingData);
      print('İlan başarıyla eklendi.');
    } catch (e) {
      print('İlan eklenirken hata oluştu: $e');
    }
  }
}
