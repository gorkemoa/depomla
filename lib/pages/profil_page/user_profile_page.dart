// lib/pages/user_page/user_profile_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../ads/ad_container.dart';
import '../../ads/banner_ad_example.dart';
import '../../models/listing_model.dart';
import '../../models/user_model.dart';
import '../listing_page/listings_details_page.dart';
import '../listing_page/add_listing_page.dart';
import '../../services/location_service.dart';
import '../auth_page/login_page.dart';

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
  bool isError = false;
  String errorMessage = '';

  // Konum verilerini önbelleğe almak için haritalar
  final Map<String, String> _citiesMap = {};
  final Map<String, String> _districtsMap = {};
  final Map<String, String> _neighborhoodsMap = {};

  // Kullanıcının ilanları
  List<Listing> userListings = [];

  @override
  void initState() {
    super.initState();
     _initializeAds();
    _initializeProfile();
  }

  /// Initialize profile by fetching all necessary data in parallel
  Future<void> _initializeProfile() async {
    setState(() {
      isLoading = true;
      isError = false;
      errorMessage = '';
    });

    try {
      await Future.wait([
        _fetchAllLocations(),
        _fetchUserListings(),
      ]);

      _fetchUserLocationNames();
    } catch (e) {
      setState(() {
        isError = true;
        errorMessage = 'Profil yüklenirken bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _initializeAds() async {
    await GlobalAdsService().initialize();
    // Reklamları önceden yüklemeye gerek yok; AdContainer kendi içinde yükler
  }
  /// Fetch and cache all location data
  Future<void> _fetchAllLocations() async {
    final locationService = LocationService();

    try {
      // Şehirleri getir
      final cities = await locationService.getCities();
      for (var city in cities) {
        _citiesMap[city.id] = city.sehirAdi;
      }

      // Kullanıcının seçtiği şehre ait ilçeleri getir
      if (widget.user.city != null &&
          widget.user.city.isNotEmpty &&
          widget.user.city != 'Seçilmemiş') {
        final districts = await locationService.getDistricts(widget.user.city);
        for (var district in districts) {
          _districtsMap[district.id] = district.ilceAdi;
        }
      }

      // Kullanıcının seçtiği ilçeye ait mahalleleri getir
      if (widget.user.district != null &&
          widget.user.district.isNotEmpty &&
          widget.user.district != 'Seçilmemiş') {
        final neighborhoods = await locationService.getNeighborhoods(
            widget.user.city, widget.user.district);
        for (var neighborhood in neighborhoods) {
          _neighborhoodsMap[neighborhood.id] = neighborhood.mahalleAdi;
        }
      }
    } catch (e) {
      throw Exception('Konum verileri yüklenirken hata: $e');
    }
  }

  /// Retrieve user's location names from cached data
  void _fetchUserLocationNames() {
    cityName = _citiesMap[widget.user.city] ?? "Şehir belirtilmemiş";
    districtName = _districtsMap[widget.user.district] ?? "İlçe belirtilmemiş";
    neighborhoodName =
        _neighborhoodsMap[widget.user.neighborhood] ?? "Mahalle belirtilmemiş";
  }

  /// Fetch all listings of the user
  Future<void> _fetchUserListings() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('listings')
          .where('userId', isEqualTo: widget.user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      userListings = snapshot.docs
          .map((doc) => Listing.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Kullanıcı ilanları alınırken hata: $e');
    }
  }

  /// Refresh profile data
  Future<void> _refreshProfile() async {
    await _initializeProfile();
  }

  /// Loading indicator with improved UI
  Widget _buildEnhancedLoadingIndicator() {
    return Stack(
      children: [
        // Yarı saydam arka plan
        Opacity(
          opacity: 0.6,
          child: const ModalBarrier(
            dismissible: false,
            color: Colors.black,
          ),
        ),
        // Merkezi içerik
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // GIF Yükleme Göstergesi
              Image.asset(
                'assets/depomlaloading.gif',
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Lütfen Bekleyin...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget to display user's listings
  Widget _buildUserListings() {
    if (userListings.isEmpty) {
      return const Center(
        child: Text(
          'Henüz ilan eklemediniz.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userListings.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 900
            ? 4
            : MediaQuery.of(context).size.width > 600
                ? 3
                : 2, // Responsive columns
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75, // Card aspect ratio
      ),
      itemBuilder: (context, index) {
        final listing = userListings[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ListingDetailPage(listing: listing)),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: Colors.black26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Listing Image
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: listing.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: listing.imageUrl[0],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.grey, size: 50),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey, size: 50),
                          ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '${listing.price.toStringAsFixed(2)} ₺',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Widget to display profile information
  Widget _buildProfileInfo() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 60,
              backgroundImage: widget.user.photoURL != null &&
                      widget.user.photoURL!.isNotEmpty
                  ? CachedNetworkImageProvider(widget.user.photoURL!)
                  : const AssetImage('assets/default_avatar.png')
                      as ImageProvider,
            ),
            const SizedBox(height: 16),
            // User Name
            Text(
              widget.user.displayName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Email Address
            Text(
              widget.user.email,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            // User Location
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on,
                    color: Colors.blueAccent, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '$cityName, $districtName, $neighborhoodName',
                    style:
                        const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
           
          ],
        ),
      ),
    );
  }

  /// Widget to display error messages
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: Colors.redAccent, size: 60),
            const SizedBox(height: 20),
            Text(
              'Bir hata oluştu!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent),
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initializeProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Yeniden Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget to display the entire profile page
  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF02aee7),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshProfile,
            child: isError
                ? _buildError()
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Profile Information
                        _buildProfileInfo(),
                        const SizedBox(height: 30),
                                            const AdContainer(),
                        const SizedBox(height: 30),

                        // User Listings Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Dinamik Kullanıcı Adı ile İlanlar Başlığı
                            Text(
                              '${widget.user.displayName}\'ın İlanları',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                           
                          ],
                        ),
                        const SizedBox(height: 16),
                        // User Listings
                        _buildUserListings(),
                      ],
                    ),
                  ),
          ),
          if (isLoading) _buildEnhancedLoadingIndicator(),
        ],
      ),
    );
  }
}