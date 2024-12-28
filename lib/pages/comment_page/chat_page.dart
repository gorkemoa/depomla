// lib/pages/comment_page/chat_page.dart

import 'package:depomla/pages/profil_page/user_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/listing_model.dart';
import '../../models/user_model.dart';
import '../listing_page/listing_picker_bottom_sheet.dart';
import '../listing_page/listings_details_page.dart';
import '../profil_page/profile_page.dart'; // Doğru dosya yolunu kullanın

class ChatPage extends StatefulWidget {
  final String chatId;
  final Listing listing;

  const ChatPage({Key? key, required this.chatId, required this.listing})
      : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Diğer kullanıcının bilgileri
  String otherUserName = 'Sohbet';
  String otherUserPhotoUrl = '';
  String otherUserId = '';

  /// Performans amaçlı kullanıcıları ve ilanları tutmak için önbellek
  final Map<String, UserModel> _userCache = {};
  final Map<String, Listing> _listingCache = {};

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _fetchOtherUserData();
  }

  /// Gelen, okunmamış mesajları işaretler
  Future<void> _markMessagesAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final unreadMessages = await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('receiverId', isEqualTo: currentUser.uid)
        .get();

    if (unreadMessages.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Sohbet ettiğimiz diğer kullanıcının verilerini çeker
  Future<void> _fetchOtherUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    DocumentSnapshot<Map<String, dynamic>> chatDoc =
        await _firestore.collection('chats').doc(widget.chatId).get();
    if (!chatDoc.exists) return;

    List<dynamic> participants = chatDoc.data()?['participants'] ?? [];
    String fetchedOtherUserId = participants.firstWhere(
      (id) => id != currentUser.uid,
      orElse: () => '',
    );
    if (fetchedOtherUserId.isEmpty) return;

    // Kullanıcı önbelleğimizde yoksa Firestore'dan çek
    if (!_userCache.containsKey(fetchedOtherUserId)) {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(fetchedOtherUserId).get();
      if (userDoc.exists) {
        UserModel user = UserModel.fromDocument(userDoc);
        _userCache[fetchedOtherUserId] = user;
      }
    }

    final userData = _userCache[fetchedOtherUserId];
    if (userData != null) {
      setState(() {
        otherUserId = fetchedOtherUserId;
        otherUserName = userData.displayName ?? 'Sohbet';
        otherUserPhotoUrl = userData.photoURL ?? '';
      });
    }
  }

  /// Mesaj gönderme fonksiyonu: text veya listingId içererek gönderir
  Future<void> _sendMessage({String? listingId}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('Mesaj göndermek için giriş yapmalısınız.');
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty && listingId == null) return;

    Map<String, dynamic> messageData = {
      'senderId': currentUser.uid,
      'receiverId': otherUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': listingId != null ? 'listing' : 'text',
    };

    if (listingId != null) {
      messageData['listingId'] = listingId;
    } else {
      messageData['text'] = text;
    }

    await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add(messageData);

    // Sohbet listesindeki son mesaj zamanını güncelle
    await _firestore.collection('chats').doc(widget.chatId).update({
      'lastMessageTime': FieldValue.serverTimestamp(),
      'isHidden': false,
    });

    if (listingId == null) {
      _messageController.clear();
    }
    _scrollToBottom();
  }

  /// Yeni mesaj geldiğinde scroll'u en alta çekmek için
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  /// İlgili ilanı önbellekten veya Firestore'dan getir
  Future<Listing?> _fetchListingById(String listingId) async {
    if (_listingCache.containsKey(listingId)) {
      return _listingCache[listingId];
    }
    DocumentSnapshot<Map<String, dynamic>> doc =
        await _firestore.collection('listings').doc(listingId).get();
    if (doc.exists) {
      Listing listing = Listing.fromDocument(doc);
      _listingCache[listingId] = listing;
      return listing;
    }
    return null;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Mesaj listesi: metin ve ilan tipinde mesajları gösterir
  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data?.docs ?? [];
        if (messages.isEmpty) {
          return const Center(child: Text('Mesaj bulunmuyor.'));
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(10.0),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final data = messages[index].data();
            final isMe =
                data['senderId'] == FirebaseAuth.instance.currentUser?.uid;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final timeString =
                createdAt != null ? DateFormat('HH:mm').format(createdAt) : '';

            if (data['type'] == 'listing' && data['listingId'] != null) {
              final listingId = data['listingId'] as String;
              final cachedListing = _listingCache[listingId];
              if (cachedListing != null) {
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: _buildListingMessageBubble(
                    cachedListing,
                    isMe,
                    timeString,
                  ),
                );
              } else {
                // Arka planda ilan bilgisi çekilsin
                _fetchListingById(listingId).then((fetchedListing) {
                  if (fetchedListing != null) {
                    setState(() {}); // Önbelleğe alındıktan sonra yeniden çiz
                  }
                });
                // Yükleme göstergesi yerine boş bir widget göster
                return SizedBox.shrink();
              }
            } else {
              // Normal metin mesajı
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    // Mesaja tıklanınca kullanıcı profiline git
                    if (otherUserId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UserProfilePage(user: _userCache[otherUserId]!),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(isMe ? 12 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeString,
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  /// Bir mesajın ilan içeren balonu
  Widget _buildListingMessageBubble(
    Listing listing,
    bool isMe,
    String timeString,
  ) {
    return InkWell(
      onTap: () {
        // Hem resme hem de yazıya tıklanınca ilan detay sayfasına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailPage(listing: listing),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: listing.imageUrl.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${listing.price.toStringAsFixed(2)} ₺',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              timeString,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kullanıcının kendi ilanlarını seçerek paylaşmasını sağlayan bottom sheet'i açar
  void _openListingPicker() async {
    final selectedListing = await showModalBottomSheet<Listing>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ListingPickerBottomSheet(),
    );
    if (selectedListing != null) {
      _sendMessage(listingId: selectedListing.id);
    }
  }

  /// Mesaj yazma ve gönderme alanı
  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              icon:
                  const Icon(Icons.insert_drive_file, color: Colors.blueAccent),
              onPressed: _openListingPicker,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Mesaj yazın...',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: () => _sendMessage(),
              mini: true,
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// Başlık kısmında ilgili ilanın fotoğrafı ve bilgileri
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // İlana tıklayınca detay sayfasını aç
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListingDetailPage(listing: widget.listing),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: widget.listing.imageUrl.first,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () {
                // İlana veya yazıya tıklanınca detay sayfasını aç
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListingDetailPage(listing: widget.listing),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.listing.title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.listing.price.toStringAsFixed(2)} ₺',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.green,
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

  /// Ana gövde: üstte ilan bilgisi, ortada mesajlar, altta mesaj gönderme kutusu
  Widget _buildBody() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildMessagesList()),
        _buildMessageInput(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Row(
          children: [
            // Kullanıcının profil fotoğrafı
            GestureDetector(
              onTap: () {
                if (otherUserId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UserProfilePage(user: _userCache[otherUserId]!),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                backgroundImage: otherUserPhotoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(otherUserPhotoUrl)
                    : const AssetImage('assets/default_avatar.png')
                        as ImageProvider,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                if (otherUserId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UserProfilePage(user: _userCache[otherUserId]!),
                    ),
                  );
                }
              },
              child: Text(
                otherUserName,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }
}
