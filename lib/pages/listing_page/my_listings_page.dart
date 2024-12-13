// lib/pages/listing_page/my_listings_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/listing_model.dart';
import '../../ads/ad_container.dart';
import '../auth_page/login_page.dart';
import 'listing_card.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({Key? key}) : super(key: key);

  @override
  _MyListingsPageState createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? user;
  bool isLoading = true;
  List<Listing> myListings = [];
  List<Listing> myFavorites = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Kullanıcı giriş yapmamışsa login sayfasına yönlendir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true, // Modal görünüm
            builder: (context) => const LoginPage(),
          ),
        ).then((_) {
          // Kullanıcı login olmadan geri dönerse
          setState(() {
            user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              fetchAllData();
            }
          });
        });
      });
    } else {
      fetchAllData();
    }
  }

  Future<void> fetchAllData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([fetchMyListings(), fetchMyFavorites()]);
    } catch (e) {
      print('Veri alınırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veri alınırken bir hata oluştu: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchMyListings({bool forceRefresh = false}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('listings')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('createdAt', descending: true)
          .get(forceRefresh
              ? const GetOptions(source: Source.server)
              : const GetOptions(source: Source.cache));

      setState(() {
        myListings = snapshot.docs.map((doc) => Listing.fromDocument(doc)).toList();
      });
    } catch (e) {
      print('My Listings veri alınırken hata oluştu: $e');
    }
  }

  Future<void> fetchMyFavorites({bool forceRefresh = false}) async {
    try {
      // Favorilerin saklandığı koleksiyonun adını ve yapısını kontrol edin
      final snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('createdAt', descending: true)
          .get(forceRefresh
              ? const GetOptions(source: Source.server)
              : const GetOptions(source: Source.cache));

      // Favorilere ait listing referanslarını alıp, gerçek listing verilerini çekin
      List<String> favoriteListingIds = snapshot.docs.map((doc) => doc['listingId'] as String).toList();

      if (favoriteListingIds.isNotEmpty) {
        final listingsSnapshot = await FirebaseFirestore.instance
            .collection('listings')
            .where(FieldPath.documentId, whereIn: favoriteListingIds)
            .get();

        setState(() {
          myFavorites = listingsSnapshot.docs.map((doc) => Listing.fromDocument(doc)).toList();
        });
      } else {
        setState(() {
          myFavorites = [];
        });
      }
    } catch (e) {
      print('My Favorites veri alınırken hata oluştu: $e');
    }
  }

  Future<void> refreshData() async {
    await fetchAllData();
  }

  bool isAdPosition(int index, int frequency) {
    // Her `frequency` itemde bir reklam göster
    return (index + 1) % (frequency + 1) == 0;
  }

  int getListingIndex(int index, int frequency) {
    // Reklamların yer aldığı index'leri atlayarak listing index'ini hesapla
    return index - ((index + 1) / (frequency + 1)).floor();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildListingsView() {
    final adFrequency = 3; // Her 5 itemde bir reklam göster
    final totalAds = (myListings.length / adFrequency).floor();
    final totalItemCount = myListings.length + totalAds;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      itemCount: totalItemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 1,
        childAspectRatio: 0.76,
      ),
      itemBuilder: (context, index) {
        if (isAdPosition(index, adFrequency)) {
          return AdContainer(key: UniqueKey()); // Benzersiz bir Key atayın
        }
        final listingIndex = getListingIndex(index, adFrequency);
        if (listingIndex < myListings.length) {
          final listing = myListings[listingIndex];
          return ListingCard(listing: listing);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget buildFavoritesView() {
    final adFrequency = 3; // Her 5 itemde bir reklam göster
    final totalAds = (myFavorites.length / adFrequency).floor();
    final totalItemCount = myFavorites.length + totalAds;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      itemCount: totalItemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 1,
        childAspectRatio: 0.76,
      ),
      itemBuilder: (context, index) {
        if (isAdPosition(index, adFrequency)) {
          return AdContainer(key: UniqueKey()); // Benzersiz bir Key atayın
        }
        final listingIndex = getListingIndex(index, adFrequency);
        if (listingIndex < myFavorites.length) {
          final listing = myFavorites[listingIndex];
          return ListingCard(listing: listing);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kendi İlanlarım'),
          backgroundColor: const Color(0xFF02aee7),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'İlanlarınızı görmek için giriş yapmanız gerekiyor.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kendi İlanlarım & Favorilerim'),
          backgroundColor: const Color(0xFF02aee7),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'İlanlarım'),
              Tab(text: 'Favorilerim'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: refreshData,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    myListings.isEmpty
                        ? const Center(
                            child: Text(
                              'Hiç ilanınız bulunmuyor.',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : buildListingsView(),
                    myFavorites.isEmpty
                        ? const Center(
                            child: Text(
                              'Hiç favoriniz bulunmuyor.',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : buildFavoritesView(),
                  ],
                ),
              ),
      ),
    );
  }
}
 bool isAdPosition(int index, int frequency) {
    return (index + 1) % (frequency + 1) == 0;
  }

  int getListingIndex(int index, int frequency) {
    return index - ((index + 1) / (frequency + 1)).floor();
  }
