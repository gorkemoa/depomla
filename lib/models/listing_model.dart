import 'package:cloud_firestore/cloud_firestore.dart';

/// İlan türlerini temsil eden enum
enum ListingType {
  deposit, // Eşyalarını depolamak için
  storage, // Ek gelir için eşya depolamak için
}

/// İlan modelini temsil eden sınıf
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

  /// Firestore'dan veri almak için fabrika metodu
  factory Listing.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Listing(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      listingType: data['listingType'] == 'deposit'
          ? ListingType.deposit
          : ListingType.storage,
    );
  }

  /// Firestore'a veri yazmak için harita dönüşümü
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

  /// `copyWith` metodu, mevcut nesneyi değiştirmek için
  Listing copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? imageUrl,
    String? userId,
    Timestamp? createdAt,
    ListingType? listingType,
  }) {
    return Listing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      listingType: listingType ?? this.listingType,
    );
  }
}