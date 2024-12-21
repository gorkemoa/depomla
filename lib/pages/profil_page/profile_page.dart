// lib/pages/profile_page/profile_page.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:depomla/pages/auth_page/settings_page.dart';
import 'package:depomla/providers/user_provider.dart';
import 'package:depomla/services/auth_service.dart';
import 'package:depomla/models/user_model.dart';
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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'photoURL': photoURL,
      });

      // UserProvider üzerinden userModel'e eriş ve güncelle
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserModel = userProvider.userModel;

      if (currentUserModel != null) {
        userProvider
            .updateUserModel(currentUserModel.copyWith(photoURL: photoURL));
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

  Future<int> _getUserListingsCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('listings')
        .where('uid', isEqualTo: _auth.currentUser!.uid)
        .get();
    return snapshot.docs.length;
  }

  void _logout() async {
    await _authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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

  Widget _buildProfileInfo(UserModel userModel, String lastSignInDate) {
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
        const SizedBox(height: 8),
        Text(
          userModel.email,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const Icon(Icons.access_time, color: Color(0xFF4A90E2)),
            title: const Text('Son Giriş'),
            subtitle: Text(lastSignInDate),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              count,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

          String lastSignInDate = userModel.lastSignIn != null
              ? DateFormat('dd MMM yyyy HH:mm')
                  .format(userModel.lastSignIn!.toDate())
              : 'Bilgi bulunamadı';

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    _buildProfileHeader(userModel),
                    const SizedBox(height: 24),

                    _buildProfileInfo(userModel, lastSignInDate),
                    const SizedBox(height: 24),

                    const SizedBox(height: 24),

                    _buildNavigationButtons(),
                    const SizedBox(height: 24),
                    const AdContainer(),



                    // Reklamları sayfanın uygun bir yerine yerleştirdik
                  ],
                ),
              ),
              if (_isUpdating)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
