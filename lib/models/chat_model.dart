// lib/models/chat_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants;
  final String listingId;
  final Timestamp createdAt;

  Chat({
    required this.id,
    required this.participants,
    required this.listingId,
    required this.createdAt,
  });

  factory Chat.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Chat(
      id: doc.id,
      participants: List<String>.from(data['participants']),
      listingId: data['listingId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'listingId': listingId,
      'createdAt': createdAt,
    };
  }
}