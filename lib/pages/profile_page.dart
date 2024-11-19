// lib/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:depomla/services/auth_service.dart';
import 'package:depomla/pages/login_page.dart';
import 'package:depomla/pages/my_listings_page.dart';
import 'package:depomla/pages/add_listing_page.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? userModel;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          setState(() {
            userModel = UserModel.fromDocument(doc);
          });
        }
      } catch (e) {
        print('Kullanıcı verisi alınırken hata: $e');
      }
    }
  }

  void _logout() async {
    await _authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedLastSignIn = userModel != null && userModel!.lastSignIn != null
        ? DateFormat('dd MMM yyyy HH:mm').format(userModel!.lastSignIn!.toDate())
        : 'Bilgi bulunamadı';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: userModel == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil Fotoğrafı
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: userModel!.photoURL.isNotEmpty
                          ? NetworkImage(userModel!.photoURL)
                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Kullanıcı Adı
                  Center(
                    child: Text(
                      userModel!.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // E-posta
                  Text(
                    'E-posta: ${userModel!.email}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // Son Giriş
                  Text(
                    'Son Giriş: $formattedLastSignIn',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  // İlan Ekleme Butonu
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddListingPage()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('İlan Ekle'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Kendi İlanlarını Görüntüleme Butonu
                  ElevatedButton.icon(
                    onPressed: () {
                      if (userModel != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyListingsPage(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('Kendi İlanlarımı Görüntüle'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}