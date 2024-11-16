class ListingModel {
  final String title;
  final String description;
  final double price;

  ListingModel({
    required this.title,
    required this.description,
    required this.price,
  });

  // Firestore'dan veri alma
  factory ListingModel.fromFirestore(Map<String, dynamic> data) {
    return ListingModel(
      title: data['title'] ?? 'Başlık Yok',
      description: data['description'] ?? 'Açıklama Yok',
      price: (data['price'] ?? 0).toDouble(),
    );
  }
}
