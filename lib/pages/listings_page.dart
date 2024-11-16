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
  String _sortOption = 'Fiyat: Düşük - Yüksek'; // Varsayılan sıralama seçeneği
  RangeValues _priceRange = const RangeValues(0, 10000);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('listings');

    if (_searchTerm.isNotEmpty) {
      query = query
          .where('title', isGreaterThanOrEqualTo: _searchTerm)
          .where('title', isLessThanOrEqualTo: '$_searchTerm\uf8ff');
    }

    query = query
        .where('price', isGreaterThanOrEqualTo: _priceRange.start)
        .where('price', isLessThanOrEqualTo: _priceRange.end);

    switch (_sortOption) {
      case 'Fiyat: Düşük - Yüksek':
        query = query.orderBy('price', descending: false);
        break;
      case 'Fiyat: Yüksek - Düşük':
        query = query.orderBy('price', descending: true);
        break;
    }

    return query;
  }

  Stream<List<QueryDocumentSnapshot>> _getListings() {
    return _buildQuery().snapshots().map((snapshot) => snapshot.docs);
  }

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _sortOption,
                decoration: const InputDecoration(labelText: 'Sıralama'),
                items: [
                  'Fiyat: Düşük - Yüksek',
                  'Fiyat: Yüksek - Düşük',
                ].map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortOption = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
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
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('Filtreyi Uygula'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListingsGrid(List<QueryDocumentSnapshot> listings) {
    List<QueryDocumentSnapshot> filteredListings = listings.where((doc) {
      if (_searchTerm.isEmpty) return true;
      String title = (doc['title'] ?? '').toString().toLowerCase();
      return title.contains(_searchTerm);
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: filteredListings.length,
      itemBuilder: (context, index) {
        final data = filteredListings[index].data() as Map<String, dynamic>;
        final images = data['images'] ?? [];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListingDetailPage(
                  data: data,
                  listingId: filteredListings[index].id,
                ),
              ),
            );
          },
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: images.isNotEmpty
                      ? Image.network(images.first, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'] ?? 'Başlık Yok'),
                      Text('${data['price']}₺'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterPanel,
          ),
        ],
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: _getListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('İlan bulunamadı.'));
          }

          return _buildListingsGrid(snapshot.data!);
        },
      ),
    );
  }
}
