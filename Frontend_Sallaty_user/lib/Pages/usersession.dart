import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? id;
  String? token;
  String? name;
  String? lastName;
  String? surname;
  String? email;
  String? phone;
  String? photoUrl;
  String? wilaya;
  String? businessName;
  String? businessType;
  bool    isMerchant = false;

  String get fullName {
    final parts = [name, surname ?? lastName]
        .where((p) => p != null && p.isNotEmpty);
    return parts.join(' ');
  }

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (email != null && email!.isNotEmpty) return email!;
    return 'User';
  }

  bool get hasPhoto   => photoUrl != null && photoUrl!.isNotEmpty;
  bool get isLoggedIn => token    != null && token!.isNotEmpty;
  int  get intId      => int.tryParse(id ?? '') ?? 0;

  Future<void> hydrateFromJson(Map<String, dynamic> json) async {
    print('=== hydrateFromJson called ===');
    print('=== token: ${json['token'] ?? json['accessToken']}');
    print('=== user: ${json['user']}');

    token = json['token']?.toString()
         ?? json['accessToken']?.toString();

    final dynamic userRaw = json['user'];
    final Map<String, dynamic> user = userRaw is Map<String, dynamic>
        ? userRaw
        : json;

    final rawId = user['id'] ?? json['id'] ?? json['userId'];
    id = rawId?.toString();

    name    = user['name']?.toString()
           ?? user['firstName']?.toString();
    surname = user['surname']?.toString()
           ?? user['lastName']?.toString();
    lastName = surname;

    email = user['email']?.toString()
         ?? user['contact']?.toString()
         ?? json['email']?.toString()
         ?? json['contact']?.toString();

    phone        = user['phone']?.toString()
                ?? user['phoneNumber']?.toString()
                ?? json['phone']?.toString();

    photoUrl     = user['profileImage']?.toString()
                ?? user['photoUrl']?.toString()
                ?? json['profileImage']?.toString()
                ?? json['photoUrl']?.toString();

    wilaya       = user['wilaya']?.toString()
                ?? json['wilaya']?.toString();

    businessName = user['businessName']?.toString()
                ?? user['shopName']?.toString()
                ?? json['businessName']?.toString()
                ?? json['shopName']?.toString();

    businessType = user['businessType']?.toString()
                ?? user['category']?.toString()
                ?? json['businessType']?.toString()
                ?? json['category']?.toString();

    // ✅ FIX — supporte bool ET String "true"/"false"
    final rawMerchant = user['isMerchant'] ?? json['isMerchant'];
    isMerchant = rawMerchant == true || rawMerchant?.toString() == 'true';

    print('=== AFTER hydrate: token=$token, name=$name, email=$email, id=$id, isMerchant=$isMerchant');
    await save();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id',            id           ?? '');
    await prefs.setString('user_token',         token        ?? '');
    await prefs.setString('user_name',          name         ?? '');
    await prefs.setString('user_last_name',     lastName     ?? '');
    await prefs.setString('user_surname',       surname      ?? '');
    await prefs.setString('user_email',         email        ?? '');
    await prefs.setString('user_phone',         phone        ?? '');
    await prefs.setString('user_photo_url',     photoUrl     ?? '');
    await prefs.setString('user_wilaya',        wilaya       ?? '');
    await prefs.setString('user_business_name', businessName ?? '');
    await prefs.setString('user_business_type', businessType ?? '');
    await prefs.setBool(  'user_is_merchant',   isMerchant);
    print('=== SAVED: token=$token, name=$name, id=$id, isMerchant=$isMerchant');
  }

  Future<void> saveToPrefs() => save();
  Future<void> loadFromPrefs() => load();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    id           = prefs.getString('user_id');
    token        = prefs.getString('user_token');
    name         = prefs.getString('user_name');
    lastName     = prefs.getString('user_last_name');
    surname      = prefs.getString('user_surname');
    email        = prefs.getString('user_email');
    phone        = prefs.getString('user_phone');
    photoUrl     = prefs.getString('user_photo_url');
    wilaya       = prefs.getString('user_wilaya');
    businessName = prefs.getString('user_business_name');
    businessType = prefs.getString('user_business_type');
    isMerchant   = prefs.getBool('user_is_merchant') ?? false;

    if (id           != null && id!.isEmpty)           id           = null;
    if (token        != null && token!.isEmpty)        token        = null;
    if (name         != null && name!.isEmpty)         name         = null;
    if (email        != null && email!.isEmpty)        email        = null;
    if (photoUrl     != null && photoUrl!.isEmpty)     photoUrl     = null;
    if (wilaya       != null && wilaya!.isEmpty)       wilaya       = null;
    if (businessName != null && businessName!.isEmpty) businessName = null;
    if (businessType != null && businessType!.isEmpty) businessType = null;

    print('=== LOADED: token=$token, name=$name, id=$id, isMerchant=$isMerchant');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    id = token = name = lastName = surname = email =
        phone = photoUrl = wilaya = businessName = businessType = null;
    isMerchant = false;
  }

  Future<void> updatePhotoUrl(String url) async {
    photoUrl = url;
    await save();
  }

  Future<void> updateFromProfile(Map<String, dynamic> data) async {
    if (data['firstName']    != null) name         = data['firstName']    as String;
    if (data['name']         != null) name         = data['name']         as String;
    if (data['lastName']     != null) lastName     = data['lastName']     as String;
    if (data['surname']      != null) surname      = data['surname']      as String;
    if (data['email']        != null) email        = data['email']        as String;
    if (data['contact']      != null) email        = data['contact']      as String;
    if (data['phone']        != null) phone        = data['phone']        as String;
    if (data['photoUrl']     != null) photoUrl     = data['photoUrl']     as String;
    if (data['profileImage'] != null) photoUrl     = data['profileImage'] as String;
    if (data['wilaya']       != null) wilaya       = data['wilaya']       as String;
    if (data['businessName'] != null) businessName = data['businessName'] as String;
    if (data['businessType'] != null) businessType = data['businessType'] as String;
    if (data['isMerchant']   != null) {
      final raw = data['isMerchant'];
      isMerchant = raw == true || raw.toString() == 'true';
    }
    await save();
  }
}