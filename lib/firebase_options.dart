import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration options for the current platform.
///
/// Note: Replace these placeholder values with your actual Firebase project
/// configuration values from the Firebase console.
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Replace these placeholders with actual values from your Firebase project
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDAlYxHdH23WL9L2R-yv4jjl8z_I7FWugg',
    appId: '1:761762671535:web:4bb2e1a747e8398ecc5d5a',
    messagingSenderId: '761762671535',
    projectId: 'mahithi-25',
    authDomain: 'mahithi-25.firebaseapp.com',
    storageBucket: 'mahithi-25.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDAlYxHdH23WL9L2R-yv4jjl8z_I7FWugg',
    appId: '1:761762671535:android:dcf19a661c7d62e0cc5d5a',
    messagingSenderId: '761762671535',
    projectId: 'mahithi-25',
    storageBucket: 'mahithi-25.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDAlYxHdH23WL9L2R-yv4jjl8z_I7FWugg',
    appId: '1:761762671535:ios:dcf19a661c7d62e0cc5d5a',
    messagingSenderId: '761762671535',
    projectId: 'mahithi-25',
    storageBucket: 'mahithi-25.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'app.Mahithi',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDAlYxHdH23WL9L2R-yv4jjl8z_I7FWugg',
    appId: '1:761762671535:ios:dcf19a661c7d62e0cc5d5a',
    messagingSenderId: '761762671535',
    projectId: 'mahithi-25',
    storageBucket: 'mahithi-25.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'app.Mahithi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDAlYxHdH23WL9L2R-yv4jjl8z_I7FWugg',
    appId: '1:761762671535:web:4bb2e1a747e8398ecc5d5a',
    messagingSenderId: '761762671535',
    projectId: 'mahithi-25',
    storageBucket: 'mahithi-25.appspot.com',
  );
}
