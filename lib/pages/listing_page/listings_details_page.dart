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
import 'package:auto_size_text/auto_size_text.dart'; // AutoSizeText paketini ekliyoruz

class ListingDetailPage extends StatefulWidget {
  final Listing listing;
  const ListingDetailPage({Key? key, required this.listing}) : super(key: key);

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage>
    with SingleTickerProviderStateMixin {
  /// Firebase ve Servisler
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FavoriteService _favoriteService = FavoriteService();

  /// Sayfa Verileri
  UserModel? listingUser;
  bool isLoading = true;
  String? errorMessage;

  /// Favori Durumları
  bool isFavorite = false;
  bool isFavoriteLoading = false;
  int _currentImageIndex = 0;

  /// Animasyonlar
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  /// Renkler ve Stiller
  final Color kPrimaryColor = Color(0xFF2196F3); // Daha koyu mavi
  final Color kSecondaryColor = const Color.fromARGB(255, 48, 101, 144); // Açık mavi
  final Color kCardColor = Colors.white;
  final Color kIconColor = Colors.grey.shade700;

  

  @override
  void initState() {
    super.initState();
    _fetchListingDetails();
    _checkFavoriteStatus();

    /// Temel animasyon
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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

  //----------------------------------------------------------------------------
  // 1) Veri Çekme ve Durum Yönetimi
  //----------------------------------------------------------------------------

  /// İlan sahibinin bilgilerini Firestore'dan çeker
  Future<void> _fetchListingDetails() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.listing.userId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (!userDoc.exists) {
        setState(() {
          errorMessage = 'İlan sahibinin bilgilerine ulaşılamadı.';
          isLoading = false;
        });
        return;
      }

      listingUser = UserModel.fromDocument(userDoc);
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        errorMessage = 'Kullanıcı bilgileri alınırken bir hata oluştu.';
        isLoading = false;
      });
      debugPrint('İlan detayları çekilirken hata: $e');
    }
  }

  /// İlanın favori olup olmadığını kontrol eder
  Future<void> _checkFavoriteStatus() async {
    final favoriteStatus = await _favoriteService.isFavorite(widget.listing.id);
    setState(() {
      isFavorite = favoriteStatus;
    });
  }

  /// Favori durumunu değiştirir
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
      debugPrint('Favori işlemi sırasında hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favori işlemi sırasında bir hata oluştu: $e')),
      );
    } finally {
      setState(() => isFavoriteLoading = false);
    }
  }

  //----------------------------------------------------------------------------
  // 2) Mesajlaşma Akışı
  //----------------------------------------------------------------------------

  /// Kullanıcıyla mesajlaşma başlatır
  Future<void> _startChat() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      final shouldLogin = await showDialog<bool>(
            context: context,
            builder: (context) => _buildLoginAlertDialog(),
          ) ??
          false;

      if (shouldLogin) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
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

    // Kendi ilanınıza mesaj göndermeyi engeller
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
        builder: (context) => ChatPage(chatId: chatId, listing: widget.listing),
      ),
    );
  }

  //----------------------------------------------------------------------------
  // 3) Ana Widget Yapısı
  //----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        /// Profesyonel görünüm için gradient arka plan
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, kPrimaryColor.withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: isLoading
                ? _buildLoadingIndicator()
                : errorMessage != null
                    ? _buildErrorState()
                    : _buildContent(),
          ),
        ),
      ),
    );
  }

  //----------------------------------------------------------------------------
  // 4) Yükleme ve Hata Durumları
  //----------------------------------------------------------------------------

  /// Yükleniyor göstergesi
  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  /// Hata mesajı göstergesi
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          errorMessage!,
          style: GoogleFonts.poppins(color: Colors.red, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  //----------------------------------------------------------------------------
  // 5) Ana İçerik
  //----------------------------------------------------------------------------

  /// Ana içerik yapısı
  Widget _buildContent() {
    final currentUser = _auth.currentUser;
    final bool isOwnListing =
        currentUser != null && currentUser.uid == listingUser?.uid;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCarousel(),
                const SizedBox(height: 16),
                _buildTitleAndPrice(),
                const SizedBox(height: 8),
                _buildLocationAndDate(),
                const SizedBox(height: 16),
                if (!isOwnListing) _buildContactButton(),
                const SizedBox(height: 24),
                _buildDescriptionSection(),
                const SizedBox(height: 8),
                _buildEventDates(), // Başlangıç ve Bitiş Tarihleri
                const SizedBox(height: 24),
                _buildDetailSection(),
                const SizedBox(height: 24),
                if (listingUser != null) _buildUserInfo(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //----------------------------------------------------------------------------
  // 5a) Header - Geri Butonu ve Favori Butonu
  //----------------------------------------------------------------------------

  /// Header kısmını oluşturur (Geri butonu ve Favori butonu)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Geri butonu
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            ),
          ),

          /// Favori butonu
          GestureDetector(
            onTap: _toggleFavorite,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: isFavoriteLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.black,
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  //----------------------------------------------------------------------------
  // 6) Görsel Galeri (Carousel)
  //----------------------------------------------------------------------------

  /// Görsel galeriyi oluşturur
  Widget _buildImageCarousel() {
    if (widget.listing.imageUrl.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider.builder(
          itemCount: widget.listing.imageUrl.length,
          itemBuilder: (context, index, _) {
            final imageUrl = widget.listing.imageUrl[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImagePage(
                    imageUrls: widget.listing.imageUrl,
                    initialIndex: index,
                  ),
                ),
              ),
              child: Hero(
                tag: 'listingImage_${widget.listing.id}_$index',
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
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
            height: 300,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            enableInfiniteScroll: false,
            onPageChanged: (index, reason) {
              setState(() => _currentImageIndex = index);
            },
          ),
        ),
        Positioned(
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.listing.imageUrl.asMap().entries.map((entry) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentImageIndex == entry.key ? 12.0 : 8.0,
                  height: _currentImageIndex == entry.key ? 12.0 : 8.0,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 4.0,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? Colors.white
                        : Colors.white54,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  //----------------------------------------------------------------------------
  // 7) Başlık ve Fiyat
  //----------------------------------------------------------------------------

  /// Başlık ve fiyat bilgisini gösterir
  Widget _buildTitleAndPrice() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          /// Başlık
          Expanded(
            child: AutoSizeText(
              widget.listing.title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2, // Maksimum iki satır
              overflow: TextOverflow.ellipsis, // Gerekirse '...' ekle
            ),
          ),
          /// Fiyat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.listing.price.toStringAsFixed(2)} ₺',
              style: GoogleFonts.poppins(
                color: kPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //----------------------------------------------------------------------------
  // 8) Konum ve Tarih
  //----------------------------------------------------------------------------

  /// Konum ve ilan tarihini gösterir
  Widget _buildLocationAndDate() {
    final locationText = _getLocationText();
    final formattedDate =
        DateFormat('dd.MM.yyyy').format(widget.listing.createdAt.toDate());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          /// Konum İkonu ve Metni
          const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
          const SizedBox(width: 4),
          Expanded(
            child: AutoSizeText(
              locationText,
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          /// Tarih İkonu ve Metni
          const SizedBox(width: 2),
          const Icon(Icons.access_time_outlined, color: Colors.grey, size: 20),
          const SizedBox(width: 4),
          Text(
            formattedDate,
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  /// Konum bilgisini birleştirir
  String _getLocationText() {
    if (widget.listing.neighborhood != null &&
        widget.listing.district != null &&
        widget.listing.city != null) {
      return '${widget.listing.neighborhood}, '
          '${widget.listing.district}, '
          '${widget.listing.city}';
    }
    return 'Konum belirtilmemiş';
  }

  //----------------------------------------------------------------------------
  // 9) İletişime Geç Butonu
  //----------------------------------------------------------------------------

  /// İlan sahibiyle iletişime geçmek için buton
  Widget _buildContactButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        icon: const Icon(Icons.chat, color: Colors.white),
        label: Text(
          'İlan Sahibiyle İletişim',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: _startChat,
      ),
    );
  }

  //----------------------------------------------------------------------------
  // 10) Açıklama Bölümü
  //----------------------------------------------------------------------------

  /// İlan açıklamasını gösterir
  Widget _buildDescriptionSection() {
    final description = widget.listing.description.isNotEmpty
        ? widget.listing.description
        : 'Bu ilan için açıklama girilmemiş.';

    return _buildCardWrapper(
      title: 'Açıklama',
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: AutoSizeText(
          description,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.grey[800],
            height: 1.5,
          ),
          maxLines: 10, // Maksimum satır sayısı
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  //----------------------------------------------------------------------------
  // 5b) İlan Başlangıç ve Bitiş Tarihleri
  //----------------------------------------------------------------------------

  /// İlan başlangıç ve bitiş tarihlerini gösterir
  Widget _buildEventDates() {
    final DateTime? startDate = widget.listing.startDate;
    final DateTime? endDate = widget.listing.endDate;

    String startDateText = 'Başlangıç Tarihi: Belirtilmemiş';
    String endDateText = 'Bitiş Tarihi: Belirtilmemiş';

    if (startDate != null) {
      startDateText = 'Başlangıç Tarihi: ${DateFormat('dd.MM.yyyy').format(startDate)}';
    }

    if (endDate != null) {
      endDateText = 'Bitiş Tarihi: ${DateFormat('dd.MM.yyyy').format(endDate)}';
    }

    return _buildCardWrapper(
      title: 'Etkinlik Tarihleri',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            startDateText,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            endDateText,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  //----------------------------------------------------------------------------
  // 11) Detaylar Bölümü (İyileştirilmiş)
  //----------------------------------------------------------------------------

  /// İlan detaylarını gösterir ve gelişmiş detaylar ekler
  Widget _buildDetailSection() {
    return _buildCardWrapper(
      title: 'İlan Detayları',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Alan
          _buildDetailRowWithIcon(Icons.square_foot, 'Alan', widget.listing.size != null ? '${widget.listing.size} m²' : 'Belirtilmemiş'),
          const SizedBox(height: 8),

          /// Depolama Türü
          _buildDetailRowWithIcon(Icons.storage, 'Depolama Türü', widget.listing.storageType ?? 'Belirtilmemiş'),
          const SizedBox(height: 8),

          /// Özellikler
          _buildFeatureChips(
            title: 'Özellikler',
            features: widget.listing.features.entries
                .where((e) => e.value)
                .map((e) => e.key)
                .toList(),
            chipColor: kPrimaryColor,
          ),
          const SizedBox(height: 16),

          /// Eşya Türü
          _buildDetailRowWithIcon(Icons.category, 'Eşya Türü', widget.listing.itemType ?? 'Belirtilmemiş'),
          const SizedBox(height: 8),

          /// Ağırlık
          _buildDetailRowWithIcon(Icons.fitness_center, 'Ağırlık', widget.listing.itemWeight != null ? '${widget.listing.itemWeight} kg' : 'Belirtilmemiş'),
          const SizedBox(height: 8),

          /// Boyutlar
          _buildDetailRowWithIcon(Icons.straighten, 'Boyutlar', _getDimensionsText()),
          const SizedBox(height: 8),

          /// Sıcaklık Kontrolü
          _buildDetailRowWithIcon(Icons.thermostat, 'Sıcaklık Kontrolü', widget.listing.requiresTemperatureControl == true ? 'Gerekli' : 'Gerekli Değil'),
          const SizedBox(height: 8),

          /// Kuru Ortam
          _buildDetailRowWithIcon(Icons.water_drop, 'Kuru Ortam', widget.listing.requiresDryEnvironment == true ? 'Gerekli' : 'Gerekli Değil'),
          const SizedBox(height: 16),

          /// Sigorta
          _buildDetailRowWithIcon(Icons.security, 'Sigorta', widget.listing.insuranceRequired == true ? 'Gerekli' : 'Gerekli Değil'),
          const SizedBox(height: 8),

          /// Yasaklı Şartlar
          _buildFeatureChips(
            title: 'Yasaklı Şartlar',
            features: widget.listing.prohibitedConditions ?? [],
            chipColor: Colors.redAccent,
          ),
          const SizedBox(height: 16),

          /// Teslimat
          _buildDetailRowWithIcon(Icons.delivery_dining, 'Teslimat', widget.listing.deliveryDetails?.isNotEmpty == true ? widget.listing.deliveryDetails! : 'Belirtilmemiş'),
          const SizedBox(height: 8),

          /// Ek Notlar
          _buildDetailRowWithIcon(Icons.note, 'Ek Notlar', widget.listing.additionalNotes?.isNotEmpty == true ? widget.listing.additionalNotes! : 'Belirtilmemiş'),
          const SizedBox(height: 16),

          /// Tercih Edilen Özellikler
          _buildFeatureChips(
            title: 'Tercih Edilen Özellikler',
            features: widget.listing.preferredFeatures ?? [],
            chipColor: kSecondaryColor,
          ),
          const SizedBox(height: 16),

          // Ekstra Gelişmiş Detaylar
          _buildAdditionalInfoSection(),
        ],
      ),
    );
  }

  /// Ekstra gelişmiş detayları ekler
 Widget _buildAdditionalInfoSection() {
        return _buildCardWrapper(
          title: 'Ek Bilgiler',
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              getAdditionalInfoText(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        );
      }

      /// İlan türüne bağlı olarak ek bilgi metnini belirler
      String getAdditionalInfoText() {
        if (widget.listing.listingType == ListingType.deposit) {
          return 'İlan sahibi, eşyaların güvenli bir şekilde depolanmasını sağlamak için gerekli tüm önlemleri almıştır. Herhangi bir hasar durumunda sigorta kapsamında olup olmadığını lütfen ilan sahibine danışınız.';
        } else if (widget.listing.listingType == ListingType.storage) {
          return 'Depolayan kişi, eşyalarınızı güvenli ve özenli bir şekilde saklamak için gerekli tüm önlemleri almıştır. Herhangi bir sorun yaşamanız durumunda depolayan kişi ile iletişime geçebilirsiniz.';
        } else {
          return 'İlan detayları için ek bilgi bulunmamaktadır.';
        }
      }

  /// Detay satırını ikon ile oluşturur
  Widget _buildDetailRowWithIcon(IconData icon, String label, String text) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 20),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $text',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  /// Boyutlar metnini oluşturur
  String _getDimensionsText() {
    final dimensions = widget.listing.itemDimensions;
    if (dimensions != null) {
      final length = dimensions['length'] ?? '–';
      final width = dimensions['width'] ?? '–';
      final height = dimensions['height'] ?? '–';
      return 'Uzunluk: $length m, Genişlik: $width m, Yükseklik: $height m';
    }
    return 'Belirtilmemiş';
  }

  //----------------------------------------------------------------------------
  // 12) Bilgi Satırları ve Chip'ler
  //----------------------------------------------------------------------------

  /// Chip'leri oluşturur
  Widget _buildFeatureChips({
    required String title,
    required List<String> features,
    required Color chipColor,
  }) {
    if (features.isEmpty) {
      return Row(
        children: [
          Icon(Icons.block, color: kIconColor, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$title: Yok',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: features
              .map(
                (f) => Chip(
                  label: Text(f),
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  backgroundColor: chipColor.withOpacity(0.1),
                  side: BorderSide(color: chipColor),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  //----------------------------------------------------------------------------
  // 13) Kullanıcı Bilgileri
  //----------------------------------------------------------------------------

  /// İlan sahibinin bilgilerini gösterir
  Widget _buildUserInfo() {
    return _buildCardWrapper(
      title: 'İlan Sahibi',
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfilePage(user: listingUser!),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: (listingUser!.photoURL != null &&
                      listingUser!.photoURL!.isNotEmpty)
                  ? NetworkImage(listingUser!.photoURL!)
                  : const AssetImage('assets/images/default_avatar.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Kullanıcı adı
                  AutoSizeText(
                    listingUser!.displayName.isNotEmpty
                        ? listingUser!.displayName
                        : 'Kullanıcı',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  /// Kullanıcı puanı ve yorum sayısı
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '4.5⭐️',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.chat_bubble,
                          color: kSecondaryColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '16+💬',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  //----------------------------------------------------------------------------
  // 14) Giriş İçin AlertDialog
  //----------------------------------------------------------------------------

  /// Giriş yapma gerektiğini belirten AlertDialog
  AlertDialog _buildLoginAlertDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Giriş Yapmanız Gerekli',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mesaj gönderebilmek için önce hesabınıza giriş yapmalısınız. '
            'Giriş yapmak ister misiniz?',
            style: GoogleFonts.poppins(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Icon(Icons.login, size: 50, color: kPrimaryColor),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceAround,
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

  //----------------------------------------------------------------------------
  // 15) Kart Wrapper
  //----------------------------------------------------------------------------

  /// Kart benzeri bölümler için genel yapı
  Widget _buildCardWrapper({
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
            color: Colors.grey.shade300,
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Kart başlığı
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}