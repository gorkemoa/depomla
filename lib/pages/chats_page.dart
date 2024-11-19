import 'package:flutter/material.dart';
import 'chat_page.dart';
import '../models/listing_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatsPage extends StatelessWidget {
  ChatsPage({Key? key}) : super(key: key);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final DateFormat _dateFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Tümü, Depolat, Depola
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sohbet'),
          backgroundColor: Colors.white,
          elevation: 1,
          bottom: TabBar(
            labelColor: Colors.redAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.redAccent,
            tabs: const [
              Tab(text: 'Tümü'),
              Tab(text: 'Depolat'),
              Tab(text: 'Depola'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Quick Filters
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Chip(label: Text('Tümü')),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Chip(label: Text('Okunmamış')),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Chip(label: Text('Önemli')),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // All Chats
                  _buildChatList(context, categoryFilter: null),
                  // Depolat (for storage)
                  _buildChatList(context, categoryFilter: 'storage'),
                  // Depola (for deposit)
                  _buildChatList(context, categoryFilter: 'deposit'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, {String? categoryFilter}) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('chats')
          .where('participants', arrayContains: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Henüz sohbet yok.'));
        }

        final chatDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: chatDocs.length,
          itemBuilder: (context, index) {
            final chatData = chatDocs[index].data();
            final chatId = chatDocs[index].id;

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _firestore.collection('listings').doc(chatData['listingId']).get(),
              builder: (context, listingSnapshot) {
                if (listingSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    title: Text('Yükleniyor...'),
                  );
                }

                if (listingSnapshot.hasError || !listingSnapshot.hasData || !listingSnapshot.data!.exists) {
                  return const ListTile(
                    title: Text('İlan bulunamadı.'),
                  );
                }

                final listing = Listing.fromDocument(listingSnapshot.data!);

                // Skip items not matching the category filter
                if (categoryFilter != null && listing.listingType != categoryFilter) {
                  return const SizedBox.shrink();
                }

                final otherUserId = (chatData['participants'] as List<dynamic>)
                    .firstWhere((id) => id != _auth.currentUser?.uid);

                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: _firestore.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        title: Text('Yükleniyor...'),
                      );
                    }

                    if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const ListTile(
                        title: Text('Kullanıcı bulunamadı.'),
                      );
                    }

                    final userData = userSnapshot.data!.data()!;
                    final userName = userData['displayName'] ?? 'Bilinmeyen Kullanıcı';
                    final userPhotoUrl = userData['photoURL'];

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestore
                          .collection('chats')
                          .doc(chatId)
                          .collection('messages')
                          .orderBy('createdAt', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, messageSnapshot) {
                        if (messageSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('Yükleniyor...'),
                          );
                        }

                        if (messageSnapshot.hasError ||
                            !messageSnapshot.hasData ||
                            messageSnapshot.data!.docs.isEmpty) {
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                                  ? NetworkImage(userPhotoUrl)
                                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
                            ),
                            title: Text(userName),
                            subtitle: const Text('Henüz mesaj yok.'),
                            trailing: const SizedBox.shrink(),
                          );
                        }

                        final lastMessage = messageSnapshot.data!.docs.first.data();
                        final isUnread = lastMessage['isRead'] == false &&
                            lastMessage['senderId'] != _auth.currentUser?.uid;

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                                ? NetworkImage(userPhotoUrl)
                                : const AssetImage('assets/default_avatar.png') as ImageProvider,
                          ),
                          title: Text(
                            userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            lastMessage['text'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isUnread
                              ? CircleAvatar(
                                  radius: 5,
                                  backgroundColor: Colors.red,
                                )
                              : const SizedBox.shrink(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(chatId: chatId, listing: listing),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}