import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

class ListingsViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // İlanları Firestore'dan çek
  Stream<List<ListingModel>> getListings() {
    return _firestore.collection('listings').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ListingModel.fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
