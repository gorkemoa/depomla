import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/listing_model.dart';
import 'package:intl/intl.dart';
import '../listing_page/listings_details_page.dart';

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

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
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

  /// Mesaj gönderir ve "lastMessageTime" alanını günceller
  Future<void> _sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj göndermek için giriş yapmalısınız.')),
      );
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
    } catch (e) {
      print('Mesaj gönderilirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj gönderilirken bir hata oluştu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.listing.title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          _buildListingCard(),
          const Divider(height: 1),
          Expanded(child: _buildMessagesList()),
          const Divider(height: 1),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildListingCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingDetailPage(listing: widget.listing),
          ),
        );
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.listing.imageUrl.isNotEmpty
                ? Image.network(widget.listing.imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                : Image.asset('assets/default_listing.png', width: 60, height: 60),
          ),
          title: Text(
            widget.listing.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${widget.listing.price.toStringAsFixed(2)} ₺',
            style: const TextStyle(color: Colors.green),
          ),
        ),
      ),
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
          reverse: true,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data();
            final isMe = messageData['senderId'] == FirebaseAuth.instance.currentUser?.uid;
            final createdAt = (messageData['createdAt'] as Timestamp?)?.toDate();
            final timeString = createdAt != null ? DateFormat('HH:mm').format(createdAt) : '';

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue : Colors.grey[300],
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
              child: TextField(
                controller: _messageController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Mesaj yazın...',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey[200],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _sendMessage,
              mini: true,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}