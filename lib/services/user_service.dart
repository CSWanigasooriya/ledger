import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.usersCollection);

  /// Get a single user by UID
  Future<AppUser?> getUser(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Stream a single user document for real-time role updates
  Stream<AppUser?> getUserStream(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  /// Create or update a user document
  Future<AppUser> createUser(AppUser user) async {
    await _collection.doc(user.uid).set(user.toMap());
    return user;
  }

  /// Update a user's role
  Future<void> updateRole(String uid, UserRole role) async {
    await _collection.doc(uid).update({'role': role.name});
  }

  /// Delete a user document (revoke access)
  Future<void> deleteUser(String uid) async {
    await _collection.doc(uid).delete();
  }

  /// Get all users
  Stream<List<AppUser>> getAllUsersStream() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  /// Check if any users exist (for first-user-is-admin logic)
  Future<bool> hasAnyUsers() async {
    final snapshot = await _collection.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }
}
