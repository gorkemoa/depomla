// lib/pages/listing_page/listings_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/listing_model.dart';
import 'listing_card.dart';
import 'listings_details_page.dart';

class ListingsPage extends StatefulWidget {
  final ListingType category;

  const ListingsPage({Key? key, required this.category}) : super(key: key);

  @override
  _ListingsPageState createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  List<Listing> cachedListings = [];
  bool isGrid = true; // Başlangıç görünümü grid
  bool isLoading = true;
  bool isLoadingMore = false; // Daha fazla veri yükleniyor mu?
  DocumentSnapshot? lastDocument; // Son getirilen belge
  bool hasMoreData = true; // Daha fazla veri var mı?

  @override
  void initState() {
    super.initState();
    _enableOfflinePersistence(); // Firestore çevrimdışı desteği etkinleştirildi
    fetchListings();
  }

  void _enableOfflinePersistence() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, // Önbellekleme etkin
    );
  }

  Future<void> fetchListings({bool forceRefresh = false}) async {
    if (isLoadingMore || !hasMoreData) return; // Aynı anda birden fazla yüklemeyi ve gereksiz sorguları önleyin

    setState(() {
      isLoading = lastDocument == null;
      isLoadingMore = lastDocument != null;
    });

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('listings')
          .where('listingType', isEqualTo: widget.category.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .limit(20);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      QuerySnapshot<Map<String, dynamic>> snapshot = await query.get(
        forceRefresh ? const GetOptions(source: Source.server) : null,
      );

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          lastDocument = snapshot.docs.last;
          cachedListings.addAll(snapshot.docs.map((doc) => Listing.fromDocument(doc)).toList());
        });
      } else {
        setState(() {
          hasMoreData = false;
        });
      }
    } catch (e) {
      print('Veri alınırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veri alınırken bir hata oluştu: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> refreshListings() async {
    // Kullanıcı yenileme yaptığında verileri sıfırla ve sunucudan güncel verileri al
    setState(() {
      cachedListings.clear();
      lastDocument = null;
      hasMoreData = true;
    });
    await fetchListings(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == ListingType.deposit
              ? 'Depola İlanlar'
              : 'Depolama İlanları',
        ),
        actions: [
          IconButton(
            icon: Icon(isGrid ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGrid = !isGrid; // Görünümü değiştir
              });
            },
            tooltip: isGrid ? 'Liste Görünümü' : 'Grid Görünümü',
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF02aee7), Color(0xFF00d0ea)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshListings,
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!isLoadingMore &&
                      hasMoreData &&
                      scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                    // Liste sonuna yaklaşıldı, daha fazla veri yükle
                    fetchListings();
                  }
                  return false;
                },
                child: cachedListings.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Bu kategoride henüz ilan bulunamadı.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    : buildListView(),
              ),
            ),
    );
  }

  Widget buildListView() {
    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: cachedListings.length + (hasMoreData ? 1 : 0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
          crossAxisSpacing: 13,
          mainAxisSpacing: 13,
          childAspectRatio: 0.70,
        ),
        itemBuilder: (context, index) {
          if (index == cachedListings.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final listing = cachedListings[index];
          return ListingCard(listing: listing);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: cachedListings.length + (hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == cachedListings.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final listing = cachedListings[index];
          return ListingCard(listing: listing, isList: true);
        },
      );
    }
  }
}