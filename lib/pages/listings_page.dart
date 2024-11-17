// lib/listings_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'listings_details_page.dart';
import 'package:intl/intl.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key});

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  // Filtreleme için güncellenmiş değişkenler
  String _sortOption = 'Fiyat: Düşük - Yüksek'; // Varsayılan sıralama seçeneği
  RangeValues _priceRange = const RangeValues(0, 10000); // Örneğin fiyat aralığı

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Firestore sorgusunu oluşturma
  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('listings');

    // Arama terimini uygulama
    if (_searchTerm.isNotEmpty) {
      query = query
          .where('title', isGreaterThanOrEqualTo: _searchTerm)
          .where('title', isLessThanOrEqualTo: '$_searchTerm\uf8ff');
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
                  child: const Text('Uygula'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02aee7),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // İlan kartlarını oluşturma
  Widget _buildListingsGrid(List<QueryDocumentSnapshot> listings) {
    // Eğer arama terimi varsa, listeyi filtrele
    List<QueryDocumentSnapshot> filteredListings = listings.where((doc) {
      if (_searchTerm.isEmpty) return true;
      String title = (doc['title'] ?? '').toString().toLowerCase();
      return title.contains(_searchTerm);
    }).toList();

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final data =
                filteredListings[index].data() as Map<String, dynamic>;
            final List<dynamic>? images = data['images'];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            ListingDetailPage(
                      data: data,
                      listingId: filteredListings[index].id,
                    ),
                    transitionsBuilder: (context, animation,
                        secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;

                      var tween =
                          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Card(
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
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _openFilterPanel,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            
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
