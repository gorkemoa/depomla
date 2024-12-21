import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/listing_model.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Favori ekleme
  Future<void> addFavorite(String listingId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Kullanıcı giriş yapmamış.");

    final favoriteRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(listingId);

    await favoriteRef.set({
      'listingId': listingId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Favori çıkarma
  Future<void> removeFavorite(String listingId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Kullanıcı giriş yapmamış.");

    final favoriteRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(listingId);

    await favoriteRef.delete();
  }

  /// Belirli bir ilan favori mi kontrol etme
  Future<bool> isFavorite(String listingId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final favoriteRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(listingId);

    final doc = await favoriteRef.get();
    return doc.exists;
  }

  /// Kullanıcının tüm favori ilanlarını çekme
  Future<List<String>> getUserFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final favoritesSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    return favoritesSnapshot.docs.map((doc) => doc.id).toList();
  }
}