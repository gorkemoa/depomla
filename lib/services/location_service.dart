// lib/services/location_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Şehirleri çek
  Future<List<Map<String, dynamic>>> getCities() async {
  try {
    final snapshot = await _firestore.collection('city').get();
    if (snapshot.docs.isEmpty) {
      print('Cities collection is empty.');
      return [];
    }
    List<Map<String, dynamic>> cities = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'sehir_id': doc.id,
        'sehir_adi': data['sehir_adi'] ?? 'Bilinmeyen Şehir',
      };
    }).toList();
    print('Cities fetched: $cities');
    return cities;
  } catch (e) {
    print('Error fetching cities: $e');
    return [];
  }
}

  // Belirli bir şehrin ilçelerini çek
  Future<List<Map<String, dynamic>>> getDistricts(String cityId) async {
  try {
    print('Fetching districts for cityId: $cityId'); // Log
    final snapshot = await _firestore
        .collection('city')
        .doc(cityId)
        .collection('districts')
        .get();

    if (snapshot.docs.isEmpty) {
      print('No districts found for cityId: $cityId');
      return [];
    }

    List<Map<String, dynamic>> districts = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'ilce_id': doc.id,
        'ilce_adi': data['ilce_adi'] ?? 'Bilinmeyen İlçe',
      };
    }).toList();

    print('Districts fetched: $districts');
    return districts;
  } catch (e) {
    print('Error fetching districts: $e');
    return [];
  }
}

  // Belirli bir ilçenin mahallelerini çek
 Future<List<Map<String, dynamic>>> getNeighborhoods({
  required String cityId,
  required String districtId,
}) async {
  try {
    print('Fetching neighborhoods for cityId: $cityId, districtId: $districtId');

    final snapshot = await _firestore
        .collection('city')
        .doc(cityId)
        .collection('districts')
        .doc(districtId)
        .collection('neighborhoods')
        .get();

    if (snapshot.docs.isEmpty) {
      print('No neighborhoods found for districtId: $districtId');
      return [];
    }

    List<Map<String, dynamic>> neighborhoods = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'mahalle_id': doc.id,
        'mahalle_adi': data['mahalle_adi'] ?? 'Bilinmeyen Mahalle',
      };
    }).toList();

    print('Neighborhoods fetched: $neighborhoods');
    return neighborhoods;
  } catch (e) {
    print('Error fetching neighborhoods: $e');
    return [];
  }
}

  // Yeni bir ilçe ekleme
  Future<void> addDistrict(String ilceId, String ilceAdi, String sehirId) async {
    try {
      await _firestore.collection('districts').doc(ilceId).set({
        'name': ilceAdi,
        'sehir_id': sehirId,
      });
      print('District added: $ilceId - $ilceAdi with sehir_id: $sehirId');
    } catch (e) {
      print('Error adding district: $e');
      throw e;
    }
  }
}