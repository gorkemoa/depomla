import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import 'listings_details_page.dart'; // Doğru import

class UserProfilePage extends StatelessWidget {
  final UserModel user;

  const UserProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Arka plan rengini güncelledik
      appBar: AppBar(
        title: Text(
          user.displayName ?? 'Kullanıcı Profili',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF02aee7),
        elevation: 0,
        centerTitle: true, // Başlığı ortaladık
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profil Bilgileri Kartı
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 5,
              shadowColor: Colors.black26,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Profil Resmi
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                          ? NetworkImage(user.photoURL!)
                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                    const SizedBox(height: 16),
                    // Kullanıcı Adı
                    Text(
                      user.displayName ?? 'Bilinmeyen Kullanıcı',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // E-posta Adresi
                    Text(
                      user.email ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Mesaj Gönder Butonu
               
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // İlanlar Başlığı
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Kullanıcının İlanları',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // İlanlar GridView
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('listings')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Kullanıcının herhangi bir ilanı bulunmamaktadır.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final listings = snapshot.data!.docs
                    .map((doc) => Listing.fromDocument(doc))
                    .toList();

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: listings.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Ekran boyutuna göre ayarlanabilir
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return GestureDetector(
                      onTap: () {
                        // İlan detaylarına git
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ListingDetailPage(listing: listing),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // İlan Görseli
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: listing.imageUrl.isNotEmpty
                                  ? Image.network(
                                      listing.imageUrl,
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          height: 140,
                                          color: Colors.grey.shade300,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 140,
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
                                      height: 140,
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // İlan Başlığı
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
                                  const SizedBox(height: 6),
                                  // Konum
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                      'Konum belirtilmemiş',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
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
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

 
}