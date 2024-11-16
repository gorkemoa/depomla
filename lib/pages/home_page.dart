import 'package:depomla/pages/category_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'listings_page.dart';
import 'chats_page.dart';

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
    const CategorySelectionPage(), // İlan ekleme sayfası
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          iconTheme: const IconThemeData(size: 24), // İkon boyutunu ayarlar
          textTheme: const TextTheme(
            bodySmall: TextStyle(fontSize: 12), // Yazı tipi boyutunu ayarlar
          ),
        ),
        child: ConvexAppBar(
          style: TabStyle.react,
          height: 50.0, // Yüksekliği küçülttük
          backgroundColor: Colors.blueAccent,
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
      ),
    );
  }
}
