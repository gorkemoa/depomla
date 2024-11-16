import 'package:flutter/material.dart';

class ListingDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const ListingDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List<dynamic>? images = data['images'];

    return Scaffold(
      appBar: AppBar(
        title: Text(data['title'] ?? 'Detaylar'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resim Galerisi
              if (images != null && images.isNotEmpty)
                SizedBox(
                  height: 250,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Başlık ve Fiyat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['title'] ?? 'Başlık Yok',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${data['price'] ?? 0}₺',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Colors.grey),
              // Açıklama
              Text(
                'Açıklama:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data['description'] ?? 'Açıklama Yok',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const Divider(height: 32, color: Colors.grey),
              // Konum
              if (data['location'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Konum:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['location'],
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const Divider(height: 32, color: Colors.grey),
                  ],
                ),
              // Tür
              Text(
                'Tür: ${data['type'] ?? 'Bilinmiyor'}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const Divider(height: 32, color: Colors.grey),
              // Tarih Aralığı
              if (data['available_from'] != null && data['available_until'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mevcut Tarih:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateTime.fromMillisecondsSinceEpoch(data['available_from'].seconds * 1000).toLocal()} - '
                      '${DateTime.fromMillisecondsSinceEpoch(data['available_until'].seconds * 1000).toLocal()}',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              // İletişim veya İşlem Butonları
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // İşlem veya iletişim
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('İletişime geçildi.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'İletişime Geç',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
