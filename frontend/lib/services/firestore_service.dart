import 'package:firebase_auth/firebase_auth.dart';
import 'package:Dharma/services/api/petitions_api.dart';

class FirestoreService {
  /// Configure Firestore settings — kept for backward compatibility.
  /// The Flutter Firestore SDK is still used for offline cache / App Check,
  /// but CRUD now goes through the backend.
  static void configureFirestore() {
    // No-op: Firestore settings are only needed if the SDK is still used
    // for auth state / offline cache. Data CRUD is via backend.
  }

  static Future<void> createPetition(String title, String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    await PetitionsApi.create(user.uid, {
      'title': title,
      'description': description,
      'ownerId': user.uid,
    });
  }
}