import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/listing_model.dart';

class ListingPickerBottomSheet extends StatelessWidget {
  const ListingPickerBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Container(
        height: 200,
        color: Colors.white,
        child: const Center(
          child: Text('Giriş yapmanız gerekiyor.', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    final listingsRef = FirebaseDatabase.instance.ref('listings');

    // Kendi ilanlarını çekeceksek, RTDB’de “listings/{listingId}/userId == currentUser.uid” gibi bir kural
    // RTDB’de “where userId == currentUser.uid” tam sorgu yok, 
    // ya client-side filtreleme veya listings’i çekip filtreleyebiliriz.

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kendi İlanlarınızı Seçin (RTDB)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: listingsRef.onValue,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return const Center(child: Text('İlanlar yüklenirken hata oluştu.'));
                }
                if (!snap.hasData || snap.data!.snapshot.value == null) {
                  return const Center(child: Text('Henüz ilan yok.'));
                }

                final listingsMap = snap.data!.snapshot.value as Map<dynamic, dynamic>;
                final List<Listing> listings = [];

                listingsMap.forEach((key, value) {
                  final listingMap = value as Map;
                  // client-side filtre: userId == currentUser.uid
                  if (listingMap['userId'] == currentUser.uid) {
                    final listingObj = Listing.fromRTDB(listingMap, key);
                    listings.add(listingObj);
                  }
                });

                if (listings.isEmpty) {
                  return const Center(child: Text('Henüz kendi ilanınız yok.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context, listing);
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: CachedNetworkImage(
                                  imageUrl: listing.imageUrl.first,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(Icons.image, color: Colors.white70, size: 40),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: Colors.white70, size: 40),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                listing.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                '${listing.price} ₺',
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}