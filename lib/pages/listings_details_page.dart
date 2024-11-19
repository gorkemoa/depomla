// lib/pages/listing_detail_page.dart

import 'package:depomla/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchListingUser();
  }

  Future<void> _fetchListingUser() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore
          .collection('users')
          .doc(widget.listing.userId)
          .get();

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
        print('Kullanıcı bulunamadı: ${widget.listing.userId}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Kullanıcı bilgileri alınırken bir hata oluştu.';
        isLoading = false;
      });
      print('Firestore Hatası: $e');
    }
  }

  Future<void> _startChat() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Kullanıcı oturum açmamışsa, oturum açma sayfasına yönlendirin
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oturum açmanız gerekiyor.')),
      );
      return;
    }

    String chatId;
    List<String> participants = [currentUser.uid, widget.listing.userId!];

    // Katılımcıları sıralayarak chatId oluşturun
    participants.sort();
    chatId = '${participants[0]}_${participants[1]}';

    DocumentReference<Map<String, dynamic>> chatRef = _firestore.collection('chats').doc(chatId);

    DocumentSnapshot<Map<String, dynamic>> chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      // Sohbet yoksa oluştur
      Chat newChat = Chat(
        id: chatId,
        participants: participants,
        listingId: widget.listing.id,
        createdAt: Timestamp.now(),
      );

      await chatRef.set(newChat.toMap());
    }

    // ChatPage'e geçiş yap
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(chatId: chatId, listing: widget.listing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive tasarım için ekran genişliğini alıyoruz
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listing.title),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İlan Görseli
                      Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: widget.listing.imageUrl.isNotEmpty
                                ? NetworkImage(widget.listing.imageUrl)
                                : const AssetImage('assets/default_listing.png') as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Kullanıcı Bilgileri
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: listingUser!.photoURL.isNotEmpty
                                ? NetworkImage(listingUser!.photoURL)
                                : const AssetImage('assets/default_avatar.png') as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listingUser!.displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'İlan Sahibi',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // İlan Başlığı
                      Text(
                        widget.listing.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // İlan Fiyatı ve Türü
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${widget.listing.price.toStringAsFixed(2)} ₺',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Chip(
                            label: Text(
                              widget.listing.listingType == ListingType.deposit
                                  ? 'Eşyalarını Depolamak'
                                  : 'Ek Gelir için Eşya Depolamak',
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: widget.listing.listingType == ListingType.deposit
                                ? Colors.blue
                                : Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // İlan Açıklaması
                      Text(
                        widget.listing.description,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // İletişim Butonu
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _startChat,
                          icon: const Icon(Icons.message),
                          label: const Text('İletişime Geç'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            textStyle: const TextStyle(fontSize: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}