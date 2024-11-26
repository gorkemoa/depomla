import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/listing_model.dart';
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
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;

      if (forceRefresh) {
        // Sunucudan güncel verileri al ve önbelleği güncelle
        snapshot = await FirebaseFirestore.instance
            .collection('listings')
            .where('listingType', isEqualTo: widget.category.toString().split('.').last)
            .orderBy('createdAt', descending: true)
            .get(const GetOptions(source: Source.server));

        setState(() {
          cachedListings = snapshot.docs.map((doc) => Listing.fromDocument(doc)).toList();
        });
      } else {
        // Önce önbellekten veri almaya çalış
        snapshot = await FirebaseFirestore.instance
            .collection('listings')
            .where('listingType', isEqualTo: widget.category.toString().split('.').last)
            .orderBy('createdAt', descending: true)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) {
          // Önbellek boşsa sunucudan veri al
          snapshot = await FirebaseFirestore.instance
              .collection('listings')
              .where('listingType', isEqualTo: widget.category.toString().split('.').last)
              .orderBy('createdAt', descending: true)
              .get();

          setState(() {
            cachedListings = snapshot.docs.map((doc) => Listing.fromDocument(doc)).toList();
          });
        } else {
          // Önbellekteki verileri kullan
          setState(() {
            cachedListings = snapshot.docs.map((doc) => Listing.fromDocument(doc)).toList();
          });
        }
      }
    } catch (e) {
      print('Veri alınırken hata oluştu: $e');
      // Hata durumunda kullanıcıya mesaj gösterebilirsiniz
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> refreshListings() async {
    // Kullanıcı yenileme yaptığında sunucudan güncel verileri alır
    await fetchListings(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == ListingType.deposit
              ? 'Depola İlanlar'
              : 'Depolat İlanlar',
        ),
        actions: [
          IconButton(
            icon: Icon(isGrid ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGrid = !isGrid; // Görünümü değiştir
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshListings,
              child: cachedListings.isEmpty
                  ? const Center(
                      child: Text('Bu kategoride henüz ilan bulunamadı.'),
                    )
                  : isGrid
                      ? buildGridView()
                      : buildListView(),
            ),
    );
  }

  Widget buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: cachedListings.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final listing = cachedListings[index];
        return ListingCard(listing: listing);
      },
    );
  }

  Widget buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: cachedListings.length,
      itemBuilder: (context, index) {
        final listing = cachedListings[index];
        return ListingCard(listing: listing, isList: true);
      },
    );
  }
}

class ListingCard extends StatelessWidget {
  final Listing listing;
  final bool isList;

  const ListingCard({
    Key? key,
    required this.listing,
    this.isList = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Detay sayfasına yönlendirme
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailPage(listing: listing),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: isList ? buildListContent() : buildGridContent(),
      ),
    );
  }

  Widget buildGridContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildImage(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: buildInfo(),
        ),
      ],
    );
  }

  Widget buildListContent() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(12),
          ),
          child: buildImage(width: 120, height: 120),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: buildInfo(),
          ),
        ),
      ],
    );
  }

  Widget buildImage({double width = double.infinity, double height = 150}) {
    return CachedNetworkImage(
      imageUrl: listing.imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }

  Widget buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${listing.price.toStringAsFixed(2)} ₺',
          style: const TextStyle(
            color: Colors.green,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
                        listing.listingType == ListingType.deposit
                            ? 'Depolatmak'
                            : 'Depolamak',
                        style: TextStyle(
                          color: listing.listingType == ListingType.deposit
                              ? Colors.blue
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
      ],
    );
  }
}