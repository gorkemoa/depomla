// lib/pages/comment_page/chat_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/listing_model.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../listing_page/listings_details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final Listing listing;

  const ChatPage({Key? key, required this.chatId, required this.listing}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String otherUserName = 'Sohbet';
  String otherUserPhotoUrl = '';
  String otherUserId = ''; // Diğer kullanıcının ID'si

  final Map<String, UserModel> _userCache = {};
  final Map<String, Listing> _listingCache = {}; // İlan önbelleği

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _fetchOtherUserData();
  }

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

    WriteBatch batch = _firestore.batch();

    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<void> _fetchOtherUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatDoc = await _firestore.collection('chats').doc(widget.chatId).get();
    if (!chatDoc.exists) return;

    List<dynamic> participants = chatDoc.data()?['participants'] ?? [];
    String fetchedOtherUserId = participants.firstWhere(
      (id) => id != currentUser.uid,
      orElse: () => '',
    );

    if (fetchedOtherUserId.isEmpty) return;

    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(fetchedOtherUserId).get();
      if (userDoc.exists) {
        UserModel user = UserModel.fromDocument(userDoc);
        setState(() {
          otherUserId = fetchedOtherUserId;
          otherUserName = user.displayName ?? 'Sohbet';
          otherUserPhotoUrl = user.photoURL ?? '';
          _userCache[otherUserId] = user;
        });
      } else {
        setState(() {
          otherUserName = 'Sohbet';
        });
      }
    } catch (e) {
      print('Hata: $e');
      setState(() {
        otherUserName = 'Sohbet';
      });
    }
  }

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
    };

    if (listingId != null) {
      messageData['type'] = 'listing';
      messageData['listingId'] = listingId;
    } else {
      messageData['text'] = text;
      messageData['type'] = 'text';
    }

    try {
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add(messageData);

      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isHidden': false,
      });

      if (listingId == null) {
        _messageController.clear();
      }

      _scrollToBottom();
    } catch (e) {
      print('Mesaj gönderilirken hata: $e');
      _showSnackBar('Mesaj gönderilirken bir hata oluştu.');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<Listing?> _fetchListingById(String listingId) async {
    if (_listingCache.containsKey(listingId)) {
      return _listingCache[listingId];
    }

    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('listings').doc(listingId).get();
      if (doc.exists) {
        Listing listing = Listing.fromDocument(doc);
        _listingCache[listingId] = listing;
        return listing;
      }
      return null;
    } catch (e) {
      print('İlan getirirken hata: $e');
      return null;
    }
  }

  Future<UserModel?> getUserModelById(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        UserModel user = UserModel.fromDocument(doc);
        _userCache[userId] = user;
        return user;
      } else {
        return null;
      }
    } catch (e) {
      print('Hata: $e');
      return null;
    }
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
        if (snapshot.hasError) {
          return const Center(child: Text('Mesajlar yüklenirken hata oluştu.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Henüz mesaj yok.'));
        }

        final messages = snapshot.data!.docs;

        return ListView.separated(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(10.0),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data();
            final isMe = messageData['senderId'] == FirebaseAuth.instance.currentUser?.uid;
            final createdAt = (messageData['createdAt'] as Timestamp?)?.toDate();
            final timeString = createdAt != null ? DateFormat('HH:mm').format(createdAt) : '';

            Widget messageBubble;

            if (messageData['type'] == 'listing' && messageData['listingId'] != null) {
              String listingId = messageData['listingId'];
              final listing = _listingCache[listingId];

              if (listing != null) {
                // İlan verisi önbellekte mevcut
                messageBubble = _buildListingMessageBubble(listing, isMe, timeString);
              } else {
                // İlan verisi önbellekte yok, çekmeye çalış
                _fetchListingById(listingId).then((fetchedListing) {
                  if (fetchedListing != null) {
                    setState(() {}); // Önbelleğe alındıktan sonra yeniden render et
                  }
                });

                // Placeholder göster
                messageBubble = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
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
                  child: const Center(
                    child: Text(
                      'İlan yükleniyor...',
                      style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }
            } else {
              // Normal metin mesajı
              messageBubble = Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
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
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      messageData['text'] ?? '',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
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
              );
            }

            // İlk mesajın bir ilan olup olmadığını kontrol et
            if (index == 0 && messageData['type'] == 'listing') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    messageBubble,
                    const SizedBox(height: 4),
                    Text(
                      'İlan gönderildi',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: messageBubble,
            );
          },
        );
      },
    );
  }

  Widget _buildListingMessageBubble(Listing listing, bool isMe, String timeString) {
    return Container(
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        color: isMe ? Colors.blueAccent : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                  placeholder: (context, url) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, color: Colors.white70),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              timeString,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openListingPicker() async {
    final selectedListing = await showModalBottomSheet<Listing>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ListingPickerBottomSheet(),
    );

    if (selectedListing != null) {
      _sendMessage(listingId: selectedListing.id);
    }
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: Colors.white,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.insert_drive_file, color: Colors.blueAccent),
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
                  decoration: InputDecoration(
                    hintText: 'Mesaj yazın...',
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListingDetailPage(listing: widget.listing),
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
                placeholder: (context, url) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, color: Colors.white70),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, color: Colors.white70),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.listing.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
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
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildMessagesList(),
        ),
        _buildMessageInput(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            if (otherUserPhotoUrl.isNotEmpty)
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(otherUserPhotoUrl),
              )
            else
              const CircleAvatar(
                backgroundImage: AssetImage('assets/default_avatar.png'),
              ),
            const SizedBox(width: 10),
            Text(
              otherUserName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }
}

class ListingPickerBottomSheet extends StatelessWidget {
  const ListingPickerBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Container(
        height: 200,
        color: Colors.white,
        child: const Center(
          child: Text('Giriş yapmanız gerekiyor.', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const Text(
            'Kendi İlanlarınızı Seçin',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .where('userId', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('İlanlar yüklenirken hata oluştu.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Henüz kendi ilanınız yok.'));
                }

                final listings = snapshot.data!.docs
                    .map((doc) => Listing.fromDocument(doc))
                    .toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(listing);
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: CachedNetworkImage(
                                  imageUrl: listing.imageUrl.first,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(Icons.image, color: Colors.white70, size: 40),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: Colors.white70, size: 40),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                listing.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                '${listing.price.toStringAsFixed(2)} ₺',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}