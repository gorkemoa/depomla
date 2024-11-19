// lib/models/listing_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingType {
  deposit,
  storage,
}

class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String userId;
  final Timestamp createdAt;
  final ListingType listingType;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.userId,
    required this.createdAt,
    required this.listingType,
  });

  factory Listing.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  return Listing(
    id: doc.id,
    title: data['title'] ?? 'Başlıksız',
    description: data['description'] ?? '',
    price: (data['price'] ?? 0).toDouble(),
    imageUrl: data['imageUrl'] ?? '',
    userId: data['userId'] ?? '',
    createdAt: data['createdAt'] ?? Timestamp.now(),
    listingType: (data['listingType'] == 'deposit') ? ListingType.deposit : ListingType.storage,
  );
}

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': createdAt,
      'listingType': listingType == ListingType.deposit ? 'deposit' : 'storage',
    };
  }
}