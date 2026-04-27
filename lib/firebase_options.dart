import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBR8LdxyFQ_8_IoVHZJM13fYED9i8S2bIs',
    appId: '1:402358191581:android:0ca88c820fd07e5e656234',
    messagingSenderId: '402358191581',
    projectId: 'phone-system-app',
    storageBucket: 'phone-system-app.firebasestorage.app',
  );
}
