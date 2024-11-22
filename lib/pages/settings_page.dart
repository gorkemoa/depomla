// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_listing_page.dart';
import 'add_listing_page.dart';
import 'manage_listings_page.dart';
import 'my_listings_page.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? userModel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Kullanıcı verilerini yükleme fonksiyonu
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kullanıcı verisi alınırken bir hata oluştu.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Ayar seçeneklerini oluşturan widget
  Widget _buildSettingsOptions() {
    return Column(
      children: [
        // Profil Bilgilerini Güncelle
        _buildSettingsCard(
          icon: Icons.person,
          title: 'Profil Bilgilerini Güncelle',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _EditProfilePage(userModel: userModel!),
              ),
            ).then((_) {
              _loadUserData(); // Geri dönüldüğünde verileri yeniden yükle
            });
          },
        ),
        const SizedBox(height: 10),

        // Şifreyi Değiştir
        _buildSettingsCard(
          icon: Icons.lock,
          title: 'Şifreyi Değiştir',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChangePasswordPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        // İlanlarımı Yönet
        _buildSettingsCard(
          icon: Icons.list,
          title: 'İlanlarımı Yönet',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageListingsPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        // Çıkış Yap
        _buildSettingsCard(
          icon: Icons.logout,
          title: 'Çıkış Yap',
          textColor: Colors.redAccent,
          onTap: () {
            _logout();
          },
        ),
      ],
    );
  }

  // Ayar seçenekleri için kart widget'ı
  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    Color textColor = Colors.black87,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent, size: 30),
        title: Text(
          title,
        
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // Çıkış yapma fonksiyonu
  void _logout() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0, // Daha düz bir görünüm için elevation kaldırıldı
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : userModel == null
              ? const Center(child: Text('Kullanıcı bilgileri bulunamadı.'))
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient( // Arka plan gradyanı eklendi
                      colors: [Colors.blue[50]!, Colors.blue[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildSettingsOptions(),
                  ),
                ),
      backgroundColor: Colors.grey[100],
    );
  }
}

// Profil Bilgilerini Düzenleme Sayfası
class _EditProfilePage extends StatefulWidget {
  final UserModel userModel;

  const _EditProfilePage({Key? key, required this.userModel}) : super(key: key);

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String? _displayName;
  String? _email;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _displayName = widget.userModel.displayName;
    _email = widget.userModel.email;
  }

  Future<void> _updateProfileInfo() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isUpdating = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış.');

      // Firebase Auth'da e-posta güncelle
      if (_email != user.email) {
        await user.updateEmail(_email!);
      }

      // Firestore'da bilgileri güncelle
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'displayName': _displayName,
        'email': _email,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil bilgileri başarıyla güncellendi.')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Profil bilgileri güncellenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profil bilgileri güncellenirken bir hata oluştu.')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Profil Bilgilerini Güncelle'),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Kullanıcı Adı
                      TextFormField(
                        initialValue: _displayName,
                        decoration: InputDecoration(
                          labelText: 'Adınız',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Adınız boş olamaz' : null,
                        onSaved: (value) => _displayName = value,
                      ),
                      const SizedBox(height: 16),

                      // E-posta
                      TextFormField(
                        initialValue: _email,
                        decoration: InputDecoration(
                          labelText: 'E-posta',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.email),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'E-posta boş olamaz' : null,
                        onSaved: (value) => _email = value,
                      ),
                      const SizedBox(height: 16),

                      // Kaydet Butonu
                      ElevatedButton.icon(
                        onPressed: _updateProfileInfo,
                        icon: const Icon(Icons.save),
                        label: const Text('Değişiklikleri Kaydet'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        
                        ),
                      ),
                    ],
                  )),
            ),
            if (_isUpdating)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ));
  }
}

// Şifre Değiştirme Sayfası
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  String? _currentPassword;
  String? _newPassword;
  bool _isUpdating = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isUpdating = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış.');

      // Eski şifreyi doğrula
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPassword!,
      );

      await user.reauthenticateWithCredential(cred);

      // Yeni şifreyi güncelle
      await user.updatePassword(_newPassword!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre başarıyla güncellendi.')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Şifre güncellenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre güncellenirken bir hata oluştu.')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Şifreyi Değiştir'),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Mevcut Şifre
                      TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Mevcut Şifre',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Mevcut şifrenizi giriniz'
                            : null,
                        onSaved: (value) => _currentPassword = value,
                      ),
                      const SizedBox(height: 16),

                      // Yeni Şifre
                      TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Yeni Şifre',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                
                        validator: (value) => value == null || value.length < 6
                            ? 'Şifre en az 6 karakter olmalı'
                            : null,
                        onSaved: (value) => _newPassword = value,
                      ),
                      const SizedBox(height: 16),

                      // Şifreyi Güncelle Butonu
                      ElevatedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(Icons.lock),
                        label: const Text('Şifreyi Güncelle'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                       
                        ),
                      ),
                    ],
                  )),
            ),
            if (_isUpdating)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ));
  }
}