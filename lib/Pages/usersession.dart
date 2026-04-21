import 'dart:io';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  // Personal info
  String name = '';
  String surname = '';
  String email = '';
  String password = '';
  String phone = '';
  String wilaya = '';

  // Account type
  bool isMerchant = false;

  // Profile image
  File? profileImage;

  // Google Sign-In
  String? displayName;
  String? photoUrl;

  // for chat
  int id = 0;
  String token = '';

  // Computed helpers
  String get fullName {
    final parts = [surname, name].where((s) => s.isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : 'No Name';
  }

  void clear() {
    name = '';
    surname = '';
    email = '';
    password = '';
    phone = '';
    wilaya = '';
    isMerchant = false;
    profileImage = null;
    displayName = null;
    photoUrl = null;
    id = 0;
    token = '';
  }
}