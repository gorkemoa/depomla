// lib/pages/listing_page/listings_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/listing_model.dart';
import '../../ads/ad_container.dart';
import 'listing_card.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

class ListingsPage extends StatefulWidget {
  final ListingType category;

  const ListingsPage({Key? key, required this.category}) : super(key: key);

  @override
  _ListingsPageState createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  List<Listing> cachedListings = [];
  bool isGrid = true;
  bool isLoading = true;
  bool isLoadingMore = false;
  DocumentSnapshot? lastDocument;
  bool hasMoreData = true;

  final ScrollController _scrollController = ScrollController();

  static const int _limit = 20;
  static const int _adFrequency = 3; // Her 3 itemde bir reklam göster

  @override
  void initState() {
    super.initState();
    _enableOfflinePersistence();
    fetchListings();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          hasMoreData) {
        fetchListings();
      }
    });
  }

  void _enableOfflinePersistence() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }

  Future<void> fetchListings({bool forceRefresh = false}) async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() {
      if (lastDocument == null) {
        isLoading = true;
      }
      isLoadingMore = lastDocument != null;
    });

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('listings')
          .where('listingType',
              isEqualTo: widget.category.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .limit(_limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      QuerySnapshot<Map<String, dynamic>> snapshot = await query.get(
        forceRefresh ? const GetOptions(source: Source.server) : null,
      );

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          lastDocument = snapshot.docs.last;
          cachedListings
              .addAll(snapshot.docs.map((doc) => Listing.fromDocument(doc)));
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
    setState(() {
      cachedListings.clear();
      lastDocument = null;
      hasMoreData = true;
      isLoading = true;
    });
    await fetchListings(forceRefresh: true);
  }

  bool isAdPosition(int index, int frequency) {
    return (index + 1) % (frequency + 1) == 0;
  }

  int getListingIndex(int index, int frequency) {
    return index - ((index + 1) / (frequency + 1)).floor();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget buildListView() {
    final totalAds = (cachedListings.length / _adFrequency).floor();
    final totalItemCount = cachedListings.length + totalAds;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        if (isAdPosition(index, _adFrequency)) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 9.0),
            child: AdContainer(),
          );
        }
        final listingIndex = getListingIndex(index, _adFrequency);
        if (listingIndex < cachedListings.length) {
          final listing = cachedListings[listingIndex];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListingCard(
              listing: listing,
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget buildGridView() {
    final totalAds = (cachedListings.length / _adFrequency).floor();
    final totalItemCount = cachedListings.length + totalAds;

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      itemCount: totalItemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        if (isAdPosition(index, _adFrequency)) {
          return const AdContainer();
        }
        final listingIndex = getListingIndex(index, _adFrequency);
        if (listingIndex < cachedListings.length) {
          final listing = cachedListings[listingIndex];
          return ListingCard(
            listing: listing,
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget buildListViewOptimized() {
    // Geçişi daha akıcı hale getirmek için AnimatedSwitcher kullanıyoruz
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isGrid ? buildGridView() : buildListView(),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(child: child, opacity: animation);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == ListingType.deposit
              ? 'Depola İlanlar'
              : 'Depolama İlanları',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isGrid ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGrid = !isGrid;
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
                  : buildListViewOptimized(),
            ),
    );
  }
}