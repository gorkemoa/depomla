// lib/pages/listing_page/listings_details_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../models/listing_model.dart';
import '../../models/user_model.dart';
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
  final Color primaryColor = const Color(0xFF02aee7);

  @override
  void initState() {
    super.initState();
    _fetchListingUser();
  }

  /// İlan sahibinin bilgilerini Firestore'dan çeker.
  Future<void> _fetchListingUser() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(widget.listing.userId).get();

      if (userDoc.exists) {
        setState(() {
          listingUser = UserModel.fromDocument(userDoc);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Kullanıcı bulunamadı.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Kullanıcı bilgileri alınırken bir hata oluştu.';
        isLoading = false;
      });
    }
  }

  /// Sohbet başlatma işlemi.
  Future<void> _startChat() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mesaj göndermek için giriş yapmalısınız.')),
      );
      return;
    }

    if (listingUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan sahibi bulunamadı.')),
      );
      return;
    }

    if (currentUser.uid == listingUser!.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendi ilanınıza mesaj gönderemezsiniz.')),
      );
      return;
    }

    // Benzersiz sohbet ID'si oluştur: Kullanıcı UID'leri + İlan ID
    String chatId =
        '${currentUser.uid}_${listingUser!.uid}_${widget.listing.id}';

    final chatRef = _firestore.collection('chats').doc(chatId);

    final chatDoc = await chatRef.get();

    // Eğer sohbet daha önce başlatılmamışsa, oluştur
    if (!chatDoc.exists) {
      await chatRef.set({
        'id': chatId,
        'participants': [currentUser.uid, listingUser!.uid],
        'listingId': widget.listing.id,
        'listingTitle': widget.listing.title,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Sohbet sayfasına yönlendir
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(chatId: chatId, listing: widget.listing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.listing.title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF02aee7), Color(0xFF00d0ea)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İlan Görselleri
                    _buildListingImages(),
                    // İçerik Bölümü
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              // İlan Başlığı ve Fiyat
                              _buildTitleAndPrice(),
                              const SizedBox(height: 10),
                              // Konum ve Tarih
                              _buildLocationAndDate(),
                              const SizedBox(height: 20),
                              // Açıklama
                              _buildDescription(),
                              const SizedBox(height: 20),
                              // Ek Detaylar
                              _buildAdditionalDetails(),
                              const SizedBox(height: 30),
                              // İlan Sahibi Bilgileri
                              if (listingUser != null) _buildListingUserInfo(),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Mesaj Gönder Butonu
                    _buildMessageButton(),
                  ],
                ),
    );
  }

  /// Çoklu ilan görsellerini gösteren widget (Carousel Slider kullanılarak).
  Widget _buildListingImages() {
    return Stack(
      children: [
        widget.listing.imageUrl.isNotEmpty
            ? CarouselSlider(
                options: CarouselOptions(
                  height: 300.0,
                  enableInfiniteScroll: false,
                  enlargeCenterPage: true,
                  viewportFraction: 1.0,
                ),
                items: widget.listing.imageUrl.map((imageUrl) {
                  return GestureDetector(
                    onTap: () {
                      // Görsel tıklandığında tam ekran göster
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImagePage(imageUrl: imageUrl),
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
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.grey.shade300,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.grey, size: 80),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )
            : Container(
                height: 300,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              ),
        // Favori Butonu (Opsiyonel)
        Positioned(
          top: 40,
          right: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.redAccent),
              onPressed: () {
                // Favori işlemleri
                _toggleFavorite();
              },
            ),
          ),
        ),
      ],
    );
  }

  /// İlan başlığı ve fiyatını gösteren widget.
  Widget _buildTitleAndPrice() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.listing.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
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
            style: TextStyle(
              color: primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Favori butonuna tıklandığında çalışacak metod.
  void _toggleFavorite() {
    // Favori ekleme/çıkarma işlemleri burada yapılabilir.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Favori işlemi henüz uygulanmadı.')),
    );
  }

  /// Konum ve tarih bilgilerini gösteren widget.
  Widget _buildLocationAndDate() {
    String location = '';
    if (widget.listing.city != null &&
        widget.listing.district != null &&
        widget.listing.neighborhood != null) {
      location =
          '${widget.listing.neighborhood}, ${widget.listing.district}, ${widget.listing.city}';
    } else {
      location = 'Konum belirtilmemiş';
    }

    return Row(
      children: [
        const Icon(Icons.location_on_outlined, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            location,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        const Icon(Icons.access_time_outlined, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          _formatDate(widget.listing.createdAt.toDate()),
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  /// İlan açıklamasını gösteren widget.
  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Açıklama',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.listing.description.isNotEmpty
              ? widget.listing.description
              : 'Açıklama bulunmamaktadır.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// Ek ilan detaylarını gösteren widget.
  Widget _buildAdditionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Boyut
        if (widget.listing.size != null)
          Row(
            children: [
              const Icon(Icons.square_foot, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '${widget.listing.size} m²',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        const SizedBox(height: 8),
        // Depolama Türü
        if (widget.listing.storageType != null &&
            widget.listing.storageType!.isNotEmpty)
          Row(
            children: [
              const Icon(Icons.storage, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                widget.listing.storageType!,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        const SizedBox(height: 8),
        // Özellikler
        if (widget.listing.features != null &&
            widget.listing.features!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Özellikler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: widget.listing.features!.entries
                    .where((entry) => entry.value)
                    .map((entry) => Chip(
                          label: Text(entry.key),
                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                        ))
                    .toList(),
              ),
            ],
          ),
        const SizedBox(height: 8),
        // Başlangıç Tarihi
        if (widget.listing.startDate != null &&
            widget.listing.startDate!.isNotEmpty)
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Başlangıç: ${widget.listing.startDate}',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        const SizedBox(height: 8),
        // Bitiş Tarihi
        if (widget.listing.endDate != null &&
            widget.listing.endDate!.isNotEmpty)
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Bitiş: ${widget.listing.endDate}',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
      ],
    );
  }

  /// İlan sahibinin bilgilerini gösteren widget.
  Widget _buildListingUserInfo() {
    return GestureDetector(
      onTap: () {
        // Kullanıcı profil sayfasına yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfilePage(user: listingUser!),
          ),
        );
      },
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Padding azaltıldı
          child: Row(
            children: [
              CircleAvatar(
                radius: 24, // Daha küçük bir radius
                backgroundImage: listingUser!.photoURL != null &&
                        listingUser!.photoURL!.isNotEmpty
                    ? NetworkImage(listingUser!.photoURL!)
                    : const AssetImage('assets/default_avatar.png')
                        as ImageProvider,
              ),
              const SizedBox(width: 10), // Boşluk biraz azaltıldı
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listingUser!.displayName.isNotEmpty
                          ? listingUser!.displayName
                          : 'Kullanıcı',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold), // Font boyutu küçültüldü
                    ),
                    const SizedBox(height: 3), // Boşluk biraz azaltıldı
                    Text(
                      listingUser!.email.isNotEmpty
                          ? listingUser!.email
                          : 'Email bulunmamaktadır.',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600]), // Font boyutu küçültüldü
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey), // İkon boyutu küçültüldü
            ],
          ),
        ),
      ),
    );
  }

  /// Mesaj gönderme butonunu gösteren widget.
  Widget _buildMessageButton() {
    final currentUser = _auth.currentUser;

    // Eğer kullanıcı kendi ilanını görüntülüyorsa
    bool isOwnListing =
        currentUser != null && currentUser.uid == listingUser?.uid;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: isOwnListing
              ? null // Kendi ilanına mesaj gönderilemez
              : _startChat,
          style: ElevatedButton.styleFrom(
            backgroundColor: isOwnListing ? Colors.grey : primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: isOwnListing ? 0 : 1,
            shadowColor: isOwnListing
                ? Colors.transparent
                : primaryColor.withOpacity(0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOwnListing ? Icons.error_outline : Icons.message,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isOwnListing
                    ? 'Bu ilan size ait, mesaj gönderemezsiniz'
                    : 'Mesaj Gönder',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarih formatlama metod.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}