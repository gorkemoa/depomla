// lib/pages/my_listings_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:depomla/models/listing_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'listings_details_page.dart';
import '../auth_page/login_page.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({Key? key}) : super(key: key);

  @override
  _MyListingsPageState createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  List<Listing> cachedListings = [];
  bool isLoading = true;
  late User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
    } else {
      _enableOfflinePersistence();
      fetchListings();
    }
  }

  void _enableOfflinePersistence() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }

  Future<void> fetchListings({bool forceRefresh = false}) async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;

      if (forceRefresh) {
        // Sunucudan verileri al ve önbelleği güncelle
        snapshot = await FirebaseFirestore.instance
            .collection('listings')
            .where('userId', isEqualTo: user!.uid)
            .orderBy('createdAt', descending: true)
            .get(const GetOptions(source: Source.server));

        setState(() {
          cachedListings =
              snapshot.docs.map((doc) => Listing.fromDocument(doc)).toList();
        });
      } else {
        // Önce önbellekten veri almaya çalış
        snapshot = await FirebaseFirestore.instance
            .collection('listings')
            .where('userId', isEqualTo: user!.uid)
            .orderBy('createdAt', descending: true)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) {
          // Önbellek boşsa sunucudan veri al
          snapshot = await FirebaseFirestore.instance
              .collection('listings')
              .where('userId', isEqualTo: user!.uid)
              .orderBy('createdAt', descending: true)
              .get();

          setState(() {
            cachedListings =
                snapshot.docs.map((doc) => Listing.fromDocument(doc)).toList();
          });
        } else {
          // Önbellekteki verileri kullan
          setState(() {
            cachedListings =
                snapshot.docs.map((doc) => Listing.fromDocument(doc)).toList();
          });
        }
      }
    } catch (e) {
      print('Veri alınırken hata oluştu: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> refreshListings() async {
    await fetchListings(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kendi İlanlarım'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshListings,
              child: cachedListings.isEmpty
                  ? const Center(child: Text('Hiç ilanınız bulunmuyor.'))
                  : ListView.builder(
                      itemCount: cachedListings.length,
                      itemBuilder: (context, index) {
                        final listing = cachedListings[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: listing.imageUrl.isNotEmpty
                                ? Image.network(
                                    listing
                                        .imageUrl.first, // Use the first image
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
                                    color: listing.listingType ==
                                            ListingType.deposit
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
                                  builder: (context) =>
                                      ListingDetailPage(listing: listing),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
