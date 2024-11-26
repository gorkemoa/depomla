// lib/pages/manage_listings_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_listing_page.dart';
import 'add_listing_page.dart';

class ManageListingsPage extends StatelessWidget {
  const ManageListingsPage({Key? key}) : super(key: key);

  // İlanları getiren fonksiyon
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchListings(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('listings')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs;
  }

  // İlan Silme fonksiyonu
  Future<void> _deleteListing(String listingId) async {
    await FirebaseFirestore.instance.collection('listings').doc(listingId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanlarımı Yönet'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _fetchListings(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('İlanlar yüklenirken bir hata oluştu.'));
          }
          final listings = snapshot.data!;
          if (listings.isEmpty) {
            return const Center(child: Text('Hiç ilanınız yok.'));
          }
          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index].data();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  leading: listing['imageUrl'] != null && listing['imageUrl'].isNotEmpty
                      ? Image.network(
                          listing['imageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported, size: 50),
                  title: Text(listing['title'] ?? 'Başlık Yok'),
                  subtitle: Text(listing['description'] ?? 'Açıklama Yok'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        // İlanı Düzenleme Sayfasına Yönlendirme
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditListingPage(
                              listingId: listings[index].id,
                              currentData: listing,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        // İlanı Silme
                        bool confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('İlanı Sil'),
                            content: const Text('Bu ilanı silmek istediğinizden emin misiniz?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('İptal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sil'),
                              ),
                            ],
                          ),
                        );
                        if (confirm) {
                          await _deleteListing(listings[index].id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('İlan başarıyla silindi.')),
                          );
                          // Sayfayı yenileme
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ManageListingsPage()),
                          );
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Düzenle'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Sil'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Yeni İlan Ekleme Sayfasına Yönlendirme
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddListingPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }
}