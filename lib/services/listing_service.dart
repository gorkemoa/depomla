// lib/services/listing_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // İlan oluşturma
  Future<void> createListing(String title, String description, double price, String imageUrl, ListingType listingType) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturum açmamış.');

      Listing newListing = Listing(
        id: '',
        title: title,
        description: description,
        price: price,
        imageUrl: imageUrl,
        userId: user.uid,
        createdAt: Timestamp.now(),
        listingType: listingType,
      );

      await _firestore.collection('listings').add(newListing.toMap());
    } catch (e) {
      print('İlan oluşturulurken hata: $e');
      rethrow;
    }
  }

  // İlan güncelleme
  Future<void> updateListing(String listingId, String title, String description, double price, String imageUrl, ListingType listingType) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturum açmamış.');

      DocumentReference<Map<String, dynamic>> listingRef = _firestore.collection('listings').doc(listingId);

      DocumentSnapshot<Map<String, dynamic>> doc = await listingRef.get();

      if (!doc.exists) throw Exception('İlan bulunamadı.');
      if (doc.data()!['userId'] != user.uid) throw Exception('İlanı güncelleme yetkiniz yok.');

      await listingRef.update({
        'title': title,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'listingType': listingType == ListingType.deposit ? 'deposit' : 'storage',
      });
    } catch (e) {
      print('İlan güncellenirken hata: $e');
      rethrow;
    }
  }

  // İlan silme
  Future<void> deleteListing(String listingId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturum açmamış.');

      DocumentReference<Map<String, dynamic>> listingRef = _firestore.collection('listings').doc(listingId);

      DocumentSnapshot<Map<String, dynamic>> doc = await listingRef.get();

      if (!doc.exists) throw Exception('İlan bulunamadı.');
      if (doc.data()!['userId'] != user.uid) throw Exception('İlanı silme yetkiniz yok.');

      await listingRef.delete();
    } catch (e) {
      print('İlan silinirken hata: $e');
      rethrow;
    }
  }
}