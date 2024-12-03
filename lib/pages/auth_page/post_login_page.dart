import 'package:depomla/models/listing_model.dart';
import 'package:flutter/material.dart';
import '../home_page.dart';
import 'login_page.dart'; // Çıkış sonrası yönlendirme için LoginPage'i import edin
import 'package:firebase_auth/firebase_auth.dart'; // Çıkış yapmak için gerekli
import 'package:carousel_slider/carousel_slider.dart'; // CarouselSlider paketi

class PostLoginPage extends StatelessWidget {
  const PostLoginPage({super.key});

  // Carousel resimlerini tanımlıyoruz
  final List<String> carouselImages = const [
    'assets/depomlablack.png',
    'assets/depomla.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 150.0),
        child: Column(
          children: [
            // Yatay Kaydırılabilir Carousel
            _buildCarouselSlider(),
            const SizedBox(height: 20),
            // Seçenek Kartları
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // 2 sütun
                mainAxisSpacing: 20, // Satırlar arası boşluk
                crossAxisSpacing: 20, // Sütunlar arası boşluk
                childAspectRatio: 1, // Kare şeklinde elemanlar
                children: [
                  _buildOptionCard(
                    icon: Icons.storage, // Depola ikonu
                    label: 'Depola',
                    onTap: () {
                      // Depola seçildiğinde HomePage'e deposit kategorisi ile git
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HomePage(selectedCategory: ListingType.deposit),
                        ),
                      );
                    },
                  ),
                  _buildOptionCard(
                    icon: Icons.store, // Depolat ikonu
                    label: 'Depolat',
                    onTap: () {
                      // Depolat seçildiğinde HomePage'e storage kategorisi ile git
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HomePage(selectedCategory: ListingType.storage),
                        ),
                      );
                    },
                  ),
                  _buildOptionCard(
                    icon: Icons.business_center, // Business ikonu
                    label: 'Depomla Business',
                    onTap: () {
                      // Depomla Business için başka bir sayfaya yönlendirme yapılabilir
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Depomla Business'),
                          content: const Text('Bu özellik yakında gelecek!'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Kapat'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _buildOptionCard(
                    icon: Icons.info_outline, // Bilgi ikonu
                    label: 'Hangisini \n seçmeliyim?',
                    onTap: () {
                      // Bilgi ekranını göster
                    showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text(
      'Hizmet Hakkında Bilgilendirme',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    content: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Depomla, depolama ihtiyaçlarınızı karşılamak için tasarlanmış bir platformdur.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 15),
          
          // Depola Bölümü
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check, size: 20, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Depola',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Ürünlerinizi güvenle saklamak için alan kiralamanıza olanak tanır.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Depolat Bölümü
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check, size: 20, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Depolat',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Depolama alanlarınızı başkalarına kiraya vermenizi sağlar.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Depomla Business Bölümü
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.business_center, size: 20, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Depomla Business',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'İşletmeler için özel depolama çözümleri sunar. Yakında hizmete açılacağız!',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          const Text(
            'Not: Depomla, bu hizmetleri doğrudan sağlamaz; kullanıcıları hizmet sunanlar ve talep edenlerle buluşturur.',
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(
          'Anladım',
          style: TextStyle(color: Colors.blue),
        ),
      ),
    ],
  ),
);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Yatay Kaydırılabilir CarouselSlider'ı oluşturuyoruz
  Widget _buildCarouselSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 150.0,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        autoPlayInterval: const Duration(seconds: 3),
      ),
      items: carouselImages.map((imagePath) {
        return Builder(
          builder: (BuildContext context) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            );
          },
        );
      }).toList(),
    );
  }



  // Seçenek Kartlarını oluşturuyoruz
  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? subWidget, // Bilgi ikonu için ek widget
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10), // Yuvarlak köşeler
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1), // Gölge rengi
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // Gölgenin pozisyonu
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60, // İkon boyutu
              color: Colors.blue, // İkon rengi
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                if (subWidget != null) ...[
                  const SizedBox(width: 5),
                  subWidget, // Ek bilgi ikonu
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Bilgi İkonunu Oluşturuyoruz
  Widget _buildInfoIcon(BuildContext context,
      {required String title, required String content}) {
    return IconButton(
      icon: const Icon(Icons.info_outline, color: Colors.blue, size: 20),
      tooltip: 'Bilgi',
      onPressed: () {
        // Bilgi dialogunu göster
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        );
      },
    );
  }
}