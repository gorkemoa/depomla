// lib/pages/auth_page/login_page.dart

import 'package:depomla/components/my_button.dart';
import 'package:depomla/components/square_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'forgot_password.dart';
import 'post_login_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Yükleme overlay'ini göstermek için kullanılan widget
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Image.asset(
          'assets/depomlaloading.gif',
          width: 150,
          height: 150,
        ),
      ),
    );
  }

  // Giriş yapma fonksiyonu
  Future<void> signInUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }

    try {
      // Firebase ile giriş
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Yükleme overlay'ini göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildLoadingOverlay(),
      );

      // 1.5 saniye bekle
      await Future.delayed(const Duration(milliseconds: 1500));

      Navigator.pop(context); // Yükleme overlay'ini kapat

      // Başarılı giriş sonrası yönlendirme
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PostLoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Bir hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlarını almak için MediaQuery kullanıyoruz
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Klavye açıldığında sayfanın yeniden boyutlanmasını engeller
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Arka Plan Resmi
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'), // Arka plan resmi
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Siyah Opaklık Katmanı (isteğe bağlı opaklığı ayarlayabilirsiniz)
          // Container(
          //   width: double.infinity,
          //   height: double.infinity,
          //   color: Colors.black.withOpacity(0.3),
          // ),
          // İçerik
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Column(
                  // İçeriğin ekranın ortasına gelmesini sağlar
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo (İsteğe bağlı ekleyebilirsiniz)
                    // SizedBox(
                    //   height: 100,
                    //   child: Image.asset('assets/logo.png'),
                    // ),
                    const SizedBox(height: 260),

                    // E-posta Alanı
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 205, 202, 202).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'E-posta',
                          icon: Icon(Icons.email, color: Colors.grey),
                        ),
                      ),
                    ),

                    // Şifre Alanı
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 205, 202, 202).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Şifre',
                          icon: Icon(Icons.lock, color: Colors.grey),
                        ),
                      ),
                    ),

                    // Şifremi Unuttum
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ForgotPasswordPage()),
                          );
                        },
                        child: Text(
                          'Şifremi Unuttum',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
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
                      ),
                    ),

                    const SizedBox(height: 20),

                    // "veya" Yazısı ve Çizgiler
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: const Color.fromARGB(189, 0, 133, 250),
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
                            color: const Color.fromARGB(189, 0, 133, 250),
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
                            // Google ile giriş yap
                            final user = await AuthService().signInWithGoogle();
                            if (user != null) {
                              // Firestore'da lastSignIn güncelleme
                              await AuthService().updateLastSignIn(user.uid);

                              // Yükleme overlay'ini göster
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => _buildLoadingOverlay(),
                              );

                              // 1.5 saniye bekle
                              await Future.delayed(const Duration(milliseconds: 2500));

                              Navigator.pop(context); // Yükleme overlay'ini kapat

                              // Başarılı giriş sonrası PostLoginPage'e yönlendirme
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const PostLoginPage()),
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
                        // İsteğe bağlı diğer sosyal giriş butonları ekleyebilirsiniz
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Kayıt Olmak İçin
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Hesabınız yok mu?',
                          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const RegisterPage()),
                            );
                          },
                          child: const Text(
                            'Kayıt Ol',
                            style: TextStyle(
                              color: Color(0xFF02aee7),
                              fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }
}