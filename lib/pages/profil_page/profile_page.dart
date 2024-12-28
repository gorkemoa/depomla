// lib/pages/profile_page/profile_page.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:depomla/pages/auth_page/settings_page.dart';
import 'package:depomla/pages/listing_page/listings_details_page.dart';
import 'package:depomla/providers/user_provider.dart';
import 'package:depomla/services/auth_service.dart';
import 'package:depomla/models/user_model.dart';
import 'package:depomla/models/listing_model.dart';
import 'package:depomla/ads/ad_container.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../ads/banner_ad_example.dart';
import '../auth_page/login_page.dart';
import '../auth_page/post_login_page.dart';
import '../comment_page/full_screen_image_page.dart'; // Tam ekran resim sayfası

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isUpdating = false;
  User? user;

  List<Listing> myListings = []; // Kullanıcının ilanları

  @override
  void initState() {
    super.initState();
    _initializeAds();
    user = _auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const LoginPage(),
          ),
        );
      });
    } else {
      Provider.of<UserProvider>(context, listen: false).loadUserData();
      fetchMyListings(); // Kullanıcı giriş yapmışsa ilanları çek
    }
  }

  Future<void> _initializeAds() async {
    await GlobalAdsService().initialize();
    // Reklamları önceden yüklemeye gerek yok; AdContainer kendi içinde yükler
  }

  @override
  void dispose() {
    // AdContainer kendi içinde BannerAd'ı serbest bırakır
    super.dispose();
  }

  /// Profil fotoğrafını günceller
  Future<void> _updateProfilePhoto() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış.');

      final file = File(pickedFile.path);
      final fileName = '${user.uid}_profile_photo.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child(fileName);

      final uploadTask = await ref.putFile(file);
      final photoURL = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoURL': photoURL,
      });

      // UserProvider üzerinden userModel'e eriş ve güncelle
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserModel = userProvider.userModel;

      if (currentUserModel != null) {
        userProvider.updateUserModel(currentUserModel.copyWith(photoURL: photoURL));
      } else {
        _showSnackBar('Kullanıcı bilgileri bulunamadı.');
      }

      _showSnackBar('Profil fotoğrafı başarıyla güncellendi.');
    } catch (e) {
      _showSnackBar('Profil fotoğrafı güncellenirken bir hata oluştu.');
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  /// Kullanıcının ilanlarını çeker
  Future<void> fetchMyListings() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('listings')
          .where('userId', isEqualTo: user!.uid) // Doğru alan adı kullanıldı
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        myListings = snapshot.docs.map((doc) => Listing.fromDocument(doc)).toList();
      });
    } catch (e) {
      print('My Listings veri alınırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İlanlar alınırken hata oluştu: $e')),
      );
    }
  }

  /// Kullanıcının favori ilanlarını çeker
  Future<List<Listing>> fetchMyFavorites() async {
    List<Listing> favorites = [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .orderBy('createdAt', descending: true)
          .get();

      List<String> favoriteListingIds = snapshot.docs.map((doc) => doc.id).toList();

      if (favoriteListingIds.isNotEmpty) {
        final listingsSnapshot = await FirebaseFirestore.instance
            .collection('listings')
            .where(FieldPath.documentId, whereIn: favoriteListingIds)
            .get();

        favorites = listingsSnapshot.docs.map((doc) => Listing.fromDocument(doc)).toList();
      }
    } catch (e) {
      print('My Favorites veri alınırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favoriler alınırken hata oluştu: $e')),
      );
    }
    return favorites;
  }

  /// Çıkış yapar
  void _logout() async {
    await _authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  /// SnackBar gösterir
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Profil başlığını oluşturur
  Widget _buildProfileHeader(UserModel userModel) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 70,
          backgroundColor: Colors.white,
          backgroundImage: (userModel.photoURL?.isNotEmpty ?? false)
              ? CachedNetworkImageProvider(userModel.photoURL!)
              : const AssetImage('assets/default_avatar.png') as ImageProvider,
        ),
        Positioned(
          bottom: 0,
          right: 4,
          child: GestureDetector(
            onTap: _updateProfilePhoto,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4A90E2),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Profil bilgilerini oluşturur
  Widget _buildProfileInfo(UserModel userModel) {
    return Column(
      children: [
        Text(
          userModel.displayName,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userModel.email,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatItem('İlanlar', myListings.length.toString(), Icons.list_alt),
            const SizedBox(width: 24),
            _buildStatItem('Puan', '4.5⭐️', Icons.star),
            const SizedBox(width: 24),
            _buildStatItem('Yorum', '16+💬', Icons.chat_bubble),
          ],
        ),
      ],
    );
  }

  /// İstatistik öğelerini oluşturur
  Widget _buildStatItem(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4A90E2), size: 28),
        const SizedBox(height: 4),
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  /// Navigasyon butonlarını oluşturur
  Widget _buildNavigationButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PostLoginPage()),
            );
          },
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Depo Kategori Sayfasına Git'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: const Color(0xFF4A90E2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text('Çıkış Yap'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
        ),
      ],
    );
  }


   

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A90E2),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.cog),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final userModel = userProvider.userModel;

          if (userModel == null) {
            return const Center(child: Text('Kullanıcı bilgileri alınamadı.'));
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildProfileHeader(userModel),
                    const SizedBox(height: 26),
                    _buildProfileInfo(userModel),
                    const SizedBox(height: 14),
                    _buildNavigationButtons(),
                    const SizedBox(height: 14),
                    const AdContainer(),
                  ],
                ),
              ),
              if (_isUpdating)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
