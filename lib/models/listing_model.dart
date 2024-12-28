// lib/models/listing_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum ListingType { deposit, storage }

class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final List<String> imageUrl;
  final String userId;
  final Timestamp createdAt;
  final ListingType listingType;
  final double? size;
  final String? city;
  final String? district;
  final String? neighborhood;
  final String? storageType;
  final Map<String, bool> features;
  final DateTime? startDate;
  final DateTime? endDate;
  bool isFavorite;
  final String? itemType;
  final Map<String, double>? itemDimensions;
  final double? itemWeight;
  final bool? requiresTemperatureControl;
  final bool? requiresDryEnvironment;
  final bool? insuranceRequired;
  final List<String>? prohibitedConditions;
  final bool? ownerPickup;
  final String? deliveryDetails;
  final String? additionalNotes;
  final List<String>? preferredFeatures;

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
    this.itemType,
    this.itemDimensions,
    this.itemWeight,
    this.requiresTemperatureControl,
    this.requiresDryEnvironment,
    this.insuranceRequired,
    this.prohibitedConditions,
    this.ownerPickup,
    this.deliveryDetails,
    this.additionalNotes,
    this.preferredFeatures,
    this.isFavorite = false,
  });

  // Firestore için
  factory Listing.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    List<String> imageUrls;
    if (data['imageUrl'] is List) {
      imageUrls = List<String>.from(data['imageUrl'] as List<dynamic>);
    } else if (data['imageUrl'] is String) {
      imageUrls = [data['imageUrl'] as String];
    } else {
      imageUrls = [];
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
      startDate: data['startDate'] != null ? Listing.parseDate(data['startDate']) : null,
      endDate: data['endDate'] != null ? Listing.parseDate(data['endDate']) : null,
      itemType: data['itemType']?.toString(),
      itemDimensions: data['itemDimensions'] != null
          ? Map<String, double>.from(
              data['itemDimensions'] as Map<dynamic, dynamic>)
          : null,
      itemWeight: (data['itemWeight'] as num?)?.toDouble(),
      requiresTemperatureControl: data['requiresTemperatureControl'] as bool?,
      requiresDryEnvironment: data['requiresDryEnvironment'] as bool?,
      insuranceRequired: data['insuranceRequired'] as bool?,
      prohibitedConditions: data['prohibitedConditions'] != null
          ? List<String>.from(data['prohibitedConditions'] as List<dynamic>)
          : null,
      ownerPickup: data['ownerPickup'] as bool?,
      deliveryDetails: data['deliveryDetails']?.toString(),
      additionalNotes: data['additionalNotes']?.toString(),
      preferredFeatures: data['preferredFeatures'] != null
          ? List<String>.from(data['preferredFeatures'] as List<dynamic>)
          : null,
    );
  }

  static DateTime? parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      try {
        return DateFormat('dd/MM/yyyy').parse(date);
      } catch (e) {
        print('Tarih parse edilirken hata: $e');
      }
    }
    return null;
  }

  // Realtime Database için
  factory Listing.fromMap(Map<dynamic, dynamic> map, String id) {
    List<String> imageUrls;
    if (map['imageUrl'] is List) {
      imageUrls = List<String>.from(map['imageUrl'] as List<dynamic>);
    } else if (map['imageUrl'] is String) {
      imageUrls = [map['imageUrl'] as String];
    } else {
      imageUrls = [];
    }

    DateTime? parseDate(dynamic date) {
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is String) {
        try {
          return DateFormat('dd/MM/yyyy').parse(date);
        } catch (e) {
          print('Tarih parse edilirken hata: $e');
        }
      }
      return null;
    }

    return Listing(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num).toDouble(),
      imageUrl: imageUrls,
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      listingType: map['listingType'] == 'deposit'
          ? ListingType.deposit
          : ListingType.storage,
      size: (map['size'] as num?)?.toDouble(),
      city: map['city']?.toString(),
      district: map['district']?.toString(),
      neighborhood: map['neighborhood']?.toString(),
      storageType: map['storageType']?.toString(),
      features: map['features'] != null
          ? Map<String, bool>.from(map['features'] as Map<dynamic, dynamic>)
          : {},
      startDate: map['startDate'] != null ? parseDate(map['startDate']) : null,
      endDate: map['endDate'] != null ? parseDate(map['endDate']) : null,
      itemType: map['itemType']?.toString(),
      itemDimensions: map['itemDimensions'] != null
          ? Map<String, double>.from(
              map['itemDimensions'] as Map<dynamic, dynamic>)
          : null,
      itemWeight: (map['itemWeight'] as num?)?.toDouble(),
      requiresTemperatureControl: map['requiresTemperatureControl'] as bool?,
      requiresDryEnvironment: map['requiresDryEnvironment'] as bool?,
      insuranceRequired: map['insuranceRequired'] as bool?,
      prohibitedConditions: map['prohibitedConditions'] != null
          ? List<String>.from(map['prohibitedConditions'] as List<dynamic>)
          : null,
      ownerPickup: map['ownerPickup'] as bool?,
      deliveryDetails: map['deliveryDetails']?.toString(),
      additionalNotes: map['additionalNotes']?.toString(),
      preferredFeatures: map['preferredFeatures'] != null
          ? List<String>.from(map['preferredFeatures'] as List<dynamic>)
          : null,
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
      'size': size,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
      'storageType': storageType,
      'features': features,
      'startDate': startDate,
      'endDate': endDate,
      'itemType': itemType,
      'itemDimensions': itemDimensions,
      'itemWeight': itemWeight,
      'requiresTemperatureControl': requiresTemperatureControl,
      'requiresDryEnvironment': requiresDryEnvironment,
      'insuranceRequired': insuranceRequired,
      'prohibitedConditions': prohibitedConditions,
      'ownerPickup': ownerPickup,
      'deliveryDetails': deliveryDetails,
      'additionalNotes': additionalNotes,
      'preferredFeatures': preferredFeatures,
    };
  }

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
    DateTime? startDate,
    DateTime? endDate,
    String? itemType,
    Map<String, double>? itemDimensions,
    double? itemWeight,
    bool? requiresTemperatureControl,
    bool? requiresDryEnvironment,
    bool? insuranceRequired,
    List<String>? prohibitedConditions,
    bool? ownerPickup,
    String? deliveryDetails,
    String? additionalNotes,
    List<String>? preferredFeatures,
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
      itemType: itemType ?? this.itemType,
      itemDimensions: itemDimensions ?? this.itemDimensions,
      itemWeight: itemWeight ?? this.itemWeight,
      requiresTemperatureControl:
          requiresTemperatureControl ?? this.requiresTemperatureControl,
      requiresDryEnvironment:
          requiresDryEnvironment ?? this.requiresDryEnvironment,
      insuranceRequired: insuranceRequired ?? this.insuranceRequired,
      prohibitedConditions:
          prohibitedConditions ?? this.prohibitedConditions,
      ownerPickup: ownerPickup ?? this.ownerPickup,
      deliveryDetails: deliveryDetails ?? this.deliveryDetails,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      preferredFeatures: preferredFeatures ?? this.preferredFeatures,
    );
  }
factory Listing.fromRTDB(Map<dynamic, dynamic> map, String id) {
    final images = map['imageUrl'] as List? ?? [];
    return Listing(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: images.map((e) => e.toString()).toList(),
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      listingType: map['listingType'] == 'deposit'
          ? ListingType.deposit
          : ListingType.storage,
    );
}
}