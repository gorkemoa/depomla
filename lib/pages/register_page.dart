import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:depomla/services/auth_service.dart';
import 'package:depomla/pages/home_page.dart';
import 'package:depomla/components/my_button.dart';
import 'package:depomla/components/my_textfield.dart';

import '../components/square_tile.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Kontrolleri başlatma
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();

  // Kayıt olma fonksiyonu
  Future<void> signUpUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String displayName = displayNameController.text.trim();

    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }

    // Kayıt işlemi sırasında hata yönetimi
    try {
      // Kayıt işlemi başlamadan önce loading göstergesi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF02aee7),
            ),
          );
        },
      );

      // AuthService kullanarak kullanıcıyı kaydet
      User? user = await AuthService().signUpWithEmailAndPassword(
        email,
        password,
        displayName,
      );

      // Loading göstergesini kapatma
      Navigator.pop(context);

      if (user != null) {
        // Kayıt başarılı, ana sayfaya yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // Kayıt başarısız
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt olma işlemi başarısız oldu.')),
        );
      }
    } catch (e) {
      // Loading göstergesini kapatma
      Navigator.pop(context);

      // Hata mesajı gösterme
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 132, 186, 237),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/depomla.png',
                  width: 400,
                  height: 300,
                ),
                const SizedBox(height: 20),
                // Kullanıcı Adı Girişi
                MyTextfield(
                  controller: displayNameController,
                  hintText: 'Kullanıcı Adı',
                  obscureText: false,
                ),
                const SizedBox(height: 20),
                // E-posta Girişi
                MyTextfield(
                  controller: emailController,
                  hintText: 'E-posta',
                  obscureText: false,
                ),
                const SizedBox(height: 20),
                // Şifre Girişi
                MyTextfield(
                  controller: passwordController,
                  hintText: 'Şifre',
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                // Kayıt Ol Butonu
                MyButton(
                  onTap: signUpUser,
                  text: 'Kayıt Ol',
                  color: const Color(0xFF02aee7),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 30),
                // Veya
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "veya",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Sosyal Giriş Butonları (Google, Apple vb.)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google ile Kayıt Ol
                    SquareTile(
                      imagePath: 'assets/google.png',
                      onTap: () async {
                        User? user = await AuthService().signInWithGoogle();
                        if (user != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Giriş başarısız veya iptal edildi.')),
                          );
                        }
                      },
                    ),
                    // Diğer sosyal giriş butonları ekleyebilirsiniz
                  ],
                ),
                const SizedBox(height: 20),
                // Giriş Sayfasına Yönlendirme
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Zaten bir hesabınız var mı?"),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      child: Text(
                        'Giriş Yap',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}