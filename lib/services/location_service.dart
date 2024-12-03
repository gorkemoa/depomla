// lib/services/location_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_model.dart';
import '../models/district_model.dart';
import '../models/neighborhood_model.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tüm şehirleri getirir
  Future<List<City>> getCities() async {
    try {
      final querySnapshot = await _firestore.collection('city').get(); // Koleksiyon adı 'city'
      return querySnapshot.docs.map((doc) => City.fromDocument(doc)).toList();
    } catch (e) {
      print('Şehirler yüklenirken hata: $e');
      return [];
    }
  }

  /// Belirli bir şehre ait ilçeleri getirir
  Future<List<District>> getDistricts(String cityId) async {
    try {
      final querySnapshot = await _firestore
          .collection('city')
          .doc(cityId)
          .collection('districts') // 'districts' alt koleksiyonu
          .get();
      return querySnapshot.docs.map((doc) => District.fromDocument(doc)).toList();
    } catch (e) {
      print('İlçeler yüklenirken hata: $e');
      return [];
    }
  }

  /// Belirli bir ilçeye ait mahalleleri getirir
  Future<List<Neighborhood>> getNeighborhoods(String cityId, String districtId) async {
    try {
      final querySnapshot = await _firestore
          .collection('city')
          .doc(cityId)
          .collection('districts')
          .doc(districtId)
          .collection('neighborhoods') // 'neighborhoods' alt koleksiyonu
          .get();
      return querySnapshot.docs.map((doc) => Neighborhood.fromDocument(doc)).toList();
    } catch (e) {
      print('Mahalleler yüklenirken hata: $e');
      return [];
    }
  }
}