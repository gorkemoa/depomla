import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class GlobalAdsService {
  // Singleton Pattern
  static final GlobalAdsService _instance = GlobalAdsService._internal();
  factory GlobalAdsService() => _instance;
  GlobalAdsService._internal();

  // Reklam birimi kimlikleri
  final String androidTestAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Android test kimliği
  final String iosTestAdUnitId = 'ca-app-pub-3940256099942544/2934735716';   // iOS test kimliği
  final String androidRealAdUnitId = 'ca-app-pub-7601198457132530/3400755238'; // Gerçek Android kimliği
  final String iosRealAdUnitId = 'ca-app-pub-7601198457132530/9326733866';    // Gerçek iOS kimliği

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return androidTestAdUnitId.isNotEmpty 
          ? androidTestAdUnitId 
          : androidRealAdUnitId; // Test yoksa gerçek reklam dön
    } else if (Platform.isIOS) {
      return iosTestAdUnitId.isNotEmpty 
          ? iosTestAdUnitId 
          : iosRealAdUnitId; // Test yoksa gerçek reklam dön
    } else {
      throw UnsupportedError('Desteklenmeyen platform');
    }
  }

  // Mobile Ads SDK'yı başlatmak
  Future<void> initialize() async {
    try {
      final InitializationStatus status = await MobileAds.instance.initialize();
      print('Mobile Ads SDK initialized: ${status.adapterStatuses}');
    } catch (e) {
      print('Reklam SDK başlatılamadı: $e');
    }
  }
}