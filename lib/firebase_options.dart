// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDS-ngTYui4WMrpf0RlvDxhjWtgBnlHtvY',
    appId: '1:30104908258:web:0cf74078e3f6c800bdc9bb',
    messagingSenderId: '30104908258',
    projectId: 'depomla-app',
    authDomain: 'depomla-app.firebaseapp.com',
    storageBucket: 'depomla-app.firebasestorage.app',
    measurementId: 'G-15DNBXW3CV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAPkrVPC6mh_ZLh0IsNCCGnIj3jrGo8qXI',
    appId: '1:30104908258:android:48abc98f9a8aea33bdc9bb',
    messagingSenderId: '30104908258',
    projectId: 'depomla-app',
    storageBucket: 'depomla-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC5YZsWwVvZvgYMn0Y9P2pzf1G1gXHMHn0',
    appId: '1:30104908258:ios:f6a57d13d2e204c4bdc9bb',
    messagingSenderId: '30104908258',
    projectId: 'depomla-app',
    storageBucket: 'depomla-app.firebasestorage.app',
    iosBundleId: 'com.example.depomla',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC5YZsWwVvZvgYMn0Y9P2pzf1G1gXHMHn0',
    appId: '1:30104908258:ios:f6a57d13d2e204c4bdc9bb',
    messagingSenderId: '30104908258',
    projectId: 'depomla-app',
    storageBucket: 'depomla-app.firebasestorage.app',
    iosBundleId: 'com.example.depomla',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDS-ngTYui4WMrpf0RlvDxhjWtgBnlHtvY',
    appId: '1:30104908258:web:47186ac35dd58f11bdc9bb',
    messagingSenderId: '30104908258',
    projectId: 'depomla-app',
    authDomain: 'depomla-app.firebaseapp.com',
    storageBucket: 'depomla-app.firebasestorage.app',
    measurementId: 'G-DZ5F0SM769',
  );

}