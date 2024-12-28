import 'dart:math' as math;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:depomla/models/listing_model.dart';
import 'package:depomla/models/user_model.dart';
import 'package:depomla/pages/auth_page/login_page.dart';
import 'package:depomla/pages/comment_page/chat_page.dart';
import 'package:depomla/pages/comment_page/full_screen_image_page.dart';
import 'package:depomla/pages/profil_page/user_profile_page.dart';
import 'package:depomla/services/favorite_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Yeni tasarımlı ListingDetailPage
class ListingDetailPage extends StatefulWidget {
  final Listing listing;
  const ListingDetailPage({Key? key, required this.listing}) : super(key: key);

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage>
    with SingleTickerProviderStateMixin {
  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FavoriteService _favoriteService = FavoriteService();

  // Kullanıcı bilgileri
  UserModel? listingUser;

  // Durumlar
  bool isLoading = true;
  String? errorMessage;
  bool isFavorite = false;
  bool isFavoriteLoading = false;
  int _currentImageIndex = 0;

  // Animasyon
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  // Temel Renkler
  final Color kPrimaryColor = const Color(0xFF2196F3); 
  final Color kSecondaryColor = const Color.fromARGB(255, 48, 101, 144);
  final Color kCardColor = Colors.white;
  final Color kIconColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _fetchListingDetails();
    _checkFavoriteStatus();

    // Basit fade-in animasyonu
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --------------------- 1) Firestore / Favorite Check ------------------------

  Future<void> _fetchListingDetails() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.listing.userId)
          .get();

      if (!userDoc.exists) {
        setState(() {
          errorMessage = 'İlan sahibine ulaşılamadı.';
          isLoading = false;
        });
        return;
      }
      listingUser = UserModel.fromDocument(userDoc);
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        errorMessage = 'Kullanıcı bilgisi çekilirken bir hata oluştu.';
        isLoading = false;
      });
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final favoriteStatus = await _favoriteService.isFavorite(widget.listing.id);
    setState(() => isFavorite = favoriteStatus);
  }

  Future<void> _toggleFavorite() async {
    setState(() => isFavoriteLoading = true);
    try {
      if (isFavorite) {
        await _favoriteService.removeFavorite(widget.listing.id);
      } else {
        await _favoriteService.addFavorite(widget.listing.id);
      }
      setState(() => isFavorite = !isFavorite);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favori işlemi hatası: $e')),
      );
    } finally {
      setState(() => isFavoriteLoading = false);
    }
  }

  // ------------------------- 2) Chat Başlatma -------------------------------

  Future<void> _startChat() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      final shouldLogin = await showDialog<bool>(
            context: context,
            builder: (_) => _buildLoginAlertDialog(),
          ) ??
          false;
      if (shouldLogin) {
        // Login'e gönder
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
      return;
    }
    if (listingUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan sahibi bulunamadı.')),
      );
      return;
    }
    // Kendi ilanınıza mesaj atamazsınız
    if (currentUser.uid == listingUser!.uid) return;

    final chatId = '${currentUser.uid}_${listingUser!.uid}_${widget.listing.id}';
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'id': chatId,
        'participants': [currentUser.uid, listingUser!.uid],
        'listingId': widget.listing.id,
        'listingTitle': widget.listing.title,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(chatId: chatId, listing: widget.listing),
      ),
    );
  }

  // --------------------------- 3) Scaffold / UI -----------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: isLoading
            ? _buildLoadingIndicator()
            : errorMessage != null
                ? _buildErrorState()
                : _buildSliverView(context),
      ),
    );
  }

  /// Modern SliverAppBar / SliverList yapısı
  Widget _buildSliverView(BuildContext context) {
    final bool isOwnListing = 
        _auth.currentUser?.uid == listingUser?.uid;

    return CustomScrollView(
      slivers: [
        // SliverAppBar (resim galerisi arkaplanda kayıyor)
        SliverAppBar(
          expandedHeight: 320.0,
          pinned: true,
          floating: false,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            isFavoriteLoading
                ? const Padding(
                    padding: EdgeInsets.all(14.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.black,
                    ),
                    onPressed: _toggleFavorite,
                  ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildCarouselHeader(),
          ),
        ),

        // SliverList: Detay içerik
        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 16),
            _buildTitleAndPrice(),
            const SizedBox(height: 8),
            _buildLocationAndDate(),
            const SizedBox(height: 16),
            if (!isOwnListing) _buildContactButton(),
            const SizedBox(height: 24),
            _buildDescriptionSection(),
            _buildEventDates(),
            const SizedBox(height: 16),
            _buildDetailSection(),
            const SizedBox(height: 16),
            if (listingUser != null) _buildUserInfo(),
            const SizedBox(height: 40),
          ]),
        ),
      ],
    );
  }

  // --------------------------- 4) Parça Widgetlar ---------------------------

  /// SliverAppBar arkasında dönen Carousel + Dot Indicator
  Widget _buildCarouselHeader() {
    final images = widget.listing.imageUrl;
    if (images.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(
            Icons.image_not_supported, 
            size: 80, 
            color: Colors.grey),
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider.builder(
          itemCount: images.length,
          itemBuilder: (context, index, _) {
            final imageUrl = images[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImagePage(
                    imageUrls: images,
                    initialIndex: index,
                  ),
                ),
              ),
              child: Hero(
                tag: 'listingImage_${widget.listing.id}_$index',
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 80,
                    ),
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: double.infinity,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() => _currentImageIndex = index);
            },
          ),
        ),
        _buildDotIndicator(images.length),
      ],
    );
  }

  /// Dot Indicator
  Widget _buildDotIndicator(int length) {
    if (length < 2) return const SizedBox.shrink();

    return Positioned(
      bottom: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (index) {
            final bool isActive = index == _currentImageIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 12 : 8,
              height: isActive ? 12 : 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white54,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Yükleniyor göstergesi
  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Hata Durumu
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          errorMessage ?? 'Bir hata oluştu.',
          style: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Başlık + Fiyat
  Widget _buildTitleAndPrice() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: AutoSizeText(
              widget.listing.title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.listing.price.toStringAsFixed(2)} ₺',
              style: GoogleFonts.poppins(
                color: kPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Konum + Oluşturulma Tarihi
  Widget _buildLocationAndDate() {
    final dateStr = DateFormat('dd.MM.yyyy')
        .format(widget.listing.createdAt.toDate());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _getFullLocation(),
              style: GoogleFonts.poppins(
                fontSize:15,
                color: const Color.fromARGB(221, 14, 82, 170),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 4,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.access_time_outlined, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            dateStr,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  String _getFullLocation() {
    final n = widget.listing.neighborhood;
    final d = widget.listing.district;
    final c = widget.listing.city;
    if (n != null && d != null && c != null) {
      return '$n, $d, $c';
    }
    return 'Konum Belirtilmemiş';
  }

  /// İlan sahibiyle iletişime geç butonu
  Widget _buildContactButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.chat),
        label: Text(
          'İlan Sahibiyle İletişim',
          style: GoogleFonts.poppins(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _startChat,
      ),
    );
  }

  /// Açıklama alanı
  Widget _buildDescriptionSection() {
    final desc = widget.listing.description.isNotEmpty
        ? widget.listing.description
        : 'Açıklama girilmemiş.';
    return _cardWrapper(
      title: 'Açıklama',
      child: Text(
        desc,
        style: GoogleFonts.poppins(
          fontSize: 14, 
          height: 1.5, 
          color: Colors.grey[800]
        ),
      ),
    );
  }

  /// Başlangıç & Bitiş tarihleri
  Widget _buildEventDates() {
    final start = widget.listing.startDate;
    final end = widget.listing.endDate;

    final startText = start != null
        ? 'Başlangıç: ${DateFormat('dd.MM.yyyy').format(start)}'
        : 'Başlangıç: Belirtilmemiş';

    final endText = end != null
        ? 'Bitiş: ${DateFormat('dd.MM.yyyy').format(end)}'
        : 'Bitiş: Belirtilmemiş';

    return _cardWrapper(
      title: 'Etkinlik Tarihleri',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(startText, style: GoogleFonts.poppins(fontSize: 14)),
          const SizedBox(height: 6),
          Text(endText, style: GoogleFonts.poppins(fontSize: 14)),
        ],
      ),
    );
  }

  /// İlan detayları
  Widget _buildDetailSection() {
    return _cardWrapper(
      title: 'İlan Detayları',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alan (Sadece Storage ise)
          if (widget.listing.listingType == ListingType.storage)
            _buildDetailRowWithIcon(
              Icons.square_foot,
              'Alan',
              widget.listing.size != null 
                  ? '${widget.listing.size} m²' 
                  : 'Belirtilmemiş',
            ),
          const SizedBox(height: 8),

          // Storage
          if (widget.listing.listingType == ListingType.storage) ...[
            _buildStorageDetails(),
          ],

          // Deposit
          if (widget.listing.listingType == ListingType.deposit) ...[
            _buildDepositDetails(),
          ],

          // Ek Bilgiler
          _buildAdditionalInfoSection(),
        ],
      ),
    );
  }

  Widget _buildStorageDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRowWithIcon(
          Icons.storage,
          'Depolama Türü',
          widget.listing.storageType ?? 'Belirtilmemiş',
        ),
        const SizedBox(height: 8),
        _buildFeatureChips(
          title: 'Özellikler',
          features: widget.listing.features.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList(),
          chipColor: kPrimaryColor,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDepositDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRowWithIcon(
          Icons.category,
          'Eşya Türü',
          widget.listing.itemType ?? 'Belirtilmemiş',
        ),
        const SizedBox(height: 8),
        _buildDetailRowWithIcon(
          Icons.fitness_center,
          'Ağırlık',
          widget.listing.itemWeight != null 
              ? '${widget.listing.itemWeight} kg'
              : 'Belirtilmemiş',
        ),
        const SizedBox(height: 8),
        _buildDetailRowWithIcon(
          Icons.straighten,
          'Boyutlar',
          _getDimensionsText(),
        ),
        const SizedBox(height: 8),
        _buildDetailRowWithIcon(
          Icons.thermostat,
          'Sıcaklık Kontrolü',
          widget.listing.requiresTemperatureControl == true
              ? 'Gerekli'
              : 'Gerekli Değil',
        ),
        const SizedBox(height: 8),
        _buildDetailRowWithIcon(
          Icons.water_drop,
          'Kuru Ortam',
          widget.listing.requiresDryEnvironment == true 
              ? 'Gerekli'
              : 'Gerekli Değil',
        ),
        const SizedBox(height: 16),
        _buildDetailRowWithIcon(
          Icons.security,
          'Sigorta',
          widget.listing.insuranceRequired == true
              ? 'Gerekli'
              : 'Gerekli Değil',
        ),
        const SizedBox(height: 8),
        _buildFeatureChips(
          title: 'Yasaklı Şartlar',
          features: widget.listing.prohibitedConditions ?? [],
          chipColor: Colors.redAccent,
        ),
        const SizedBox(height: 16),
        _buildDetailRowWithIcon(
          Icons.delivery_dining,
          'Teslimat',
          widget.listing.deliveryDetails?.isNotEmpty == true
              ? widget.listing.deliveryDetails!
              : 'Belirtilmemiş',
        ),
        const SizedBox(height: 8),
        _buildDetailRowWithIcon(
          Icons.note,
          'Ek Notlar',
          widget.listing.additionalNotes?.isNotEmpty == true
              ? widget.listing.additionalNotes!
              : 'Belirtilmemiş',
        ),
        const SizedBox(height: 16),
        _buildFeatureChips(
          title: 'Tercih Edilen Özellikler',
          features: widget.listing.preferredFeatures ?? [],
          chipColor: kSecondaryColor,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getDimensionsText() {
    final dims = widget.listing.itemDimensions;
    if (dims != null) {
      final l = dims['length'] ?? '–';
      final w = dims['width'] ?? '–';
      final h = dims['height'] ?? '–';
      return 'Uzunluk: $l m, Genişlik: $w m, Yükseklik: $h m';
    }
    return 'Belirtilmemiş';
  }

  /// Ortak satır stili
  Widget _buildDetailRowWithIcon(IconData icon, String label, String text) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 20),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $text',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  /// Chip set
  Widget _buildFeatureChips({
    required String title,
    required List<String> features,
    required Color chipColor,
  }) {
    if (features.isEmpty) {
      return Row(
        children: [
          Icon(Icons.block, color: Colors.grey.shade600, size: 18),
          const SizedBox(width: 6),
          Text(
            '$title: Yok',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14, 
            fontWeight: FontWeight.w600
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: features.map((f) {
            return Chip(
              label: Text(f, style: GoogleFonts.poppins(fontSize: 13)),
              backgroundColor: chipColor.withOpacity(0.1),
              side: BorderSide(color: chipColor),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Ek Bilgi
  Widget _buildAdditionalInfoSection() {
    return _cardWrapper(
      title: 'Ek Bilgiler',
      child: Text(
        getAdditionalInfoText(),
        style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
      ),
    );
  }

  String getAdditionalInfoText() {
    if (widget.listing.listingType == ListingType.deposit) {
      return 'Eşyalarınız için gerekli tüm önlemler alınmış olup, sigorta konusunu ilan sahibiyle görüşebilirsiniz.';
    } else if (widget.listing.listingType == ListingType.storage) {
      return 'Depolayan kişi, eşyalarınızı güvenli ve özenli şekilde saklamak için gerekli tüm önlemleri almaktadır.';
    }
    return 'Ek bilgi bulunmamaktadır.';
  }

  Widget _cardWrapper({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  /// İlan sahibi bilgisi
  Widget _buildUserInfo() {
    return _cardWrapper(
      title: 'İlan Sahibi',
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfilePage(user: listingUser!),
            ),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: (listingUser!.photoURL?.isNotEmpty ?? false)
                  ? NetworkImage(listingUser!.photoURL!)
                  : const AssetImage('assets/images/default_avatar.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    listingUser!.displayName.isEmpty 
                        ? 'Kullanıcı' 
                        : listingUser!.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade700, size: 16),
                      const SizedBox(width: 4),
                      Text('4.5',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          )),
                      const SizedBox(width: 16),
                      const Icon(Icons.chat_bubble, color: Colors.blueAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '16+ Yorum',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  /// Giriş Yap AlertDialog
  AlertDialog _buildLoginAlertDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Giriş Yapmanız Gerekli',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mesaj göndermek için giriş yapmalısınız.\nGiriş yapmak ister misiniz?',
            style: GoogleFonts.poppins(fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Icon(Icons.login, size: 50, color: kPrimaryColor),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Vazgeç',
            style: GoogleFonts.poppins(
              color: Colors.redAccent,
              fontSize: 16,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Giriş Yap',
            style: GoogleFonts.poppins(
              color: kPrimaryColor,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}