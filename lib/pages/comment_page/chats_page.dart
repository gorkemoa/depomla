import 'package:flutter/material.dart';
import 'chat_page.dart';
import '../../models/listing_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatsPage extends StatefulWidget {
  ChatsPage({Key? key}) : super(key: key);

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildChatList(BuildContext context,
      {String? categoryFilter, bool showUnreadOnly = false}) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text(
          'Giriş yapmanız gerekiyor.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    // Tür belirterek Query oluşturuyoruz ve lastMessageTime'a göre sıralıyoruz
 Query<Map<String, dynamic>> chatsQuery = _firestore
    .collection('chats')
    .where('participants', arrayContains: currentUser.uid)
    .where('isHidden', isEqualTo: false) // Gizlenmemiş sohbetleri getir
    .orderBy('lastMessageTime', descending: true);

    if (categoryFilter != null) {
      chatsQuery = chatsQuery.where('category', isEqualTo: categoryFilter);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: chatsQuery.snapshots(),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chatSnapshot.hasError) {
          return Center(
            child: Text(
              'Bir hata oluştu: ${chatSnapshot.error}',
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
          );
        }

        if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Henüz sohbet yok.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final chatDocs = chatSnapshot.data!.docs;

        return ListView.separated(
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemCount: chatDocs.length,
          itemBuilder: (context, index) {
            final chatData = chatDocs[index].data();
            final chatId = chatDocs[index].id;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, messageSnapshot) {
                if (messageSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                if (messageSnapshot.hasError) {
                  return ListTile(
                    title: Text('Hata: ${messageSnapshot.error}'),
                  );
                }

                if (!messageSnapshot.hasData ||
                    messageSnapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                final lastMessageDoc = messageSnapshot.data!.docs.first;
                final lastMessage = lastMessageDoc.data();
                final messageId =
                    lastMessageDoc.id; // Mesaj belge kimliğini alıyoruz

                // 'isRead' ve 'senderId' alanlarının varlığını kontrol ediyoruz
                final isUnread = (lastMessage['isRead'] ?? false) == false &&
                    (lastMessage['senderId'] ?? '') != currentUser.uid;

                if (showUnreadOnly && !isUnread) {
                  return const SizedBox.shrink();
                }

                return _buildChatTile(
                  context,
                  chatId,
                  chatData,
                  lastMessage,
                  isUnread,
                  categoryFilter,
                  messageId, // Mesaj belge kimliğini geçiriyoruz
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatTile(
  BuildContext context,
  String chatId,
  Map<String, dynamic> chatData,
  Map<String, dynamic> lastMessage,
  bool isUnread,
  String? categoryFilter,
  String messageId,
) {
  final currentUser = _auth.currentUser;

  // Diğer katılımcının ID'sini alıyoruz
  final participants = chatData['participants'] as List<dynamic>? ?? [];
  if (participants.length < 2) {
    return const SizedBox.shrink(); // Hiçbir şey göstermiyor
  }
  final otherUserId = participants.firstWhere((id) => id != currentUser!.uid, orElse: () => '');

  if (otherUserId.isEmpty) {
    return const SizedBox.shrink(); // Hiçbir şey göstermiyor
  }

  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    future: _firestore.collection('users').doc(otherUserId).get(),
    builder: (context, userSnapshot) {
      if (!userSnapshot.hasData || userSnapshot.data == null || !userSnapshot.data!.exists) {
        return const SizedBox.shrink(); // Hiçbir şey göstermiyor
      }

      final userData = userSnapshot.data!.data()!;
      final userName = userData['displayName'] ?? 'Bilinmeyen Kullanıcı';
      final userPhotoUrl = userData['photoURL'];

      return ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
              ? NetworkImage(userPhotoUrl)
              : const AssetImage('assets/default_avatar.png') as ImageProvider,
        ),
        title: Text(
          userName,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
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
            ? const CircleAvatar(
                radius: 5,
                backgroundColor: Colors.blue,
              )
            : const SizedBox.shrink(),
        onTap: () async {
          if (isUnread) {
            try {
              await _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .doc(messageId)
                  .update({'isRead': true});
            } catch (e) {
              print('Mesaj güncellenirken hata: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mesaj güncellenirken bir hata oluştu.')),
              );
            }
          }

          try {
            final listingId = chatData['listingId'];
            if (listingId == null || listingId.toString().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('İlgili ilan bulunamadı.')),
              );
              return;
            }

            final listingDoc = await _firestore.collection('listings').doc(listingId).get();

            if (!listingDoc.exists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('İlgili ilan bulunamadı.')),
              );
              return;
            }

            final listing = Listing.fromDocument(listingDoc);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  chatId: chatId,
                  listing: listing,
                ),
              ),
            );
          } catch (e) {
            print('İlan alınırken hata: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('İlan alınırken bir hata oluştu.')),
            );
          }
        },
        onLongPress: () {
          _showChatOptions(context, chatId);
        },
      );
    },
  );
}
  void _showChatOptions(BuildContext context, String chatId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Önemli Yap'),
                onTap: () async {
                  try {
                    // Sohbeti önemli olarak işaretle (kategori olarak 'important' yapıyoruz)
                    await _firestore.collection('chats').doc(chatId).update({
                      'category': 'important',
                      'lastMessageTime': FieldValue
                          .serverTimestamp(), // lastMessageTime'ı da güncelliyoruz
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Sohbet önemli olarak işaretlendi.')),
                    );
                  } catch (e) {
                    print('Sohbet önemli olarak işaretlenirken hata: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Sohbet önemli olarak işaretlenirken bir hata oluştu.')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: const Text('Sohbeti Sil'),
                onTap: () async {
                  try {
                    // Sohbeti gizlemek için `isHidden` alanını güncelle
                    await _firestore.collection('chats').doc(chatId).update({
                      'isHidden': true,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sohbet Silindi.')),
                    );
                  } catch (e) {
                    print('Sohbet silinirken hata: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sohbet silinirken bir hata oluştu.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Tümü, Okunmamış, Önemli
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Sohbet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Tümü'),
              Tab(text: 'Okunmamış'),
              Tab(text: 'Önemli'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildChatList(context),
            _buildChatList(context, showUnreadOnly: true),
            _buildChatList(context,
                categoryFilter: 'important'), // 'deposit' yerine 'important'
          ],
        ),
      ),
    );
  }
}
