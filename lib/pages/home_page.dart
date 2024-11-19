// lib/pages/home_page.dart

import 'package:depomla/pages/add_listing_page.dart';
import 'package:depomla/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'listings_page.dart';
import 'chats_page.dart'; // Doğru şekilde ChatsPage'i import edin

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ListingsPage(), // İlanları listeleyen sayfa
    ChatsPage(),          // Sohbetleri listeleyen sayfa
    const AddListingPage(), // İlan ekleme sayfası
    const ProfilePage(),    // Profil sayfası
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensure all items are visible
        backgroundColor: Colors.white,
        selectedItemColor: const Color.fromARGB(255, 35, 68, 152),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Sohbetler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: 'Depola',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilim',
          ),
        ],
      ),
    );
  }
}