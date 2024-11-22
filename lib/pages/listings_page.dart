import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import 'listings_details_page.dart';

class ListingsPage extends StatelessWidget {
  final ListingType category; // Kategori parametresi eklendi

  const ListingsPage({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Firestore'dan kategoriye göre ilanları getir
    Stream<QuerySnapshot<Map<String, dynamic>>> listingsStream =
        FirebaseFirestore.instance
            .collection('listings')
            .where('listingType', isEqualTo: category.name) // Kategori filtresi
            .orderBy('createdAt', descending: true)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category == ListingType.deposit ? 'Depola İlanlar' : 'Depolat İlanlar',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF02aee7),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: listingsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Bir hata oluştu: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF02aee7)),
              ),
            );
          }

          final listings = snapshot.data?.docs
              .map((doc) => Listing.fromDocument(doc))
              .toList();

          if (listings == null || listings.isEmpty) {
            return const Center(
              child: Text(
                'Bu kategoride henüz ilan bulunamadı.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: GridView.builder(
              itemCount: listings.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return ListingCard(listing: listing, category: category);
              },
            ),
          );
        },
      ),
    );
  }
}

class ListingCard extends StatelessWidget {
  final Listing listing;
  final ListingType category;

  const ListingCard({
    Key? key,
    required this.listing,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailPage(listing: listing),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: listing.imageUrl.isNotEmpty
                  ? Image.network(
                      listing.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 160,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 160,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.broken_image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 160,
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Fiyat
                  Text(
                    '${listing.price.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tür ve Konum
                  Row(
                    children: [
                      Icon(
                        category == ListingType.deposit
                            ? Icons.store
                            : Icons.home_work,
                        color: const Color(0xFF1f4985),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          category == ListingType.deposit
                              ? 'Depolamak'
                              : 'Ek Gelir',
                          style: TextStyle(
                            color: category == ListingType.deposit
                                ? const Color(0xFF02aee7)
                                : const Color(0xFF1f4985),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}