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

  // New fields for detailed item information
  final String? itemType; // Type of item (e.g., Motorcycle, Furniture)
  final Map<String, double>? itemDimensions; // Dimensions: length, width, height in meters
  final double? itemWeight; // Weight in kg
  final bool? requiresTemperatureControl; // Temperature-sensitive item
  final bool? requiresDryEnvironment; // Requires dry environment (e.g., for electronics)
  final bool? insuranceRequired; // Does the item require insurance?
  final List<String>? prohibitedConditions; // Prohibited conditions for the item
  final bool? ownerPickup; // Will the owner pick up the item from the user?
  final String? deliveryDetails; // Responsibility for item delivery
  final String? additionalNotes; // Additional notes or requirements
  final List<String>? preferredFeatures; // Features the user is looking for (e.g., secure, covered space)

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
    // New fields
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
      startDate: data['startDate']?.toString(),
      endDate: data['endDate']?.toString(),
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
    // New fields
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
}