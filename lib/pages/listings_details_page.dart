import 'package:flutter/material.dart';

class ListingDetailPage extends StatelessWidget {
  final String listingId;
  final Map<String, dynamic> data;

  const ListingDetailPage({
    Key? key,
    required this.listingId,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<dynamic>? images = data['images'];
    final String title = data['title'] ?? 'Detaylar';
    final String description = data['description'] ?? 'Açıklama Yok';
    final String location = data['location'] ?? 'Konum Yok';
    final double price = (data['price'] ?? 0).toDouble();
    final String date = "14 Kasım 2024"; // Örnek tarih, Firestore'dan dinamik olarak alınabilir

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF02AEE7),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Paylaşma fonksiyonu
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Favorilere ekleme fonksiyonu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Resim galerisi
          if (images != null && images.isNotEmpty)
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.grey),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '1/${images.length}', // Dinamik olarak resim sayısı
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          // Fiyat ve başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${price.toStringAsFixed(0)} TL',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Color(0xFF02AEE7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1),
          // Açıklama
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'İlan Açıklaması',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Alt butonlar
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Sohbet açma işlemi
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Sohbet',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Arama işlemi
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Ara',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}