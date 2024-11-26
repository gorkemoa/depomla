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

  String otherUserName = 'Sohbet'; // Varsayılan başlık
  String otherUserPhotoUrl = ''; // Diğer kullanıcının profil fotoğrafı

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _fetchOtherUserData();
  }

  /// Okunmamış mesajları "okundu" olarak işaretler
  Future<void> _markMessagesAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final unreadMessages = await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  /// Diğer kullanıcının adını ve profil fotoğrafını alır
  Future<void> _fetchOtherUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // 'participants' alanının bir liste olduğunu varsayıyoruz
    final chatDoc = await _firestore.collection('chats').doc(widget.chatId).get();
    if (!chatDoc.exists) return;

    List<dynamic> participants = chatDoc.data()?['participants'] ?? [];
    // Mevcut kullanıcının ID'sini listeden çıkararak diğer kullanıcının ID'sini buluyoruz
    String otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');

    if (otherUserId.isEmpty) return;

    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(otherUserId).get();
      if (userDoc.exists) {
        setState(() {
          otherUserName = userDoc.data()?['displayName'] ?? 'Sohbet';
          otherUserPhotoUrl = userDoc.data()?['photoURL'] ?? '';
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

  /// Mesaj gönderir ve "lastMessageTime" alanını günceller
  Future<void> _sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showSnackBar('Mesaj göndermek için giriş yapmalısınız.');
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await _firestore.collection('chats').doc(widget.chatId).collection('messages').add({
        'text': text,
        'senderId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isHidden': false, // Sohbeti görünür yap
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print('Mesaj gönderilirken hata: $e');
      _showSnackBar('Mesaj gönderilirken bir hata oluştu.');
    }
  }

  /// Mesaj gönderildikten sonra listeyi aşağı kaydırır
  void _scrollToBottom() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<UserModel?> getUserModelById(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
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
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data();
            final isMe = messageData['senderId'] == FirebaseAuth.instance.currentUser?.uid;
            final createdAt = (messageData['createdAt'] as Timestamp?)?.toDate();
            final timeString = createdAt != null ? DateFormat('HH:mm').format(createdAt) : '';

            return FutureBuilder<UserModel?>(
              future: getUserModelById(messageData['senderId']),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  );
                }
                if (userSnapshot.hasError || !userSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final sender = userSnapshot.data!;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe)
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: sender.photoURL != null && sender.photoURL!.isNotEmpty
                              ? CachedNetworkImageProvider(sender.photoURL!)
                              : const AssetImage('assets/default_avatar.png') as ImageProvider,
                        ),
                      if (!isMe) const SizedBox(width: 8),
                      Container(
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
                      ),
                      if (isMe) const SizedBox(width: 8),
                      if (isMe)
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: sender.photoURL != null && sender.photoURL!.isNotEmpty
                              ? CachedNetworkImageProvider(sender.photoURL!)
                              : const AssetImage('assets/default_avatar.png') as ImageProvider,
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: Colors.white,
        child: Row(
          children: [
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
              onPressed: _sendMessage,
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
      padding: const EdgeInsets.all(16.0),
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
              child: widget.listing.imageUrl.isNotEmpty
                  ? Image.network(widget.listing.imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                  : Image.asset('assets/default_listing.png', width: 60, height: 60),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Arka plan rengini hafif gri yaparak kontrast oluşturduk
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
        backgroundColor: Colors.blueAccent, // Daha parlak bir mavi tonu
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(), // İlan bilgilerini gösteren başlık
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}