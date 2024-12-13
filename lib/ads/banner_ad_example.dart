// lib/ads/global_ads_service.dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class GlobalAdsService {
  // Singleton Pattern
  static final GlobalAdsService _instance = GlobalAdsService._internal();
  factory GlobalAdsService() => _instance;
  GlobalAdsService._internal();

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Android için test banner reklam birimi kimliği
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      // iOS için test banner reklam birimi kimliği
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Desteklenmeyen platform');
    }
  }

  // Mobile Ads SDK'yı Başlatmak
  Future<void> initialize() async {
    final InitializationStatus status = await MobileAds.instance.initialize();
    print('Mobile Ads SDK initialized: ${status.adapterStatuses}');
  }
}