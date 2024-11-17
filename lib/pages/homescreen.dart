// lib/homescreen.dart
import 'package:depomla/pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Homescreen extends StatelessWidget {
   Homescreen({super.key});

final user = FirebaseAuth.instance.currentUser!;

  // Çıkış yapma fonksiyonu
  void signUserOut(){
    FirebaseAuth.instance.signOut();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signUserOut,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Başardın!",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
