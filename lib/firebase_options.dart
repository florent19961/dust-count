import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// IMPORTANT: Replace these placeholder values with your actual Firebase
/// project configuration from the Firebase Console:
/// https://console.firebase.google.com
///
/// You can also regenerate this file using the FlutterFire CLI:
/// ```
/// flutterfire configure
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBXED-RO3NqHST1gAywwhx3td_U6lLDTxQ',
    appId: '1:710559176715:web:632153532c7e015c368f0e',
    messagingSenderId: '710559176715',
    projectId: 'dust-count',
    authDomain: 'dust-count.firebaseapp.com',
    storageBucket: 'dust-count.firebasestorage.app',
  );

  // TODO: Replace with your actual Firebase Web configuration

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAIBYFXB1Cy72W_O_TZrNzL7RtmkFmEH-w',
    appId: '1:710559176715:android:0acc0b509c5b9370368f0e',
    messagingSenderId: '710559176715',
    projectId: 'dust-count',
    storageBucket: 'dust-count.firebasestorage.app',
  );

  // TODO: Replace with your actual Firebase Android configuration

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAP4jrFAXTrdfQFaqXYE8UNtsJzaE3EgEQ',
    appId: '1:710559176715:ios:972953fa0067ea6e368f0e',
    messagingSenderId: '710559176715',
    projectId: 'dust-count',
    storageBucket: 'dust-count.firebasestorage.app',
    iosBundleId: 'com.dustcount.dustCount',
  );

  // TODO: Replace with your actual Firebase iOS configuration
}