import 'package:depomla/pages/item_storage_page.dart';
import 'package:depomla/pages/storage_rental_page.dart';
import 'package:flutter/material.dart';
class CategorySelectionPage extends StatelessWidget {
  const CategorySelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Seçimi'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StorageRentalPage()),
                );
              },
              child: const Text('Depo Kiralama'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ItemStoragePage()),
                );
              },
              child: const Text('Eşya Depolama'),
            ),
          ],
        ),
      ),
    );
  }
}
