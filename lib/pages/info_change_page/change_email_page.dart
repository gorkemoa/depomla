// lib/pages/auth_page/settings_page/change_email_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({Key? key}) : super(key: key);

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _formKey = GlobalKey<FormState>();
  String? _currentPassword;
  String? _newEmail;
  String? _confirmEmail;
  bool _isProcessing = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Re-authenticate the user
  Future<bool> _reauthenticateUser() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        _showSnackBar('Kullanıcı bulunamadı.');
        return false;
      }

      // Kullanıcıdan mevcut şifresini almanız gerekebilir
      // Bu örnekte mevcut şifreyi girdik varsayılıyor
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPassword!,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print('Re-authentication hatası: $e');
      _showSnackBar('Mevcut şifre yanlış veya tekrar giriş yapmanız gerekebilir.');
      return false;
    }
  }

  Future<void> _changeEmail() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    if (_newEmail != _confirmEmail) {
      _showSnackBar('Yeni e-postalar eşleşmiyor.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        _showSnackBar('Kullanıcı bulunamadı.');
        return;
      }

      // Re-authenticate
      bool reauthenticated = await _reauthenticateUser();
      if (!reauthenticated) return;

      // Update email
      await user.updateEmail(_newEmail!);
      await user.sendEmailVerification();

      _showSnackBar('E-posta başarıyla güncellendi. Lütfen e-posta adresinizi doğrulayın.');
      Navigator.pop(context);
    } catch (e) {
      print('E-posta güncelleme hatası: $e');
      _showSnackBar('E-posta güncellenirken bir hata oluştu.');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-posta Değiştir'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? screenWidth * 0.2 : 24,
              vertical: 32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // İkon ve Başlık
                  Column(
                    children: [
                      Icon(
                        Icons.email,
                        size: 100,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'E-posta Değiştirme',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                  // Mevcut Şifre
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mevcut Şifreniz',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mevcut şifre boş olamaz.';
                      }
                      if (value.length < 6) {
                        return 'Şifre en az 6 karakter olmalıdır.';
                      }
                      return null;
                    },
                    onSaved: (value) => _currentPassword = value,
                  ),
                  const SizedBox(height: 24),
                  // Yeni E-posta
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Yeni E-posta',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Yeni e-posta boş olamaz.';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Geçerli bir e-posta adresi giriniz.';
                      }
                      return null;
                    },
                    onSaved: (value) => _newEmail = value,
                  ),
                  const SizedBox(height: 16),
                  // Yeni E-posta Doğrulama
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Yeni E-postayı Doğrulayın',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'E-posta doğrulama boş olamaz.';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Geçerli bir e-posta adresi giriniz.';
                      }
                      return null;
                    },
                    onSaved: (value) => _confirmEmail = value,
                  ),
                  const SizedBox(height: 32),
                  // Kaydet Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changeEmail,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'E-postayı Güncelle',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}