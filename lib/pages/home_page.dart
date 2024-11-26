import 'package:depomla/notifications_page.dart';
import 'package:depomla/pages/auth_page/settings_page.dart';
import 'package:depomla/pages/listing_page/my_listings_page.dart';
import 'package:flutter/material.dart';
import 'listing_page/listings_page.dart';
import 'comment_page/chats_page.dart';
import 'listing_page/add_listing_page.dart';
import 'profil_page/profile_page.dart';
import '../models/listing_model.dart';

class HomePage extends StatefulWidget {
  final ListingType selectedCategory;

  const HomePage({super.key, required this.selectedCategory});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      ListingsPage(
          category:
              widget.selectedCategory), // Dinamik kategoriye göre ana sayfa
      ChatsPage(),
      const AddListingPage(),
      const MyListingsPage(), // İlanlarım için örnek
      SettingsPage(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
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
                icon: SizedBox
                    .shrink(), // Ortadaki öğe boş olacak, yerini custom widget alacak
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'İlanlarım',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profilim',
              ),
            ],
          ),
          Positioned(
            top: -23, // İkonun biraz yukarı çıkması için
            left: MediaQuery.of(context).size.width / 2 - 25, // Ortalamak için
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = 2; // "İlan Ver" sayfasına git
                });
              },
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color.fromARGB(255, 207, 224, 231),
                    radius: 25, // Yuvarlak ikon boyutu
                    child: Image.asset(
                      'assets/ilan_ver.png', // İkonun yolu
                      height: 27,
                      width: 27,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "İlan Ver",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
