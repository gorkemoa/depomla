import 'package:depomla/components/my_button.dart';
import 'package:depomla/components/my_textfield.dart';
import 'package:depomla/components/square_tile.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Initialize the controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Define the sign-in logic
  void signInUser() {
    final username = usernameController.text;
    final password = passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      print('Username: $username');
      print('Password: $password');
    } else {
      print('Please fill in both fields');
    }
  }

  void signInWithGoogle() {
    print('Signing in with Google...');
    // Add Google sign-in functionality here
  }

  void signInWithApple() {
    print('Signing in with Apple...');
    // Add Apple sign-in functionality here
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
                Image.asset(
                  'assets/depomla.png',
                  width: 500,
                  height: 250,
                ),
                MyTextfield(
                  controller: usernameController,
                  hintText: 'Kullanıcı Adı',
                  obscureText: false,
                ),
                const SizedBox(height: 20),
                MyTextfield(
                  controller: passwordController,
                  hintText: 'Şifre',
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        print('Forgot Password pressed');
                        // Handle forgot password functionality
                      },
                      child: Text(
                        "Şifremi Unuttum",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                MyButton(
                  onTap: signInUser,
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey[700],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "veya",
                        style: TextStyle(color: Colors.grey[700]),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTile(
                      imagePath: 'assets/google.png',
                      onTap: signInWithGoogle,
                    ),
                    const SizedBox(width: 20), // Add spacing between the tiles
                    SquareTile(
                      imagePath: 'assets/apple.png',
                      onTap: signInWithApple,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey[700],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Giriş yapamıyor musun ?",
                        style: TextStyle(color: Colors.grey[700]),
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
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Üye ol',
                      style: TextStyle(color: Colors.blue[900], fontSize: 15),
                    )
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
