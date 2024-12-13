import 'package:depomla/models/listing_model.dart';
import 'package:flutter/material.dart';
import '../home_page.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class PostLoginPage extends StatefulWidget {
  const PostLoginPage({super.key});

  @override
  _PostLoginPageState createState() => _PostLoginPageState();
}

class _PostLoginPageState extends State<PostLoginPage> with TickerProviderStateMixin {
  final List<String> carouselImages = const [
    'assets/depomlablack.png',
    'assets/depomla.png',
  ];

  late AnimationController _alignmentController;
  late Animation<Alignment> _alignmentAnimation;

  late AnimationController _pageFadeController;
  late Animation<double> _pageFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Kullanıcı verilerini ilk frame'den sonra çek
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.loadUserData();
    });

    // Banner animasyonu
    _alignmentController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _alignmentAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(
      CurvedAnimation(
        parent: _alignmentController,
        curve: Curves.easeInOut,
      ),
    );

    // Sayfa fade-in animasyonu
    _pageFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageFadeController, curve: Curves.easeIn),
    );

    _pageFadeController.forward();
  }

  @override
  void dispose() {
    _alignmentController.dispose();
    _pageFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isUserLoggedIn = userProvider.userModel != null;

    final theme = Theme.of(context);
    final primaryColor = Colors.blueAccent.shade400;

    return FadeTransition(
      opacity: _pageFadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBanner(isUserLoggedIn, userProvider, primaryColor),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                  child: Column(
                    children: [
                      _buildCarouselSlider(),
                      const SizedBox(height: 30),
                      _buildOptionsGrid(context),
                      if (!isUserLoggedIn) ...[
                        const SizedBox(height: 30),
                        _buildLoginButton(context),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBanner(bool isUserLoggedIn, UserProvider userProvider, Color primaryColor) {
    final username = isUserLoggedIn ? userProvider.userModel!.email.split('@').first : null;

    return AnimatedBuilder(
      animation: _alignmentAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, Colors.blueAccent.shade100],
              begin: Alignment.topLeft,
              end: _alignmentAnimation.value,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: isUserLoggedIn
              ? Row(
                  children: [
                    const Icon(Icons.account_circle, size: 50, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hoşgeldin, $username',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 5,
                              color: Colors.black26,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Depomla',
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black26,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Depolama ihtiyaçlarınız için modern çözümler',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCarouselSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 180.0,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        autoPlayInterval: const Duration(seconds: 3),
      ),
      items: carouselImages.map((imagePath) {
        return Builder(
          builder: (BuildContext context) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.3)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildOptionsGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 600 ? 2 : 4;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildOptionCard(
          context: context,
          icon: Icons.storage,
          label: 'Depola',
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomePage(selectedCategory: ListingType.deposit),
              ),
            );
          },
        ),
        _buildOptionCard(
          context: context,
          icon: Icons.store,
          label: 'Depolat',
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomePage(selectedCategory: ListingType.storage),
              ),
            );
          },
        ),
        _buildOptionCard(
          context: context,
          icon: Icons.business_center,
          label: 'Depomla Business',
          onTap: () {
            _showComingSoonDialog(context);
          },
        ),
        _buildOptionCard(
          context: context,
          icon: Icons.info_outline,
          label: 'Hangisini seçmeliyim?',
          onTap: () {
            _showInfoDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 7,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
      icon: const Icon(Icons.login, size: 20),
      label: const Text(
        'Giriş Yap',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.blueAccent,
        elevation: 5,
        shadowColor: Colors.black38,
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
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
              _buildInfoRow(
                icon: Icons.check,
                title: 'Depola',
                description: 'Ürünlerinizi güvenle saklamak için alan kiralamanıza olanak tanır.',
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                icon: Icons.check,
                title: 'Depolat',
                description: 'Depolama alanlarınızı başkalarına kiraya vermenizi sağlar.',
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                icon: Icons.business_center,
                title: 'Depomla Business',
                description: 'İşletmeler için özel depolama çözümleri sunar. Yakında hizmete açılacağız!',
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
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Depomla Business'),
        content: const Text('Bu özellik yakında gelecek!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Kapat',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueAccent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}