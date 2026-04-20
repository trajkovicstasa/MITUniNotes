import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_hub/consts/admin_access_config.dart';

class AdminAccessService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool _isAllowedAdminEmail(String? email) {
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      return false;
    }

    return AdminAccessConfig.allowedAdminEmails.contains(normalizedEmail);
  }

  static bool _isAdminData(Map<String, dynamic>? data) {
    if (data == null) {
      return false;
    }

    return data['isAdmin'] == true ||
        (data['role'] ?? '').toString().toLowerCase() == 'admin';
  }

  static bool isAdminFromUserMap(Map<String, dynamic>? data) {
    return _isAdminData(data);
  }

  static Future<bool> isAdminUser(User? user) async {
    if (user == null) {
      return false;
    }

    if (_isAllowedAdminEmail(user.email)) {
      return true;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (_isAdminData(userDoc.data())) {
      return true;
    }

    final adminDocByUid = await _firestore.collection('admins').doc(user.uid).get();
    if (adminDocByUid.exists) {
      final data = adminDocByUid.data();
      return data == null || data['enabled'] != false;
    }

    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      return false;
    }

    final adminDocByEmail = await _firestore.collection('admins').doc(email).get();
    if (adminDocByEmail.exists) {
      final data = adminDocByEmail.data();
      return data == null || data['enabled'] != false;
    }

    return false;
  }

  static Future<bool> ensureAdminAccessForAllowedEmail(User? user) async {
    if (user == null) {
      return false;
    }

    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      return false;
    }

    if (!_isAllowedAdminEmail(email)) {
      return false;
    }

    await _firestore.collection('admins').doc(user.uid).set({
      'email': email,
      'enabled': true,
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'allowed_admin_email',
    }, SetOptions(merge: true));

    return true;
  }
}
