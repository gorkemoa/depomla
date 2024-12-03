// lib/models/listing_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing the type of listing
enum ListingType {
  deposit, // For storing personal items
  storage, // For generating extra income by storing items
}

/// Model class representing a listing
class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final List<String> imageUrl; // Supports multiple images
  final String userId;
  final Timestamp createdAt;
  final ListingType listingType;
  final double? size; // Storage size in square meters
  final String? city; // City ID
  final String? district; // District ID
  final String? neighborhood; // Neighborhood ID
  final String? storageType; // Type of storage (e.g., Indoor, Outdoor)
  final Map<String, bool> features; // Security features
  final String? startDate; // Storage start date
  final String? endDate; // Storage end date

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.userId,
    required this.createdAt,
    required this.listingType,
    this.size,
    this.city,
    this.district,
    this.neighborhood,
    this.storageType,
    this.features = const {},
    this.startDate,
    this.endDate,
  });

  /// Factory constructor to create a Listing from a Firestore document
  factory Listing.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // Handle imageUrl being either List<String> or String
    List<String> imageUrls;
    if (data['imageUrl'] is List) {
      imageUrls = List<String>.from(data['imageUrl'] as List<dynamic>);
    } else if (data['imageUrl'] is String) {
      imageUrls = [data['imageUrl'] as String];
    } else {
      imageUrls = []; // Default to empty list if imageUrl is neither List nor String
    }

    return Listing(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num).toDouble(),
      imageUrl: imageUrls,
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      listingType: data['listingType'] == 'deposit'
          ? ListingType.deposit
          : ListingType.storage,
      size: (data['size'] as num?)?.toDouble(),
      city: data['city']?.toString(),
      district: data['district']?.toString(),
      neighborhood: data['neighborhood']?.toString(),
      storageType: data['storageType']?.toString(),
      features: data['features'] != null
          ? Map<String, bool>.from(data['features'] as Map<dynamic, dynamic>)
          : {},
      startDate: data['startDate']?.toString(),
      endDate: data['endDate']?.toString(),
    );
  }

  /// Converts the Listing instance to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': createdAt,
      'listingType': listingType == ListingType.deposit ? 'deposit' : 'storage',
      'size': size,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
      'storageType': storageType,
      'features': features,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  /// Creates a copy of the Listing with updated fields
  Listing copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    List<String>? imageUrl,
    String? userId,
    Timestamp? createdAt,
    ListingType? listingType,
    double? size,
    String? city,
    String? district,
    String? neighborhood,
    String? storageType,
    Map<String, bool>? features,
    String? startDate,
    String? endDate,
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
      size: size ?? this.size,
      city: city ?? this.city,
      district: district ?? this.district,
      neighborhood: neighborhood ?? this.neighborhood,
      storageType: storageType ?? this.storageType,
      features: features ?? this.features,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}