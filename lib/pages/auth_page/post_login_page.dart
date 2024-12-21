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

class _PostLoginPageState extends State<PostLoginPage>
    with TickerProviderStateMixin {
  final List<String> carouselImages = const [
    'assets/depomlablack.png',
    'assets/depomla.png',
  ];

  late AnimationController _alignmentController;
  late Animation<Alignment> _alignmentAnimation;

  late AnimationController _pageFadeController;
  late Animation<double> _pageFadeAnimation;

  // Define the custom color palette
  final Color primaryBlue =   Color.fromARGB(181, 43, 79, 169);
  final Color lightBlue = Color.fromARGB(200, 31, 101, 148);
  final Color darkBlue =     Color.fromARGB(168, 11, 63, 152);

               
                   
               
  @override
  void initState() {
    super.initState();

    // Fetch user data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider =
          Provider.of<UserProvider>(context, listen: false);
      userProvider.loadUserData();
    });

    // Banner alignment animation
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

    // Page fade-in animation
    _pageFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _pageFadeController, curve: Curves.easeIn),
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

    return FadeTransition(
      opacity: _pageFadeAnimation,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 219, 235, 249), // Changed to white for a cleaner look
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBanner(isUserLoggedIn, userProvider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 30.0),
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

  /// ----------- TOP BANNER -----------
  Widget _buildTopBanner(
      bool isUserLoggedIn, UserProvider userProvider) {
    final username = isUserLoggedIn
        ? userProvider.userModel!.email.split('@').first
        : null;

    return Column(
      children: [
        // White top section
        // Blue gradient banner
        AnimatedBuilder(
          animation: _alignmentAnimation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, lightBlue],
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
                        const Icon(
                          Icons.account_circle,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            'Hoşgeldin, $username',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                          'Depolama Çözümleri',
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black26,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Modern depolama ihtiyaçlarınız için güvenilir çözümler.',
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
        ),
      ],
    );
  }

  /// ----------- CAROUSEL SLIDER -----------
  Widget _buildCarouselSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        pauseAutoPlayOnTouch: true,
      ),
      items: carouselImages.map((imagePath) {
        return Builder(
          builder: (BuildContext context) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.4)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  /// ----------- KATEGORİ SEÇME ALANI (GRID) -----------
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
          icon: Icons.storage,
          label: 'Depola',
          color: primaryBlue,
          onTap: () =>
              _navigateToCategory(context, ListingType.deposit),
        ),
        _buildOptionCard(
          icon: Icons.store,
          label: 'Depolat',
          color: lightBlue,
          onTap: () =>
              _navigateToCategory(context, ListingType.storage),
        ),
        _buildOptionCard(
          icon: Icons.business_center,
          label: 'Depomla\nBusiness',
          color: darkBlue,
          onTap: () => _showComingSoonDialog(context),
        ),
        _buildOptionCard(
          icon: Icons.info_outline,
          label: 'Hangisini\nseçmeliyim?',
          color: primaryBlue,
          onTap: () => _showInfoDialog(context),
        ),
      ],
    );
  }

  /// ----------- OPTION CARD WIDGET -----------
  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: color,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color.darken(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ----------- Giriş Butonu -----------
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
        padding:
            const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: primaryBlue,
        elevation: 5,
        shadowColor: Colors.black38,
      ),
    );
  }

  /// ----------- Info Dialog -----------
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
                description:
                    'Ürünlerinizi güvenle saklamak için alan kiralamanıza olanak tanır.',
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                icon: Icons.check,
                title: 'Depolat',
                description:
                    'Depolama alanlarınızı başkalarına kiraya vermenizi sağlar.',
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                icon: Icons.business_center,
                title: 'Depomla Business',
                description:
                    'İşletmeler için özel depolama çözümleri sunar. Yakında hizmete açılacağız!',
              ),
              const SizedBox(height: 15),
              const Text(
                'Not: Depomla, bu hizmetleri doğrudan sağlamaz; kullanıcıları hizmet sunanlar ve talep edenlerle buluşturur.',
                style: TextStyle(
                    fontSize: 14, fontStyle: FontStyle.italic),
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

  /// ----------- INFO ROW WIDGET -----------
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
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
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

  /// ----------- Coming Soon Dialog -----------
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

  /// ----------- Kategoriyi Tıklayınca İlgili Sayfaya Geçiş -----------
  void _navigateToCategory(
      BuildContext context, ListingType category) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(selectedCategory: category),
      ),
    );
  }
}

/// ----------- COLOR EXTENSION -----------
extension ColorBrightness on Color {
  /// [amount] 0.0 => renk değişmez, 1.0 => tamamen siyah
  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }
}