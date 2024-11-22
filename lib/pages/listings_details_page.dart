import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import 'chat_page.dart';
import 'user_profile_page.dart';
import 'full_screen_image_page.dart';

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

 Future<void> _fetchListingUser() async {
  try {
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await _firestore.collection('users').doc(widget.listing.userId).get();

    if (userDoc.exists) {
      setState(() {
        listingUser = UserModel.fromDocument(userDoc); // fromDocument kullanımı
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
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                    _buildListingImage(),
                    // İçerik Bölümü
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              // İlan Başlığı
                              Text(
                                widget.listing.title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Konum ve Tarih
                              _buildLocationAndDate(),
                              const SizedBox(height: 20),
                              // Açıklama
                              _buildDescription(),
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

  Widget _buildListingImage() {
    return GestureDetector(
      onTap: () {
        // Görsel tıklandığında tam ekran göster
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FullScreenImagePage(imageUrl: widget.listing.imageUrl),
          ),
        );
      },
      child: Stack(
        children: [
          // Arka plan görseli
          Hero(
            tag: 'listingImage_${widget.listing.id}',
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(2),
              ),
              child: widget.listing.imageUrl != null &&
                      widget.listing.imageUrl!.isNotEmpty
                  ? FadeInImage.assetNetwork(
                      placeholder: 'assets/loading.gif',
                      image: widget.listing.imageUrl!,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Container(
                          height:
                              300, // Görüntü yüksekliğiyle uyumlu hale getirildi
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        );
                      },
                      placeholderFit:
                          BoxFit.scaleDown, // Placeholder küçültüldü
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
            ),
          ),
          // Fiyat Etiketi
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.listing.price.toStringAsFixed(2)} ₺',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Favori Butonu
          Positioned(
            top: 40,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              child: IconButton(
                icon:
                    const Icon(Icons.favorite_border, color: Colors.redAccent),
                onPressed: () {
                  // Favori işlemleri
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAndDate() {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Konum belirtilmemiş',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        const Icon(Icons.access_time_outlined, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          _formatDate(widget.listing.createdAt?.toDate()),
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

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
          widget.listing.description ?? 'Açıklama bulunmamaktadır.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

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
                      listingUser!.displayName ?? 'Kullanıcı',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold), // Font boyutu küçültüldü
                    ),
                    const SizedBox(height: 3), // Boşluk biraz azaltıldı
                    Text(
                      listingUser!.email ?? '',
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

  Widget _buildMessageButton() {
  final currentUser = _auth.currentUser;

  // Eğer kullanıcı kendi ilanını görüntülüyorsa
  bool isOwnListing = currentUser != null && currentUser.uid == listingUser?.uid;

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

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}.${date.month}.${date.year}';
  }
}
