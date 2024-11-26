import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  String? _email;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  void _loadUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _email = user?.email ?? '';
    });
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_email == null || _email!.isEmpty) {
      _showSnackBar('E-posta adresi boş olamaz.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email!);
      _showSnackBar('Şifre sıfırlama e-postası gönderildi. Lütfen e-postanızı kontrol edin.');
      Navigator.pop(context);
    } catch (e) {
      print('E-posta gönderme hatası: $e');
      _showSnackBar('Şifre sıfırlama e-postası gönderilirken bir hata oluştu.');
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
        title: const Text('Şifre Değiştir'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 0,
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
                  // Başlık ve İkon
                  Column(
                    children: [
                      Icon(
                        Icons.lock_reset,
                        size: 100,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Şifre Sıfırlama',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                  // E-posta Alanı (Salt Okunur)
                  TextFormField(
                    initialValue: _email,
                    readOnly: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: 'E-posta Adresiniz',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // E-posta Gönder Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendPasswordResetEmail,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Şifre Sıfırlama E-postası Gönder',
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