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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController displayNameController = TextEditingController();

  bool isProcessing = false; // Butonun tıklanma durumunu kontrol etmek için

  Future<void> signUpUser() async {
    if (isProcessing) return; // Eğer işlem devam ediyorsa yeni bir işlem başlatma
    setState(() {
      isProcessing = true;
    });

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
      setState(() {
        isProcessing = false;
      });
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreler eşleşmiyor.')),
      );
      setState(() {
        isProcessing = false;
      });
      return;
    }

    try {
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

      User? user = await AuthService().signUpWithEmailAndPassword(
        email,
        password,
        displayName,
      );

      Navigator.pop(context);

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PostLoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt olma işlemi başarısız oldu.')),
        );
      }
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
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
    // Cihazın ekran boyutlarını al
    final size = MediaQuery.of(context).size;

    return Scaffold(
     
      body: Stack(
        children: [
          // Arka Plan Resmi
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background_register.jpg'), // Arka plan görseli
                fit: BoxFit.cover,
              ),
            ),
          ),
          // İçerik
          SafeArea(
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: SingleChildScrollView( // ScrollView ekledik
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // İçeriğin ekranı doldurmasını engeller
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/depomla.png',
                          width: size.width * 0.4, // Ekran genişliğinin %40'ı kadar
                          height: size.width * 0.4,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Kullanıcı Adı Girişi
                      MyTextfield(
                        controller: displayNameController,
                        hintText: 'Kullanıcı Adı',
                        obscureText: false,
                        prefixIcon: Icons.person,
                      ),
                      const SizedBox(height: 15),
                      // E-posta Girişi
                      MyTextfield(
                        controller: emailController,
                        hintText: 'E-posta',
                        obscureText: false,
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 15),
                      // Şifre Girişi
                      MyTextfield(
                        controller: passwordController,
                        hintText: 'Şifre',
                        obscureText: true,
                        prefixIcon: Icons.lock,
                      ),
                      const SizedBox(height: 15),
                      // Şifre Tekrar Girişi
                      MyTextfield(
                        controller: confirmPasswordController,
                        hintText: 'Şifre Tekrar',
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 25),
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
                        // width: double.infinity, // Kaldırıldı
                        // height: 50, // Kaldırıldı
                        // borderRadius: 8, // Kaldırıldı
                      ),
                      const SizedBox(height: 25),
                      // Veya
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              color: Colors.grey[400],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "veya",
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              color: Colors.grey[400],
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
                              if (isProcessing) return; // İşlem devam ediyorsa iptal et
                              setState(() {
                                isProcessing = true;
                              });

                              User? user = await AuthService().signInWithGoogle();
                              setState(() {
                                isProcessing = false;
                              });

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
                          // Diğer sosyal giriş butonlarını eklemek isterseniz buraya ekleyebilirsiniz
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
          ),)    ],
          ),
        );
      }
    }