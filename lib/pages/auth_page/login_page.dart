// lib/login_page.dart
import 'package:depomla/components/my_button.dart';
import 'package:depomla/components/my_textfield.dart';
import 'package:depomla/components/square_tile.dart';
import 'package:depomla/pages/home_page.dart';
import 'package:depomla/pages/profil_page/profile_page.dart';
import 'package:depomla/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'forgot_password.dart';
import 'post_login_page.dart';
import 'register_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore importu ekleyin

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Kontrolleri başlatma
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService(); // AuthService örneği

  // Giriş yapma fonksiyonu
  Future<void> signInUser() async {
    // Formun geçerli olup olmadığını kontrol etmek için
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }

    // Giriş işlemi sırasında hata yönetimi
    try {
      // Giriş işlemi başlamadan önce loading göstergesi
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

      // Kullanıcıyı Firebase Authentication ile giriş yaptırma
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      User? user = userCredential.user;

      if (user != null) {
        // Firestore'da lastSignIn güncelleme
        await _authService.updateLastSignIn(user.uid);
      }

      // Loading göstergesini kapatma
      Navigator.pop(context);

      // Giriş başarılı, ana sayfaya yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PostLoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      // Loading göstergesini kapatma
      Navigator.pop(context);

      // Hata mesajı gösterme
      String message = '';
      if (e.code == 'user-not-found') {
        message = 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      } else if (e.code == 'wrong-password') {
        message = 'Yanlış şifre girdiniz.';
      } else {
        message = 'Bir hata oluştu. Lütfen tekrar deneyin.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      // Loading göstergesini kapatma
      Navigator.pop(context);

      // Genel hata mesajı gösterme
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu.')),
      );
    }
  }

  void signInWithGoogle() {
    print('Google ile giriş yapılıyor...');
    // Google sign-in işlevselliğini burada ekleyin
  }

  void signInWithApple() {
    print('Apple ile giriş yapılıyor...');
    // Apple sign-in işlevselliğini burada ekleyin
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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
                  width: 400, // Daha uygun bir genişlik
                  height: 300, // Daha uygun bir yükseklik
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
                // Şifremi Unuttum Butonu
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage()),
                    );
                  },
                  child: Text(
                    "Şifremi Unuttum",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),

                const SizedBox(height: 20),
                // Giriş Yap Butonu
                MyButton(
                  onTap: signInUser,
                  text: 'Giriş Yap',
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
                // Sosyal Giriş Butonları
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTile(
                      imagePath: 'assets/google.png',
                      onTap: () async {
                        final user = await AuthService().signInWithGoogle();
                        if (user != null) {
                          // Firestore'da lastSignIn güncelleme
                          await AuthService().updateLastSignIn(user.uid);

                          // Başarılı giriş sonrası ProfilSayfasi'na yönlendirme
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => PostLoginPage()),
                          );
                        } else {
                          // Giriş iptal edildi veya başarısız oldu
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Giriş başarısız veya iptal edildi.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Kayıt Sayfasına Yönlendirme
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Zaten bir hesabınız var mı?"),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterPage()),
                        );
                      },
                      child: Text(
                        'Üye Ol',
                        style: TextStyle(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
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