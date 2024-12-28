// lib/pages/listing_page/listings_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/listing_model.dart';
import '../../ads/ad_container.dart';
import 'filter_modal.dart';
import 'listing_card.dart';

class ListingsPage extends StatefulWidget {
  final ListingType category;

  const ListingsPage({Key? key, required this.category}) : super(key: key);

  @override
  _ListingsPageState createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  final ScrollController _scrollController = ScrollController();

  List<Listing> cachedListings = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  DocumentSnapshot? lastDocument;
  bool isGrid = true;

  String searchQuery =  '';
  double? minPrice;
  double? maxPrice;
  String? selectedItemType;
  String? selectedStorageType;

  static const int _limit = 20;
  static const int _adFrequency = 5; // Reklam gösterim sıklığı 
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
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: true);
  }

  Future<void> fetchListings({bool forceRefresh = false}) async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() {
      if (lastDocument == null) isLoading = true;
      isLoadingMore = lastDocument != null;
    });

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('listings')
          .where('listingType',
              isEqualTo: widget.category.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .limit(_limit);

      // Filtreler
      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }

      if (selectedItemType != null && selectedItemType!.isNotEmpty) {
        query = query.where('itemType', isEqualTo: selectedItemType);
      }

      if (selectedStorageType != null && selectedStorageType!.isNotEmpty) {
        query = query.where('storageType', isEqualTo: selectedStorageType);
      }

      // Arama
      if (searchQuery.isNotEmpty) {
        query = query
            .orderBy('title')
            .startAt([searchQuery]).endAt([searchQuery + '\uf8ff']);
      }

      if (lastDocument != null) query = query.startAfterDocument(lastDocument!);

      final snapshot = await query
          .get(forceRefresh ? const GetOptions(source: Source.server) : null);

      if (snapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            lastDocument = snapshot.docs.last;
            cachedListings
                .addAll(snapshot.docs.map((doc) => Listing.fromDocument(doc)));
          });
        }
      } else {
        if (mounted) {
          setState(() {
            hasMoreData = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri alınırken hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> refreshListings() async {
    if (!mounted) return;
    setState(() {
      cachedListings.clear();
      lastDocument = null;
      hasMoreData = true;
      isLoading = true;
    });
    await fetchListings(forceRefresh: true);
  }

  void resetAndFetch() {
    if (!mounted) return;
    setState(() {
      cachedListings.clear();
      lastDocument = null;
      hasMoreData = true;
      isLoading = true;
    });
    fetchListings(forceRefresh: true);
  }

  bool isAdPosition(int index, int frequency) {
    return (index + 1) % (frequency + 1) == 0;
  }

  int getListingIndex(int index, int frequency) {
    return index - ((index + 1) / (frequency + 1)).floor();
  }

  Widget buildListView() {
    final totalAds = (cachedListings.length / _adFrequency).floor();
    final totalItemCount = cachedListings.length + totalAds;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
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
            child: ListingCard(listing: listing),
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      itemCount: totalItemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: MediaQuery.of(context).size.width < 600 ? 0.68 : 0.7,
      ),
      itemBuilder: (context, index) {
        if (isAdPosition(index, _adFrequency)) {
          return const AdContainer();
        }
        final listingIndex = getListingIndex(index, _adFrequency);
        if (listingIndex < cachedListings.length) {
          final listing = cachedListings[listingIndex];
          return ListingCard(listing: listing);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget buildListViewOptimized() {
    // AnimatedSwitcher kaldırıldı ve doğrudan koşullu render yapıldı
    return isGrid ? buildGridView() : buildListView();
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        color: Color(0xFF2196F3),
      ));
    } else if (cachedListings.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Aradığınız kriterlerde ilan bulunamadı.',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return RefreshIndicator(
        color: const Color(0xFF2196F3),
        onRefresh: refreshListings,
        child: buildListViewOptimized(),
      );
    }
  }

  void _openFilterSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilterPage(
          minPrice: minPrice,
          maxPrice: maxPrice,
          selectedItemType: selectedItemType,
          selectedStorageType: selectedStorageType,
          onApply: (newMin, newMax, newItemType, newStorageType) {
            if (mounted) {
              setState(() {
                minPrice = newMin;
                maxPrice = newMax;
                selectedItemType = newItemType;
                selectedStorageType = newStorageType;
              });
              resetAndFetch();
            }
          },
        ),
      ),
    );
  }

  Widget _buildTopBarElements() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height:69), // Üstten daha küçük bir boşluk
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            onChanged: (value) => searchQuery = value.trim(),
            onSubmitted: (_) => resetAndFetch(),
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Başlık ile ara...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 5),
            ),
          ),
        ),
      ],
    );
  }

  Color get _appBarColor => const Color(0xFF2196F3);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              titleSpacing: 16,
              title: Text(
                widget.category == ListingType.deposit
                    ? 'Depola İlanları'
                    : 'Depotlama İlanları',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              pinned: true,
              floating: true,
              expandedHeight: 92, // Arama çubuğuna yeterli alan tanındı
              backgroundColor: _appBarColor,
              actions: [
                IconButton(
                  icon: Icon(
                      isGrid
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      color: Colors.white),
                  onPressed: () => setState(() => isGrid = !isGrid),
                  tooltip: isGrid ? 'Liste Görünümü' : 'Grid Görünümü',
                ),
                IconButton(
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                  onPressed: _openFilterSheet,
                  tooltip: 'Filtreler',
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildTopBarElements(),
                ),
              ),
            ),
          ];
        },
        body: _buildBody(),
      ),
    );
  }
}