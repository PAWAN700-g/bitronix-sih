import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return ios;
      case TargetPlatform.windows:
        return android;
      case TargetPlatform.linux:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDMmkKz3RIbikcofyeRNwIDlPT0KGd_Cu0',
    appId: '1:837198275681:web:bitronix_sih_web',
    messagingSenderId: '837198275681',
    projectId: 'bitronix-sih',
    authDomain: 'bitronix-sih.firebaseapp.com',
    storageBucket: 'bitronix-sih.firebasestorage.app',
    databaseURL: 'https://bitronix-sih-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMmkKz3RIbikcofyeRNwIDlPT0KGd_Cu0',
    appId: '1:837198275681:android:21cfd6351e4396ad6fb620',
    messagingSenderId: '837198275681',
    projectId: 'bitronix-sih',
    storageBucket: 'bitronix-sih.firebasestorage.app',
    databaseURL: 'https://bitronix-sih-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDMmkKz3RIbikcofyeRNwIDlPT0KGd_Cu0',
    appId: '1:837198275681:ios:dff4a6a8bab62c3f6fb620',
    messagingSenderId: '837198275681',
    projectId: 'bitronix-sih',
    storageBucket: 'bitronix-sih.firebasestorage.app',
    iosBundleId: 'com.sih.waterquality.sihSmartWater',
    databaseURL: 'https://bitronix-sih-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}
