import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // Configure Firestore settings for better connection handling
  static void configureFirestore() {
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  static Future<void> createPetition(String title, String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not authenticated'); // or show UI error
    }
    print('creating petition as uid=${user.uid}'); // debug

    await _db.collection('petitions').add({
      'title': title,
      'description': description,
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}