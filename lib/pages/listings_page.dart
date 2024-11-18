// Gerekli paketleri ekleyin
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'listings_details_page.dart';
import 'package:intl/intl.dart';
import 'login_page.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key});

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  // Yeni eklenen değişkenler
  String _selectedCategory = 'Tümü';
  double _searchRadius = 50; // Kilometre cinsinden arama yarıçapı
  List<String> _favoriteListings = []; // Favori ilanların ID'leri

  // Kategoriler listesi
  final List<String> _categories = [
    'Tümü',
    
  ];

  // Filtreleme için güncellenmiş değişkenler
  String _sortOption = 'Fiyat: Düşük - Yüksek'; // Varsayılan sıralama seçeneği
  RangeValues _priceRange = const RangeValues(0, 10000); // Fiyat aralığı

  @override
  void initState() {
    super.initState();
    // Favori ilanları yükle (Eğer kullanıcı oturum açtıysa)
    _loadFavoriteListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  

  // Firestore sorgusunu oluşturma
  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('listings');

    // Kategori filtresi
    if (_selectedCategory != 'Tümü') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    // Arama terimini uygulama
    if (_searchTerm.isNotEmpty) {
      query = query
          .where('search_keywords', arrayContains: _searchTerm.toLowerCase());
    }

    // Fiyat aralığını uygulama
    query = query
        .where('price', isGreaterThanOrEqualTo: _priceRange.start)
        .where('price', isLessThanOrEqualTo: _priceRange.end);

    // Sıralama Seçenekleri
    switch (_sortOption) {
      case 'Fiyat: Düşük - Yüksek':
        query = query.orderBy('price', descending: false);
        break;
      case 'Fiyat: Yüksek - Düşük':
        query = query.orderBy('price', descending: true);
        break;
      default:
        query = query.orderBy('price', descending: false);
    }


    return query;
  }

  // Firestore'dan veri çekme
  Stream<List<QueryDocumentSnapshot>> _getListings() {
    Query query = _buildQuery();

    return query.snapshots().map((snapshot) => snapshot.docs);
  }

  // Filtre panelini açma fonksiyonu
  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Kategori Seçimi
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Sıralama Seçeneği
                DropdownButtonFormField<String>(
                  value: _sortOption,
                  decoration: const InputDecoration(
                    labelText: 'Sıralama',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Fiyat: Düşük - Yüksek',
                    'Fiyat: Yüksek - Düşük',
                  ].map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortOption = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Fiyat Aralığı Seçeneği
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fiyat Aralığı (₺)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 10000,
                      divisions: 100,
                      labels: RangeLabels(
                        _priceRange.start.round().toString(),
                        _priceRange.end.round().toString(),
                      ),
                      onChanged: (values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {}); // Filtreleri uygula
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02aee7),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Uygula'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // Favori ilanları yükleme fonksiyonu
  void _loadFavoriteListings() async {
    // Burada favori ilanları Firestore'dan veya başka bir kaynaktan yükleyebilirsiniz
    // Örneğin:
    /*
    final userId = AuthService().currentUser?.uid;
    if (userId != null) {
      final favsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();
      setState(() {
        _favoriteListings = favsSnapshot.docs.map((doc) => doc.id).toList();
      });
    }
    */
  }

  // İlan kartlarını oluşturma
  Widget _buildListingsGrid(List<QueryDocumentSnapshot> listings) {
    // Eğer arama terimi varsa, listeyi filtrele
    List<QueryDocumentSnapshot> filteredListings = listings;

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final data =
                filteredListings[index].data() as Map<String, dynamic>;
            final List<dynamic>? images = data['images'];
            final listingId = filteredListings[index].id;

            bool isFavorite = _favoriteListings.contains(listingId);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            ListingDetailPage(
                      data: data,
                      listingId: listingId,
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;

                      var tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Stack(
                children: [
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    shadowColor: const Color(0xFF1f4985).withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // İlan Görseli
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20.0),
                            ),
                            child: images != null && images.isNotEmpty
                                ? Image.network(
                                    images.first,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    loadingBuilder:
                                        (context, child, progress) {
                                      if (progress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: const Color(0xFF02aee7),
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                        // İlan Bilgileri
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? 'Başlık Yok',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${data['price'] ?? 0}₺',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF02aee7),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      data['location'] ?? 'Konum Yok',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    data['created_at'] != null
                                        ? DateFormat('yyyy-MM-dd').format(
                                            (data['created_at'] as Timestamp)
                                                .toDate())
                                        : 'Tarih Yok',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
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
                  // Favori Butonu
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        // Favorilere ekleme veya çıkarma işlemi
                        setState(() {
                          if (isFavorite) {
                            _favoriteListings.remove(listingId);
                            // Favorilerden kaldırma işlemi (Firestore'da da güncelle)
                          } else {
                            _favoriteListings.add(listingId);
                            // Favorilere ekleme işlemi (Firestore'da da güncelle)
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: filteredListings.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              MediaQuery.of(context).size.width > 600 ? 3 : 2, // Responsive
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.7,
        ),
      ),
    );
  }

  // Ana gövdeyi oluşturma
  Widget _buildBody() {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _getListings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF02aee7),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bir hata oluştu: ${snapshot.error}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'İlan bulunamadı.',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        }

        final listings = snapshot.data!;

        return _buildListingsGrid(listings);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Çıkış işlemi
              await AuthService().signOut();

              // Çıkış yaptıktan sonra LoginPage'e yönlendirme
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false, // Tüm önceki rotaları kaldır
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _openFilterPanel,
          ),
        ],
        title: const Text(
          'İlanlar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF02aee7),
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            // Kategori seçimi için ek alan
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: _categories.map((category) {
                      bool isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: const Color(0xFF02aee7),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.grey[100],
              automaticallyImplyLeading: false,
              title: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'İlanlarda ara...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchTerm = value.toLowerCase();
                  });
                },
              ),
            ),
            _buildBody(),
          ],
        ),
      ),
    );
  }
}