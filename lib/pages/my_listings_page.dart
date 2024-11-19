// lib/pages/my_listings_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:depomla/models/listing_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'listings_details_page.dart';
import 'login_page.dart'; // Giriş sayfanızın doğru dosya adını kullandığınızdan emin olun

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Kullanıcının oturum açmış olup olmadığını kontrol edin
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Kullanıcı oturum açmamışsa, giriş sayfasına yönlendir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Firestore sorgusunu kullanıcı ID'sine göre filtrele ve doğru türde yapın
    Stream<QuerySnapshot<Map<String, dynamic>>> myListingsStream =
        FirebaseFirestore.instance
            .collection('listings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kendi İlanlarım'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: myListingsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final listings = snapshot.data!.docs
              .map((doc) => Listing.fromDocument(doc))
              .toList();

          // Konsolda ilan sayısını kontrol edin
          print('Number of listings: ${listings.length}');

          if (listings.isEmpty) {
            return const Center(child: Text('Hiç ilanınız bulunmuyor.'));
          }

          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: listing.imageUrl.isNotEmpty
                      ? Image.network(
                          listing.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(listing.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${listing.price} ₺'),
                      Text(
                        listing.listingType == ListingType.deposit
                            ? 'Eşyalarını Depolamak'
                            : 'Ek Gelir için Eşya Depolamak',
                        style: TextStyle(
                          color: listing.listingType == ListingType.deposit
                              ? Colors.blue
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListingDetailPage(listing: listing),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}