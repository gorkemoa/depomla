// lib/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'my_listings_page.dart';
import 'post_login_page.dart';
import 'settings_page.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  UserModel? userModel;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            userModel = UserModel.fromDocument(doc);
          });
        }
      } catch (e) {
        _showSnackBar('Kullanıcı verisi alınırken bir hata oluştu.');
      }
    }
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

      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': photoURL,
      });

      setState(() {
        userModel = userModel?.copyWith(photoURL: photoURL);
      });

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
    final snapshot = await _firestore
        .collection('listings')
        .where('userId', isEqualTo: _auth.currentUser!.uid)
        .get();
    return snapshot.docs.length;
  }

  void _logout() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    String lastSignInDate = userModel != null && userModel!.lastSignIn != null
        ? DateFormat('dd MMM yyyy HH:mm').format(userModel!.lastSignIn!.toDate())
        : 'Bilgi bulunamadı';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.cog, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: userModel == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 20),
                      _buildProfileInfo(lastSignInDate),
                      const SizedBox(height: 20),
                      _buildUserStats(),
                      const SizedBox(height: 20),
                      _buildPostLoginButton(),
                      const SizedBox(height: 20),
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
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isUpdating)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

 Widget _buildProfileHeader() {
  return GestureDetector(
    onTap: _updateProfilePhoto,
    child: CircleAvatar(
      radius: 60,
      backgroundColor: Colors.white,
      backgroundImage: (userModel?.photoURL?.isNotEmpty ?? false)
          ? NetworkImage(userModel!.photoURL!)
          : const AssetImage('assets/default_avatar.png') as ImageProvider,
    ),
  );
}

  Widget _buildProfileInfo(String lastSignInDate) {
    return Column(
      children: [
        Text(
          userModel?.displayName ?? 'Kullanıcı',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          userModel?.email ?? '',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.access_time, color: Colors.blueAccent),
            title: const Text('Son Giriş'),
            subtitle: Text(lastSignInDate),
          ),
        ),
      ],
    );
  }

  Widget _buildUserStats() {
    return FutureBuilder<int>(
      future: _getUserListingsCount(),
      builder: (context, snapshot) {
        int listingsCount = snapshot.data ?? 0;
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.list, color: Colors.orange),
            title: const Text('Toplam İlan Sayısı'),
            trailing: Text('$listingsCount'),
          ),
        );
      },
    );
  }

  Widget _buildPostLoginButton() {
    return ElevatedButton.icon(
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
        backgroundColor: Colors.blue[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}