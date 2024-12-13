// lib/pages/listing_page/listing_detail_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/listing_model.dart';
import '../../models/user_model.dart';
import '../auth_page/login_page.dart';
import '../comment_page/chat_page.dart';
import '../profil_page/user_profile_page.dart';
import '../comment_page/full_screen_image_page.dart';

class ListingDetailPage extends StatefulWidget {
  final Listing listing;

  const ListingDetailPage({Key? key, required this.listing}) : super(key: key);

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  UserModel? listingUser;
  bool isLoading = true;
  String? errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Renk Paleti (Daha ferah, soft tonlar)
  final Color primaryColor = const Color(0xFF4B9CE2);
  final Color secondaryColor = const Color(0xFF66B7F0);
  final Color backgroundColor = const Color(0xFFF0F4F8);
  final Color cardColor = Colors.white;
  final Color iconColor = Colors.grey.shade600;

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchListingDetails();
  }

  /// İlan ve kullanıcı detaylarını çeken method
  Future<void> _fetchListingDetails() async {
    try {
      // İlan sahibinin bilgilerini al
      DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore
          .collection('users')
          .doc(widget.listing.userId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (userDoc.exists) {
        listingUser = UserModel.fromDocument(userDoc);
      } else {
        errorMessage = 'İlan sahibinin bilgilerine ulaşılamadı.';
        setState(() {
          isLoading = false;
        });
        return;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Kullanıcı bilgileri alınırken bir hata oluştu.';
        isLoading = false;
      });
      print('Error fetching listing details: $e');
    }
  }

  Future<void> _startChat() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      bool shouldLogin = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Giriş Yapmanız Gerekli',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mesaj gönderebilmek için önce hesabınıza giriş yapmalısınız. Giriş yapmak ister misiniz?',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Icon(Icons.login, size: 50, color: primaryColor),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Vazgeç',
                style: TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(
                'Giriş Yap',
                style: TextStyle(color: primaryColor, fontSize: 16),
              ),
            ),
          ],
        ),
      );

      if (shouldLogin) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
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

    if (currentUser.uid == listingUser!.uid) {
      // Kullanıcı kendi ilanını görüntülüyor, butonu göstermiyoruz
      return;
    }

    String chatId =
        '${currentUser.uid}_${listingUser!.uid}_${widget.listing.id}';

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

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    bool isOwnListing =
        currentUser != null && currentUser.uid == listingUser?.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: isLoading
          ? _buildLoadingIndicator()
          : errorMessage != null
              ? _buildErrorState()
              : _buildContent(isOwnListing),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        widget.listing.title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      elevation: 2,
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: primaryColor,
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text(
        errorMessage!,
        style: const TextStyle(color: Colors.red, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildContent(bool isOwnListing) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListingImages(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleAndPrice(),
                const SizedBox(height: 16),
                _buildLocationSection(),
                const SizedBox(height: 16),
                if (!isOwnListing) _buildMessageButton(),
                const SizedBox(height: 16),
                _buildDescriptionSection(),
                const SizedBox(height: 16),
                _buildDetailsSection(),
                const SizedBox(height: 24),
                if (listingUser != null) _buildListingUserInfo(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingImages() {
    return widget.listing.imageUrl.isNotEmpty
        ? Stack(
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  height: 300.0,
                  enableInfiniteScroll: false,
                  enlargeCenterPage: true,
                  viewportFraction: 1.0,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                ),
                items: widget.listing.imageUrl.map((imageUrl) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FullScreenImagePage(imageUrl: imageUrl),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'listingImage_${widget.listing.id}_$imageUrl',
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero, // Geçiş efektini kaldır
                        fadeOutDuration: Duration.zero, // Geçiş efektini kaldır
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.grey.shade300,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      widget.listing.imageUrl.asMap().entries.map((entry) {
                    return Container(
                      width: 12.0,
                      height: 12.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == entry.key
                            ? primaryColor
                            : Colors.grey,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          )
        : Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor),
            ),
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 80,
                color: Colors.grey,
              ),
            ),
          );
  }

  Widget _buildTitleAndPrice() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.listing.title,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${widget.listing.price.toStringAsFixed(2)} ₺',
            style: GoogleFonts.poppins(
              color: primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Konum bilgilerini daha şık bir şekilde sunan widget
  Widget _buildLocationSection() {
    String location = '';
    if (widget.listing.neighborhood != null &&
        widget.listing.district != null &&
        widget.listing.city != null) {
      location =
          '${widget.listing.neighborhood}, ${widget.listing.district}, ${widget.listing.city}';
    } else {
      location = 'Konum belirtilmemiş';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on_outlined, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                location,
                style: TextStyle(fontSize: 16, color: iconColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.access_time_outlined, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Text(
              'İlan Tarihi: ${_formatDate(widget.listing.createdAt.toDate())}',
              style: TextStyle(fontSize: 16, color: iconColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Açıklama',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            widget.listing.description.isNotEmpty
                ? widget.listing.description
                : 'Açıklama bulunmamaktadır.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İlan Detayları',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        _buildAdditionalDetails(),
      ],
    );
  }

  Widget _buildAdditionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.listing.size != null) ...[
          _buildDetailRow(Icons.square_foot, '${widget.listing.size} m²'),
          const SizedBox(height: 12),
        ],
        if (widget.listing.storageType != null &&
            widget.listing.storageType!.isNotEmpty) ...[
          _buildDetailRow(Icons.storage, widget.listing.storageType!),
          const SizedBox(height: 12),
        ],
        if (widget.listing.features != null &&
            widget.listing.features!.isNotEmpty) ...[
          const Text(
            'Özellikler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: widget.listing.features!.entries
                .where((entry) => entry.value)
                .map((entry) => Chip(
                      label: Text(entry.key),
                      backgroundColor: primaryColor.withOpacity(0.1),
                      side: BorderSide(color: primaryColor),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.listing.startDate != null &&
            widget.listing.startDate!.isNotEmpty) ...[
          _buildDetailRow(
              Icons.calendar_today, 'Başlangıç: ${widget.listing.startDate}'),
          const SizedBox(height: 12),
        ],
        if (widget.listing.endDate != null &&
            widget.listing.endDate!.isNotEmpty) ...[
          _buildDetailRow(
              Icons.calendar_today, 'Bitiş: ${widget.listing.endDate}'),
          const SizedBox(height: 20),
        ],
        _buildNewListingDetails(),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildNewListingDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.listing.itemType != null &&
            widget.listing.itemType!.isNotEmpty) ...[
          _buildDetailRow(
              Icons.category, 'Eşya Türü: ${widget.listing.itemType}'),
          const SizedBox(height: 12),
        ],
        if (widget.listing.itemDimensions != null) ...[
          _buildDetailRow(
              Icons.straighten,
              'Boyutlar: ${widget.listing.itemDimensions!['length']}m x '
              '${widget.listing.itemDimensions!['width']}m x '
              '${widget.listing.itemDimensions!['height']}m'),
          const SizedBox(height: 12),
        ],
        if (widget.listing.itemWeight != null) ...[
          _buildDetailRow(
              Icons.fitness_center, 'Ağırlık: ${widget.listing.itemWeight} kg'),
          const SizedBox(height: 12),
        ],
        if (widget.listing.requiresTemperatureControl != null) ...[
          _buildDetailRow(
              Icons.thermostat_outlined,
              'Sıcaklık Kontrolü: '
              '${widget.listing.requiresTemperatureControl! ? 'Gerekiyor' : 'Gerekmiyor'}'),
          const SizedBox(height: 12),
        ],
        if (widget.listing.requiresDryEnvironment != null) ...[
          _buildDetailRow(
              Icons.water_drop_outlined,
              'Kuru Ortam: '
              '${widget.listing.requiresDryEnvironment! ? 'Gerekiyor' : 'Gerekmiyor'}'),
          const SizedBox(height: 12),
        ],
        if (widget.listing.insuranceRequired != null) ...[
          _buildDetailRow(Icons.security,
              'Sigorta Gerekiyor: ${widget.listing.insuranceRequired! ? 'Evet' : 'Hayır'}'),
          const SizedBox(height: 12),
        ],
        if (widget.listing.prohibitedConditions != null &&
            widget.listing.prohibitedConditions!.isNotEmpty) ...[
          const Text(
            'Yasaklı Şartlar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: widget.listing.prohibitedConditions!.map((condition) {
              return Chip(
                label: Text(condition),
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                side: const BorderSide(color: Colors.redAccent),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.listing.ownerPickup != null) ...[
          _buildDetailRow(Icons.local_shipping,
              'Eşyayı Depolayan Teslim Alır: ${widget.listing.ownerPickup! ? 'Evet' : 'Hayır'}'),
          const SizedBox(height: 12),
        ],
        if (widget.listing.deliveryDetails != null &&
            widget.listing.deliveryDetails!.isNotEmpty) ...[
          const Text(
            'Teslimat Detayları',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            widget.listing.deliveryDetails!,
            style: const TextStyle(
                fontSize: 16, color: Colors.black87, height: 1.6),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.listing.additionalNotes != null &&
            widget.listing.additionalNotes!.isNotEmpty) ...[
          const Text(
            'Ek Notlar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            widget.listing.additionalNotes!,
            style: const TextStyle(
                fontSize: 16, color: Colors.black87, height: 1.6),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.listing.preferredFeatures != null &&
            widget.listing.preferredFeatures!.isNotEmpty) ...[
          const Text(
            'Tercih Edilen Özellikler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: widget.listing.preferredFeatures!.map((feature) {
              return Chip(
                label: Text(feature),
                backgroundColor: primaryColor.withOpacity(0.1),
                side: BorderSide(color: primaryColor),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildListingUserInfo() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => UserProfilePage(user: listingUser!)),
        );
      },
      child: Card(
        color: cardColor,
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: listingUser!.photoURL != null &&
                        listingUser!.photoURL!.isNotEmpty
                    ? NetworkImage(listingUser!.photoURL!)
                    : const AssetImage('assets/default_avatar.png')
                        as ImageProvider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listingUser!.displayName.isNotEmpty
                          ? listingUser!.displayName
                          : 'Kullanıcı',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                           '(4.5⭐️ , 16+💬)',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageButton() {
    return ElevatedButton(
      onPressed: _startChat,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        shadowColor: primaryColor.withOpacity(0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.message,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'İlan Sahibiyle İletişime Geç',
            style: TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
