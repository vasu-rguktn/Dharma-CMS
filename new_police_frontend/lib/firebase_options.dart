// Firebase configuration for project: ap-dharma-cms-1998
// Account: apdharmacms@gmail.com
// POLICE FRONTEND — same Firebase project, separate Flutter app.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return web;
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBRLPhXBQDjqL2lB_4_yAeUiF8Hs4Syvzc',
    appId: '1:492784963984:web:6eb33b370fedd63d756315',
    messagingSenderId: '492784963984',
    projectId: 'ap-dharma-cms-1998',
    authDomain: 'ap-dharma-cms-1998.firebaseapp.com',
    storageBucket: 'ap-dharma-cms-1998.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBRLPhXBQDjqL2lB_4_yAeUiF8Hs4Syvzc',
    appId: '1:492784963984:web:6eb33b370fedd63d756315',
    messagingSenderId: '492784963984',
    projectId: 'ap-dharma-cms-1998',
    storageBucket: 'ap-dharma-cms-1998.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBRLPhXBQDjqL2lB_4_yAeUiF8Hs4Syvzc',
    appId: '1:492784963984:web:6eb33b370fedd63d756315',
    messagingSenderId: '492784963984',
    projectId: 'ap-dharma-cms-1998',
    storageBucket: 'ap-dharma-cms-1998.firebasestorage.app',
    iosBundleId: 'com.dharma.police.dharmaPolice',
  );
}
