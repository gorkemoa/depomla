// lib/pages/auth_page/register_page.dart
import 'package:depomla/pages/auth_page/post_login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:depomla/services/auth_service.dart';
import 'package:depomla/components/my_button.dart';
import 'package:depomla/components/my_textfield.dart';
import '../../components/square_tile.dart';
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
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController displayNameController = TextEditingController();

  // Kayıt olma fonksiyonu
  Future<void> signUpUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();
    String displayName = displayNameController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreler eşleşmiyor.')),
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
          MaterialPageRoute(builder: (context) => const PostLoginPage()),
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
    confirmPasswordController.dispose();
    displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlarını almak için
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Arka plan rengini değiştirebilirsiniz
      backgroundColor: const Color.fromARGB(255, 132, 186, 237),
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Geri dönüş işlemi
          },
        ),
      backgroundColor: const Color.fromARGB(255, 132, 186, 237),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                SizedBox(
                  width: size.width * 0.6,
                  child: Image.asset(
                    'assets/depomla.png',
                    fit: BoxFit.cover,
                  ),
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
                // Şifre Tekrar Girişi
                MyTextfield(
                  controller: confirmPasswordController,
                  hintText: 'Şifre Tekrar',
                  obscureText: true,
                ),
                const SizedBox(height: 30),
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
                        color: const Color.fromARGB(190, 12, 133, 52),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "veya",
                        style: TextStyle(color: Color.fromARGB(255, 59, 56, 56)),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: const Color.fromARGB(190, 12, 133, 52),
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
                            MaterialPageRoute(
                                builder: (context) => const PostLoginPage()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Giriş başarısız veya iptal edildi.')),
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
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}