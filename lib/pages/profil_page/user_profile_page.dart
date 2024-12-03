// lib/pages/user_profile_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/listing_model.dart';
import '../../models/user_model.dart';
import '../listing_page/listings_details_page.dart';
import '../../services/location_service.dart';

class UserProfilePage extends StatefulWidget {
  final UserModel user;

  const UserProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? cityName;
  String? districtName;
  String? neighborhoodName;
  bool isLoading = true;

  // Konum verilerini önbelleğe almak için haritalar
  final Map<String, String> _citiesMap = {};
  final Map<String, String> _districtsMap = {};
  final Map<String, String> _neighborhoodsMap = {};

  @override
  void initState() {
    super.initState();
    _fetchAllLocations().then((_) {
      _fetchUserLocationNames();
    });
  }

  /// Tüm şehir, ilçe ve mahalle verilerini önbelleğe alır
  Future<void> _fetchAllLocations() async {
    final locationService = LocationService();

    try {
      // Şehirleri getir
      final cities = await locationService.getCities();
      setState(() {
        for (var city in cities) {
          _citiesMap[city.id] = city.sehirAdi;
        }
      });

      // Kullanıcının seçtiği şehre ait ilçeleri getir
      if (widget.user.city != null && widget.user.city!.isNotEmpty) {
        final districts = await locationService.getDistricts(widget.user.city!);
        setState(() {
          for (var district in districts) {
            _districtsMap[district.id] = district.ilceAdi;
          }
        });
      }

      // Kullanıcının seçtiği ilçeye ait mahalleleri getir
      if (widget.user.city != null &&
          widget.user.city!.isNotEmpty &&
          widget.user.district != null &&
          widget.user.district!.isNotEmpty) {
        final neighborhoods = await locationService.getNeighborhoods(
            widget.user.city!, widget.user.district!);
        setState(() {
          for (var neighborhood in neighborhoods) {
            _neighborhoodsMap[neighborhood.id] = neighborhood.mahalleAdi;
          }
        });
      }
    } catch (e) {
      print('Konum verileri yüklenirken hata: $e');
      // Hata durumunda kullanıcıya uygun bir mesaj gösterebilirsiniz.
    }
  }

  /// Kullanıcının konum isimlerini önbellekten alır
  Future<void> _fetchUserLocationNames() async {
    try {
      cityName = _citiesMap[widget.user.city] ?? "Şehir belirtilmemiş";
      districtName =
          _districtsMap[widget.user.district] ?? "İlçe belirtilmemiş";
      neighborhoodName = _neighborhoodsMap[widget.user.neighborhood] ??
          "Mahalle belirtilmemiş";
    } catch (e) {
      print("Hata: $e");
      // Hata durumunda kullanıcıya uygun bir mesaj gösterebilirsiniz.
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Belirli bir koleksiyondan ID'ye karşılık gelen ismi önbellekten alır
  String _getNameFromCache(String collection, String? id) {
    if (id == null || id.isEmpty) return "Belirtilmemiş";
    switch (collection) {
      case 'cities':
        return _citiesMap[id] ?? "Şehir belirtilmemiş";
      case 'districts':
        return _districtsMap[id] ?? "İlçe belirtilmemiş";
      case 'neighborhoods':
        return _neighborhoodsMap[id] ?? "Mahalle belirtilmemiş";
      default:
        return "Belirtilmemiş";
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Arka plan rengini güncelledik
      appBar: AppBar(
        title: Text(
          widget.user.displayName ?? 'Kullanıcı Profili',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF02aee7),
        elevation: 0,
        centerTitle: true, // Başlığı ortaladık
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profil Bilgileri Kartı
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Profil Resmi
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: widget.user.photoURL != null &&
                                    widget.user.photoURL!.isNotEmpty
                                ? NetworkImage(widget.user.photoURL!)
                                : const AssetImage('assets/default_avatar.png')
                                    as ImageProvider,
                          ),
                          const SizedBox(height: 16),
                          // Kullanıcı Adı
                          Text(
                            widget.user.displayName ?? 'Bilinmeyen Kullanıcı',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // E-posta Adresi
                          Text(
                            widget.user.email ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Kullanıcının Konumu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.blueAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$cityName, $districtName, $neighborhoodName',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // İlanlar Başlığı
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Kullanıcının İlanları',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // İlanlar GridView
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestore
                        .collection('listings')
                        .where('userId', isEqualTo: widget.user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Kullanıcının herhangi bir ilanı bulunmamaktadır.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }

                      final listings = snapshot.data!.docs
                          .map((doc) => Listing.fromDocument(doc))
                          .toList();

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listings.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              2, // Ekran boyutuna göre ayarlanabilir
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.7,
                        ),
                        itemBuilder: (context, index) {
                          final listing = listings[index];
                          return GestureDetector(
                            onTap: () {
                              // İlan detaylarına git
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ListingDetailPage(listing: listing),
                                ),
                              );
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // İlan Görseli
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: listing.imageUrl.isNotEmpty
                                        ? Image.network(
                                            listing.imageUrl.isNotEmpty
                                                ? listing.imageUrl.first
                                                : '', // Use the first image
                                            height: 140,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                  height: 140,
                                                  color: Colors.grey.shade300,
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ));
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                height: 140,
                                                color: Colors.grey.shade300,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  size: 80,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            height: 140,
                                            color: Colors.grey.shade300,
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              size: 80,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // İlan Başlığı
                                        Text(
                                          listing.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        // Fiyat
                                        Text(
                                          '${listing.price.toStringAsFixed(2)} ₺',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Konum
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '${_getNameFromCache('cities', listing.city)}, '
                                                '${_getNameFromCache('districts', listing.district)}, '
                                                '${_getNameFromCache('neighborhoods', listing.neighborhood)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
