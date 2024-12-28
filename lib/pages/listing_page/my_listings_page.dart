// lib/pages/comment_page/my_listings_page.dart

import 'package:depomla/pages/listing_page/listing_card.dart'; // ListingCard widget'ını içe aktar
import 'package:depomla/pages/listing_page/listings_details_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/listing_model.dart';
import '../../ads/ad_container.dart';
import '../../services/favorite_service.dart';
import '../auth_page/login_page.dart';
import 'edit_listing_page.dart'; // Düzenleme sayfasını içe aktar

/// MyListingsPage, kullanıcının kendi ilanlarını ve favori ilanlarını görüntüler.
class MyListingsPage extends StatefulWidget {
  const MyListingsPage({Key? key}) : super(key: key);

  @override
  _MyListingsPageState createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // Sekmeleri kontrol etmek için
  User? user; // Mevcut kullanıcı bilgisi
  bool isLoading = true; // Veri yükleniyor mu?
  List<Listing> myListings = []; // Kullanıcının ilanları
  List<Listing> myFavorites = []; // Kullanıcının favori ilanları

  final FavoriteService _favoriteService = FavoriteService(); // Favori hizmeti

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 sekmeli TabController
    user = FirebaseAuth.instance.currentUser; // Mevcut kullanıcıyı al

    if (user == null) {
      // Kullanıcı giriş yapmamışsa login sayfasını modal olarak aç
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true, // Modal görünüm
            builder: (context) => const LoginPage(),
          ),
        ).then((_) {
          // Kullanıcı giriş yaptıktan sonra verileri çek
          setState(() {
            user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              fetchAllData();
            }
          });
        });
      });
    } else {
      fetchAllData(); // Kullanıcı giriş yapmışsa verileri çek
    }
  }

  /// Tüm verileri çeker (ilanlar ve favoriler)
  Future<void> fetchAllData() async {
    setState(() {
      isLoading = true; // Yükleniyor göstergesini başlat
    });

    try {
      await Future.wait([fetchMyListings(), fetchMyFavorites()]); // Paralel olarak verileri çek
    } catch (e) {
      print('Veri alınırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veri alınırken bir hata oluştu: $e')),
      );
    } finally {
      setState(() {
        isLoading = false; // Yüklenme tamamlandı
      });
    }
  }

  /// Kullanıcının kendi ilanlarını çeker
  Future<void> fetchMyListings({bool forceRefresh = false}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('listings')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('createdAt', descending: true)
          .get(forceRefresh
              ? const GetOptions(source: Source.server) // Sunucudan veriyi zorla al
              : const GetOptions(source: Source.cache)); // Önbellekten al

      setState(() {
        myListings =
            snapshot.docs.map((doc) => Listing.fromDocument(doc)).toList();
      });
    } catch (e) {
      print('My Listings veri alınırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İlanlar alınırken hata oluştu: $e')),
      );
    }
  }

  /// Kullanıcının favori ilanlarını çeker
  Future<void> fetchMyFavorites({bool forceRefresh = false}) async {
    try {
      // Kullanıcının favori ilanlarını al
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .orderBy('createdAt', descending: true)
          .get(forceRefresh
              ? const GetOptions(source: Source.server) // Sunucudan veriyi zorla al
              : const GetOptions(source: Source.cache)); // Önbellekten al

      // Favorilere ait listing referanslarını alıp, gerçek listing verilerini çek
      List<String> favoriteListingIds =
          snapshot.docs.map((doc) => doc.id).toList();

      if (favoriteListingIds.isNotEmpty) {
        final listingsSnapshot = await FirebaseFirestore.instance
            .collection('listings')
            .where(FieldPath.documentId, whereIn: favoriteListingIds)
            .get();

        setState(() {
          myFavorites =
              listingsSnapshot.docs.map((doc) => Listing.fromDocument(doc)).toList();
        });
      } else {
        setState(() {
          myFavorites = [];
        });
      }
    } catch (e) {
      print('My Favorites veri alınırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favoriler alınırken hata oluştu: $e')),
      );
    }
  }

  /// Verileri yenilemek için pull-to-refresh özelliği
  Future<void> refreshData() async {
    await fetchAllData();
  }

  /// Belirli bir index'te reklam olup olmadığını kontrol eder
  bool isAdPosition(int index, int frequency) {
    // Her `frequency` itemde bir reklam göster
    return (index + 1) % (frequency + 1) == 0;
  }

  /// Reklamların yer aldığı index'leri atlayarak listing index'ini hesaplar
  int getListingIndex(int index, int frequency) {
    return index - ((index + 1) / (frequency + 1)).floor();
  }

  @override
  void dispose() {
    _tabController.dispose(); // TabController'ı temizle
    super.dispose();
  }

  /// İlan listesi görünümünü oluşturur
  Widget buildListingsView() {
  final adFrequency = 3; // Her 3 itemde bir reklam göster
  final totalAds = (myListings.length / adFrequency).floor();
  final totalItemCount = myListings.length + totalAds;

  return GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
    itemCount: totalItemCount,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.7,
    ),
    itemBuilder: (context, index) {
      if (isAdPosition(index, adFrequency)) {
        return const AdContainer(); // Reklam widget'ı
      }
      final listingIndex = getListingIndex(index, adFrequency);
      if (listingIndex < myListings.length) {
        final listing = myListings[listingIndex];
        return ListingCard(
          listing: listing,
          isEditable: true, // Düzenleme butonunu açıyoruz
        );
      } else {
        return const SizedBox.shrink();
      }
    },
  );
}
  /// Favori ilanlar listesi görünümünü oluşturur
  Widget buildFavoritesView() {
    final adFrequency = 3; // Her 3 itemde bir reklam göster
    final totalAds = (myFavorites.length / adFrequency).floor();
    final totalItemCount = myFavorites.length + totalAds;

    return GridView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      itemCount: totalItemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            MediaQuery.of(context).size.width < 600 ? 2 : 3, // Ekran genişliğine göre sütun sayısı
        crossAxisSpacing: 8, // Çapraz eksen boşluğu
        mainAxisSpacing: 8, // Ana eksen boşluğu
        childAspectRatio: 0.7, // Çocukların oranı
      ),
      itemBuilder: (context, index) {
        if (isAdPosition(index, adFrequency)) {
          return const AdContainer(); // Reklam widget'ı
        }
        final listingIndex = getListingIndex(index, adFrequency);
        if (listingIndex < myFavorites.length) {
          final listing = myFavorites[listingIndex];
          return GestureDetector(
            onTap: () => _showOptions(context, listing), // İlan seçildiğinde seçenekleri göster
            child: ListingCard(
              listing: listing,
            ),
          );
        } else {
          return const SizedBox.shrink(); // Boş widget
        }
      },
    );
  }

  /// Seçenekler menüsünü gösterir (Görüntüle, Düzenle, Sil)
  void _showOptions(BuildContext context, Listing listing) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              // İlanı Görüntüle
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Görüntüle'),
                onTap: () {
                  Navigator.pop(ctx);
                  _viewListing(context, listing); // İlanı görüntüle
                },
              ),
              // İlanı Düzenle
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Düzenle'),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToEditPage(context, listing); // İlanı düzenle
                },
              ),
              // İlanı Sil
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Sil',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, listing.id); // İlanı silmek için onay al
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// İlanı görüntüleme sayfasına yönlendirir
  void _viewListing(BuildContext context, Listing listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingDetailPage(listing: listing),
      ),
    );
  }

  /// Düzenleme sayfasına yönlendirir
  void _navigateToEditPage(BuildContext context, Listing listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditListingPage(
          listingId: listing.id,
          currentData: listing.toMap(),
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Güncelleme başarılıysa verileri yenile
        fetchAllData();
      }
    });
  }

  /// Silme işlemi için onay alır ve ilanı siler
  void _confirmDelete(BuildContext context, String listingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İlanı Sil'),
        content: const Text('Bu ilanı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteListing(listingId); // Onaylanmışsa ilanı sil
    }
  }

  /// İlan silme işlemini gerçekleştirir
  Future<void> _deleteListing(String listingId) async {
    try {
      await FirebaseFirestore.instance.collection('listings').doc(listingId).delete();

      // Eğer favorilerde de bu ilan varsa, onları da sil
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .where(FieldPath.documentId, isEqualTo: listingId)
          .get();

      for (var doc in favoritesSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('favorites')
            .doc(doc.id)
            .delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan başarıyla silindi.')),
      );
      fetchAllData(); // Verileri yenile
    } catch (e) {
      print('İlan silinirken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İlan silinirken bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      // Kullanıcı giriş yapmamışsa giriş yapma ekranını göster
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kendi İlanlarım'),
          backgroundColor: const Color(0xFF02aee7),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'İlanlarınızı görmek için giriş yapmanız gerekiyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => const LoginPage(),
                      ),
                    ).then((_) {
                      setState(() {
                        user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          fetchAllData();
                        }
                      });
                    });
                  },
                  child: const Text('Giriş Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2, // İki sekmeli TabController
      child: Scaffold(
        appBar: AppBar(
          title: const Text('İlanlarım & Favorilerim'),
          backgroundColor: const Color(0xFF02aee7),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'İlanlarım'),
              Tab(text: 'Favorilerim'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator()) // Yükleniyor göstergesi
            : RefreshIndicator(
                onRefresh: refreshData, // Pull-to-refresh özelliği
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    myListings.isEmpty
                        ? const Center(
                            child: Text(
                              'Hiç ilanınız bulunmuyor.',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : buildListingsView(), // İlanlarım sekmesi
                    myFavorites.isEmpty
                        ? const Center(
                            child: Text(
                              'Hiç favoriniz bulunmuyor.',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : buildFavoritesView(), // Favorilerim sekmesi
                  ],
                ),
              ),
      ),
    );
  }
}