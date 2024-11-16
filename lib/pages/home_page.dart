import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'listings_page.dart';
import 'chats_page.dart';
import 'store_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ListingsPage(), // İlanları listeleyen sayfa
    const ChatsPage(),    // Sohbetler sayfası
    const StorePage(),    // İlan ekleme sayfası
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['Anasayfa', 'Sohbetler', 'Depola'][_selectedIndex]),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.react,
        items: const [
          TabItem(icon: Icons.home, title: 'Anasayfa'),
          TabItem(icon: Icons.chat, title: 'Sohbetler'),
          TabItem(icon: Icons.storage, title: 'Depola'),
        ],
        initialActiveIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
