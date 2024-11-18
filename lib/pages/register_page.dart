// lib/register_page.dart
import 'package:depomla/components/my_button.dart';
import 'package:depomla/components/my_textfield.dart';
import 'package:depomla/components/square_tile.dart';
import 'package:depomla/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController usernameController = TextEditingController();

  // Kayıt yapma fonksiyonu
  Future<void> signUserUp() async {
    // Kullanıcı kayıt sırasında bir hata ile karşılaşırsa
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

      // Kullanıcıyı Firebase'e kaydetme
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      // Firestore'a ek bilgiler ekleyebilirsiniz (örn: kullanıcı adı)
      // Örneğin:
      /*
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'created_at': Timestamp.now(),
      });
      */

      // Loading göstergesini kapatma
      Navigator.pop(context);

      // Başarı mesajı gösterme
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt Başarılı!')),
      );

      // Kayıt sonrası yönlendirme (Giriş sayfası)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      // Loading göstergesini kapatma
      Navigator.pop(context);

      // Hata mesajı gösterme
      String message = '';
      if (e.code == 'weak-password') {
        message = 'Şifre çok zayıf.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta zaten kullanımda.';
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
    usernameController.dispose();
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
                  width: 200, // Daha uygun bir genişlik
                  height: 100, // Daha uygun bir yükseklik
                ),
                const SizedBox(height: 20),
                // Kullanıcı Adı Girişi
                MyTextfield(
                  controller: usernameController,
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
                  onTap: signUserUp,
                  text: 'Üye Ol',
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
                        try {
                          await AuthService().signInWithGoogle();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Google ile giriş başarılı!')),
                          );
                          // Başarılı giriş sonrası yönlendirme
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                          );
                        } catch (e) {
                          // Hata durumunda mesaj gösterme
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Google ile giriş başarısız: $e')),
                          );
                        }
                      },
                    ),

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
