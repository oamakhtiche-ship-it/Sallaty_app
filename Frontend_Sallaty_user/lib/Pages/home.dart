import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'registermerchant.dart';
import 'manageprofile.dart';
import 'editprofile.dart';
import 'orderhistory.dart';
import 'my_offers.dart';
import 'offer_store.dart';
import 'language.dart';
import 'privacy.dart';
import 'help.dart';
import 'aboutus.dart';
import 'viewoffer.dart';
import 'usersession.dart';
import 'signup1.dart';
import 'chat.dart';
import 'conversation.dart';
import 'package:saallatyy/l10n/app_localizations.dart';
import 'all_offers.dart';
import 'myorders.dart';
import 'notifications.dart';                  
import 'otifications.dart' as notif_inbox;       
import 'statistics.dart';
import 'apiservice.dart';
import 'pending_verification.dart';
import 'favori_store.dart';
import 'favori_button.dart';
import 'merchant_profile_page.dart';
import 'network_image_widget.dart';


// ─────────────────────────────────────────────────────────────
//  HOME PAGE
// ─────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _page = 0;
  bool _isRegistering = false;
  bool _isMerchant = false;
  final Set<int> _favorites = {};
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _isMerchant = UserSession().isMerchant;
    _loadOffers();
    FavoriStore().loadMyFavoris();
  }

  Future<void> _loadOffers() async {
    await OfferStore.fetchOffers();
    debugPrint("OFFERS COUNT = ${OfferStore.offers.length}");
    debugPrint(
        "FIRST ITEM = ${OfferStore.offers.isNotEmpty ? OfferStore.offers[0].title : 'EMPTY'}");
    if (mounted) setState(() {});
  }

  List<Offer> get _topSavingOffers {
    final sorted = List<Offer>.from(OfferStore.offers);
    sorted.sort((a, b) {
      final priceA =
          double.tryParse(a.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final priceB =
          double.tryParse(b.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      return priceA.compareTo(priceB);
    });
    return sorted.take(10).toList();
  }

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Bakery',
      'color': const Color(0xFFFFC9D7),
      'nameColor': const Color(0xFFCB1B5F),
      'nameSize': 14.0
    },
    {
      'name': 'Fish',
      'color': const Color(0xFFA6DCEF),
      'nameColor': const Color(0xFF08339E),
      'nameSize': 14.0
    },
    {
      'name': 'Cafe',
      'color': const Color(0xFFEFE3D2),
      'nameColor': const Color(0xFFB17B2F),
      'nameSize': 14.0
    },
    {
      'name': 'Grocery',
      'color': const Color(0xFFD0E6A5),
      'nameColor': const Color(0xFF72A843),
      'nameSize': 14.0
    },
    {
      'name': 'Fruits & Vegetables',
      'color': const Color(0xFF86E3CE),
      'nameColor': const Color(0xFF009966),
      'nameSize': 12.0
    },
    {
      'name': 'Restaurant',
      'color': const Color(0xFFE0B6C4),
      'nameColor': const Color(0xFFA84296),
      'nameSize': 13.0
    },
    {
      'name': 'Butcher',
      'color': const Color(0xFFFDD6C1),
      'nameColor': const Color(0xFFFF9D9D),
      'nameSize': 14.0
    },
    {
      'name': 'HomeCooking',
      'color': const Color(0xFFFDFF97),
      'nameColor': const Color(0xFFDBCF4C),
      'nameSize': 13.0
    },
    {
      'name': 'FastFood',
      'color': const Color(0xFFFFDD94),
      'nameColor': const Color(0xFFF8A136),
      'nameSize': 14.0
    },
  ];

  final List<String> _wilayas = [
    '01 - Adrar', '02 - Chlef', '03 - Laghouat', '04 - Oum El Bouaghi',
    '05 - Batna', '06 - Béjaïa', '07 - Biskra', '08 - Béchar',
    '09 - Blida', '10 - Bouira', '11 - Tamanrasset', '12 - Tébessa',
    '13 - Tlemcen', '14 - Tiaret', '15 - Tizi Ouzou', '16 - Alger',
    '17 - Djelfa', '18 - Jijel', '19 - Sétif', '20 - Saïda',
    '21 - Skikda', '22 - Sidi Bel Abbès', '23 - Annaba', '24 - Guelma',
    '25 - Constantine', '26 - Médéa', '27 - Mostaganem', "28 - M'Sila",
    '29 - Mascara', '30 - Ouargla', '31 - Oran', '32 - El Bayadh',
    '33 - Illizi', '34 - Bordj Bou Arréridj', '35 - Boumerdès',
    '36 - El Tarf', '37 - Tindouf', '38 - Tissemsilt', '39 - El Oued',
    '40 - Khenchela', '41 - Souk Ahras', '42 - Tipaza', '43 - Mila',
    '44 - Aïn Defla', '45 - Naâma', '46 - Aïn Témouchent',
    '47 - Ghardaïa', '48 - Relizane', '49 - Timimoun',
    '50 - Bordj Badji Mokhtar', '51 - Ouled Djellal', '52 - Béni Abbès',
    '53 - In Salah', '54 - In Guezzam', '55 - Touggourt', '56 - Djanet',
    "57 - El M'Ghair", '58 - El Meniaa',
  ];

  AppLocalizations get _t => AppLocalizations.of(context)!;

  // ── Profile Page ──────────────────────────────────────────────
  Widget _buildProfilePage() {
    final session = UserSession();
    assert(() {
      final url = session.photoUrl;
      debugPrint('[Profile] photoUrl="${(url != null && url.isNotEmpty) ? url : '<not set>'}"}');
      return true;
    }());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 80),
        Center(
          child: Text(
            _t.profile,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFD0E6A5).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade200,
                child: (session.photoUrl != null && session.photoUrl!.isNotEmpty)
                    ? ClipOval(
                        child: AppNetworkImage(
                          url: session.photoUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        (session.name?.isNotEmpty == true)
                            ? session.name![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF72A843)),
                      ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.fullName.isNotEmpty ? session.fullName : 'User',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    session.email?.isNotEmpty == true
                        ? session.email!
                        : _t.noEmail,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  Text(
                    session.isMerchant ? _t.merchantClient : _t.client,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(_t.account, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 10),
        _buildSection([
          _buildItem(Icons.person_outline, _t.manageProfile, context,
              const ManageProfilePage()),
          _buildDivider(),
          _buildItem(
              Icons.edit, _t.editProfile, context, const EditProfilePage()),
          _buildDivider(),
          _buildItem(Icons.shopping_cart_outlined, _t.orderHistory, context,
              const OrderHistoryPage()),
          _buildDivider(),
          _buildItem(Icons.bar_chart_outlined, 'Statistics', context,
              const StatisticsPage()),
        ]),

        const SizedBox(height: 20),

        Text(_t.settings, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 10),
        _buildSection([
          _buildItem(Icons.language, _t.language, context, const LanguagePage()),
          _buildDivider(),
          _buildItem(Icons.privacy_tip_outlined, _t.privacy, context,
              const PrivacyPage()),
          _buildDivider(),
          _buildItem(Icons.settings_outlined, 'Settings', context,
              const NotificationsPage()),
          _buildDivider(),
          _buildItem(
              Icons.help_outline, _t.helpSupport, context, const HelpSupportPage()),
          _buildDivider(),
          _buildItem(Icons.info_outline, _t.aboutUs, context, const AboutUsPage()),
        ]),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () async {
              final nav = Navigator.of(context);
              FavoriStore().clear();
              await UserSession().clear();
              if (!mounted) return;
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignUp1()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(_t.logout, style: const TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showSuccessAndGoToOffers(BuildContext context) {
    setState(() => _isMerchant = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) {
        final t = AppLocalizations.of(context)!;
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF72A843).withValues(alpha: 0.4),
                        width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/merchantregister.png',
                          height: 150),
                      const SizedBox(height: 16),
                      Text(t.thankYou,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF72A843))),
                      const SizedBox(height: 12),
                      Text(
                        t.thankYouMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 18, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MyOffersPage()));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(t.done,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _logo() {
  return Image.asset(
    'assets/images/logohome.png',
    height: 50,
    fit: BoxFit.contain,
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      appBar: _page == 0 
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: _logo(),
              actions: [
                IconButton(
                  icon: _UnreadBadgeIcon(
                    userId: int.tryParse(UserSession().id ?? '') ?? 0,
                    token: UserSession().token ?? '',
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatListScreen(
                          myUserId: int.tryParse(UserSession().id ?? '') ?? 0,
                          myToken: UserSession().token ?? '',
                        ),
                      ),
                    );
                  },
                ),
               
                notif_inbox.NotificationBadge(onTap: () {}),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: _page == 1
          ? _SearchPage(
              categories: _categories,
              wilayas: _wilayas,
              favorites: _favorites,
              myUserId: int.tryParse(UserSession().id ?? '') ?? 0,
              myToken: UserSession().token ?? '',
              onFavoriteToggle: (index) => setState(() {
                if (_favorites.contains(index)) {
                  _favorites.remove(index);
                } else {
                  _favorites.add(index);
                }
              }),
            )
          : _page == 2
              ? _isMerchant
                  ? FutureBuilder<String?>(
                      future: ApiService.getMerchantStatus(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF72A843)));
                        }
                        final status = snapshot.data ?? '';
                        if (status == 'VERIFIED') {
                          return const MyOffersPage();
                        }
                        return const PendingVerificationPage();
                      },
                    )
                  : _isRegistering
                      ? RegisterMerchantPage(
                          onSuccess: () => _showSuccessAndGoToOffers(context))
                      : SizedBox(
                          height: MediaQuery.of(context).size.height * 0.75,
                          
                          child: Center(
                            child: Container(
                              width: 300,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: const Color(0xFF72A843)
                                        .withValues(alpha: 0.3),
                                    width: 1.5),
                              ),
                             
                                
                              child: Column(
                                 mainAxisSize: MainAxisSize.min,
                              
                                children: [
                                  Image.asset('assets/images/Bakery.png',
                                      height: 140),
                                  const SizedBox(height: 12),
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      colors: [
                                        Color(0xFF72A843),
                                        Color(0xFF2D421A)
                                      ],
                                    ).createShader(bounds),
                                    child: Text(_t.createOffer,
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_t.createOfferQuestion,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black87),
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RegisterMerchantPage(
                                            onSuccess: () =>
                                                _showSuccessAndGoToOffers(
                                                    context),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF72A843),
                                            Color(0xFFA0CA09)
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(24),
                                      ),
                                      child: Center(
                                        child: Text(_t.yes,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _page = 0),
                                    child: Text(_t.no,
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 16)),
                                  ),
                                ],
                              ),
                            
                            ),
                          ),
                        )
              : _page == 3
                  ? MyOrdersPage(onBrowse: () => setState(() => _page = 0))
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: _page == 0
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 15),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5F8C38),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(_t.saveFoodTitle,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 8),
                                            Text(_t.saveFoodSubtitle,
                                                style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 13)),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() => _page = 1);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor:
                                                    Colors.green[700],
                                                shape: const StadiumBorder(),
                                              ),
                                              child: Text(_t.exploreNow),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      CircleAvatar(
                                        radius: 35,
                                        backgroundColor: Colors.white24,
                                        child: Image.asset(
                                            'assets/images/Chefhat.png',
                                            width: 40,
                                            height: 40,
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildSectionHeader(_t.latestOffers),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 236,
                                  child: OfferStore.offers.isEmpty
                                      ? Center(child: Text(_t.noOffersYet))
                                      : ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: OfferStore.offers.length,
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(width: 12),
                                          itemBuilder: (context, index) =>
                                              _buildOfferCard(
                                            title: OfferStore
                                                .offers[index].title,
                                            subtitle: OfferStore
                                                .offers[index].description,
                                            shop: OfferStore
                                                .offers[index].location,
                                            price: OfferStore
                                                .offers[index].price,
                                            imageUrl: OfferStore
                                                    .offers[index]
                                                    .imageUrl
                                                    .isNotEmpty
                                                ? OfferStore
                                                    .offers[index].imageUrl
                                                : '',
                                            availableUntil: OfferStore
                                                .offers[index].availableUntil,
                                            status: OfferStore
                                                .offers[index].status,
                                            quantity: OfferStore
                                                .offers[index].quantity,
                                            offerId:
                                                OfferStore.offers[index].id,
                                            index: index,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            )
                          : _page == 4
                              ? _buildProfilePage()
                              : const SizedBox(),
                    ),

      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _page,
        height: 75,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.search, size: 30, color: Colors.white),
          Icon(Icons.add, size: 30, color: Colors.white),
          Icon(Icons.shopping_cart, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        color: const Color(0xFF72A843),
        backgroundColor: const Color(0xFFFAFFF7),
        onTap: (index) {
          setState(() {
            _page = index;
            _isRegistering = false;
            _isMerchant = UserSession().isMerchant;
          });
          if (index == 0) {
            _loadOffers();
            FavoriStore().loadMyFavoris();
          }
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AllOffersPage(
                  title: title,
                  offers: title == _t.topSaving
                      ? _topSavingOffers
                      : OfferStore.offers,
                ),
              ),
            );
          },
          child: Row(
            children: [
              Text(_t.viewAll,
                  style: const TextStyle(color: Color(0xFFA1C582))),
              Icon(Icons.chevron_right, color: Colors.green[700], size: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD0E6A5).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildItem(
      IconData icon, String title, BuildContext context, Widget page) {
    return InkWell(
      onTap: () async {
        final nav = Navigator.of(context);
        await nav.push(MaterialPageRoute(builder: (_) => page));
        if (mounted) setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(thickness: 0.5),
    );
  }

  Widget _buildOfferCard({
    required String title,
    required String subtitle,
    required String shop,
    required String price,
    required String imageUrl,
    required int index,
    required String offerId,
    String availableUntil = '',
    String status = 'active',
    String quantity = '',
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewOfferPage(
              offerId: offerId,
              title: title,
              description: subtitle,
              location: shop,
              price: price,
              imageUrl: imageUrl,
              availableUntil: availableUntil,
              status: status,
              quantity: quantity,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl.isEmpty
                      ? Container(
                          height: 110,
                          width: 160,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.fastfood,
                              color: Colors.grey, size: 36),
                        )
                      : AppNetworkImage(
                          url: imageUrl,
                          height: 110,
                          width: 160,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: FavoriButton(offerId: offerId),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 11)),
                  Text(shop,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(price,
                      style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  USER SEARCH RESULT MODEL
// ═══════════════════════════════════════════════════════════════

class _UserResult {
  final int id;
  final String name;
  final String shopName;
  final String wilaya;
  final String category;
  final String avatarUrl;
  final bool isVerified;
  final bool isMerchant;

  const _UserResult({
    required this.id,
    required this.name,
    required this.shopName,
    required this.wilaya,
    required this.category,
    required this.avatarUrl,
    required this.isVerified,
    required this.isMerchant,
  });
}

// ═══════════════════════════════════════════════════════════════
//  UNREAD BADGE ICON  (chat icon with unread count)
// ═══════════════════════════════════════════════════════════════

class _UnreadBadgeIcon extends StatefulWidget {
  final int userId;
  final String token;
  const _UnreadBadgeIcon({required this.userId, required this.token});

  @override
  State<_UnreadBadgeIcon> createState() => _UnreadBadgeIconState();
}

class _UnreadBadgeIconState extends State<_UnreadBadgeIcon> {
  int _unread = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchUnread();
    // Poll every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchUnread());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnread() async {
    try {
      final api = ChatApiService(widget.token);
      final convs = await api.getConversations();
      final total = convs.fold(0, (sum, c) => sum + c.unreadCount);
      if (mounted) setState(() => _unread = total);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.chat_bubble_outline, color: Color(0xFF8DC63F), size: 26),
        if (_unread > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _unread > 99 ? '99+' : '$_unread',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SEARCH PAGE
// ═══════════════════════════════════════════════════════════════

class _SearchPage extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final List<String> wilayas;
  final Set<int> favorites;
  final int myUserId;
  final String myToken;
  final void Function(int index) onFavoriteToggle;

  const _SearchPage({
    required this.categories,
    required this.wilayas,
    required this.favorites,
    required this.myUserId,
    required this.myToken,
    required this.onFavoriteToggle,
  });

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  // ── Tab state ──────────────────────────────────────────────────
  bool _isMerchantTab = false;

  // ── Offers state ───────────────────────────────────────────────
  String _offerQuery = '';
  String? _selectedCategory;
  bool _showFilters = false;
  double _minPrice = 0;
  double _maxPrice = 10000;
  String? _filterWilaya;
  String? _filterCategory;
  double _minDistance = 0;
  double _maxDistance = 500;
  String _locationText = '';
  bool _isLoadingGps = false;
  final TextEditingController _locationController = TextEditingController();
  List<Map<String, dynamic>> _placeSuggestions = [];
  Timer? _debounce;
  static const String _googleApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // ── Merchants state ────────────────────────────────────────────
  final TextEditingController _merchantController = TextEditingController();
  String _merchantQuery = '';
  List<_UserResult> _merchantResults = [];
  List<_UserResult> _allMerchants    = [];   
  bool _merchantsLoaded = false;             
  bool _isLoadingMerchants = false;
  String? _merchantError;
  Timer? _merchantDebounce;

  // ── Backend search state ───────────────────────────────────────
  List<Offer> _backendResults = [];
  bool _isSearching = false;
  double? _userLat;
  double? _userLng;

  late final ChatApiService _chatApi;

  AppLocalizations get _t => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _chatApi = ChatApiService();
    _chatApi.setToken(widget.myToken);
    _merchantController.addListener(_onMerchantTyped);
    _getGps();
    _doBackendSearch();
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _locationController.dispose();
    _debounce?.cancel();
    _merchantDebounce?.cancel();
    super.dispose();
  }

  Future<void> _getGps() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
      }
    } catch (_) {}
  }

  Future<void> _doBackendSearch() async {
    setState(() {
      _isSearching = true;
    });

    final params = <String, String>{};

    if (_offerQuery.trim().isNotEmpty) params['q'] = _offerQuery.trim();

    if (_filterCategory != null)
      params['categoryType'] = _filterCategory!
          .toUpperCase()
          .replaceAll('Fruits & Vegetables'.toUpperCase(), 'FRUITS_VEGETABLES')
          .replaceAll('HomeCooking'.toUpperCase(), 'HOME_COOKING')
          .replaceAll('FastFood'.toUpperCase(), 'FAST_FOOD')
          .replaceAll('Butcher'.toUpperCase(), 'BOUCHERIE')
          .replaceAll(' & ', '_')
          .replaceAll(' ', '_');

    if (_filterWilaya != null) params['wilaya'] = _filterWilaya!.trim();
    if (_minPrice > 0) params['minPrice'] = _minPrice.toStringAsFixed(0);
    if (_maxPrice < 10000) params['maxPrice'] = _maxPrice.toStringAsFixed(0);

    if (_userLat != null && _userLng != null) {
      params['lat'] = _userLat!.toString();
      params['lng'] = _userLng!.toString();
      if (_maxDistance < 500)
        params['distance'] = _maxDistance.toStringAsFixed(0);
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/search')
          .replace(queryParameters: params);

      final headers = <String, String>{};
      final token = UserSession().token;
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        final List<dynamic> data = body['offres'] ?? [];

        final results = data.map((e) {
          final o = e is Map ? e : {};
          String photoUrl = '';
          if (o['photo'] != null && o['photo'].toString().isNotEmpty) {
            final photo = o['photo'].toString();
            photoUrl = photo.startsWith('http')
                ? photo
                : '${ApiConfig.baseUrl}/$photo';
          }
          return Offer(
            id: o['id']?.toString() ?? '',
            title: o['title']?.toString() ?? '',
            description: o['description']?.toString() ?? '',
            location: o['wilaya']?.toString() ?? '',
            price: o['price']?.toString() ?? '',
            imageUrl: photoUrl,
            availableUntil: o['expireAt']?.toString() ?? '',
            status: o['status']?.toString() ?? 'active',
            quantity: o['quantity']?.toString() ?? '',
            available: (o['quantity'] ?? 0).toString(),
            type: o['categoryType']?.toString() ?? '',
          );
        }).toList();

        if (mounted)
          setState(() {
            _backendResults = results;
            _isSearching = false;
          });
      } else {
        if (mounted)
          setState(() {
            _backendResults = [];
            _isSearching = false;
          });
      }
    } catch (e) {
      debugPrint('[Search] exception: $e');
      if (mounted)
        setState(() {
          _backendResults = [];
          _isSearching = false;
        });
    }
  }

  void _onMerchantTyped() {
    final query = _merchantController.text;
    setState(() => _merchantQuery = query);
    _merchantDebounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _merchantResults = List.from(_allMerchants);
        _merchantError   = null;
      });
      return;
    }

    // Si déjà chargé, filtre local instantané
    if (_merchantsLoaded) {
      _filterMerchantsLocally(query.trim());
      return;
    }

    _merchantDebounce = Timer(const Duration(milliseconds: 300), () {
      _loadAllMerchants(query.trim());
    });
  }

  // Filtre local sur le cache
  void _filterMerchantsLocally(String query) {
    final q = query.toLowerCase();
    setState(() {
      _merchantResults = _allMerchants.where((m) {
        return m.shopName.toLowerCase().contains(q)
            || m.name.toLowerCase().contains(q)
            || m.wilaya.toLowerCase().contains(q)
            || m.category.toLowerCase().contains(q);
      }).toList();
    });
  }

  // Charge tous les marchands via /api/offres/active → marchandIds → /api/marchand/get/{id}
  // (car /api/marchand/verified retourne 403 — réservé aux admins)
  Future<void> _loadAllMerchants(String initialQuery) async {
    if (_merchantsLoaded) {
      _filterMerchantsLocally(initialQuery);
      return;
    }
    setState(() { _isLoadingMerchants = true; _merchantError = null; });

    try {
      final token = UserSession().token ?? '';

      // Étape 1 : récupérer toutes les offres actives pour extraire les marchandIds
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/offres/active'),
        headers: {
          'Authorization'             : 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('[MarchandList] offres/active status: ${res.statusCode}');

      if (res.statusCode != 200) {
        if (mounted) setState(() { _merchantResults = []; _isLoadingMerchants = false; _merchantError = 'Erreur ${res.statusCode}'; });
        return;
      }

      final List<dynamic> offres = jsonDecode(res.body) as List<dynamic>? ?? [];

      // Extraire les marchandIds uniques
      final marchandIds = <int>{};
      for (final o in offres) {
        if (o is Map<String, dynamic>) {
          final id = (o['marchandId'] as num?)?.toInt() ?? 0;
          if (id > 0) marchandIds.add(id);
        }
      }

      debugPrint('[MarchandList] marchandIds trouvés: $marchandIds');

      // Étape 2 : charger les infos de chaque marchand en parallèle
      final results = <_UserResult>[];

      await Future.wait(marchandIds.map((marchandId) async {
        final r = await _fetchMarchandInfo(marchandId, token);
        if (r != null) results.add(r);
      }));

      _allMerchants    = results;
      _merchantsLoaded = true;

      if (mounted) {
        setState(() { _isLoadingMerchants = false; });
        _filterMerchantsLocally(initialQuery);
      }
    } catch (e) {
      debugPrint('[MarchandList] error: $e');
      if (mounted) setState(() {
        _merchantError      = 'Erreur de connexion';
        _isLoadingMerchants = false;
      });
    }
  }

  //  Récupère les infos d'un marchand : /api/marchand/get/{id} + /api/profile/public/{id}
  Future<_UserResult?> _fetchMarchandInfo(int marchandId, String token) async {
    try {
      final headers = {
        'Authorization'             : 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      };

      // Appel 1 : infos marchand (businessName, businessType, wilaya, fullName)
      final mRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/marchand/get/$marchandId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      debugPrint('[MarchandGet] $marchandId → ${mRes.statusCode}: ${mRes.body.length > 200 ? mRes.body.substring(0, 200) : mRes.body}');

      if (mRes.statusCode != 200) return null;

      final d = jsonDecode(mRes.body) as Map<String, dynamic>;

      // ✅ Champs réels du backend
      final fullName     = d['fullName']?.toString()     ?? '';
      final businessName = d['businessName']?.toString() ?? '';
      final businessType = d['businessType']?.toString() ?? '';
      final wilaya       = d['wilaya']?.toString()       ?? '';
      final isVerified   = d['statusMarchand']?.toString() == 'VERIFIED';

      // Appel 2 : photo via /api/profile/public/{id}
      String avatar = '';
      try {
        final pRes = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/profile/public/$marchandId'),
          headers: headers,
        ).timeout(const Duration(seconds: 8));

        debugPrint('[ProfilePublic] $marchandId → ${pRes.statusCode}: ${pRes.body.length > 200 ? pRes.body.substring(0, 200) : pRes.body}');

        if (pRes.statusCode == 200) {
          final p = jsonDecode(pRes.body) as Map<String, dynamic>;
          avatar = p['photoUrl']?.toString()
              ?? p['profileImage']?.toString()
              ?? p['photo']?.toString()
              ?? p['profilePhoto']?.toString()
              ?? p['avatarUrl']?.toString()
              ?? '';
          if (avatar.isNotEmpty && !avatar.startsWith('http')) {
            avatar = '${ApiConfig.baseUrl}/$avatar';
          }
        }
      } catch (_) {}

      return _UserResult(
        id:         marchandId,
        name:       fullName.isNotEmpty ? fullName : 'Marchand',
        shopName:   businessName,
        wilaya:     wilaya,
        category:   businessType,
        avatarUrl:  avatar,
        isVerified: isVerified,
        isMerchant: true,
      );
    } catch (e) {
      debugPrint('[MarchandGet] error for $marchandId: $e');
      return null;
    }
  }

  //  Fallback : /api/search → extrait marchandIds → _fetchMarchandInfo
  Future<void> _searchMerchants(String query) async {
    if (!mounted) return;
    setState(() { _isLoadingMerchants = true; _merchantError = null; });
    try {
      final token = UserSession().token ?? '';
      final uri   = Uri.parse('${ApiConfig.baseUrl}/api/search')
          .replace(queryParameters: {'q': query});
      final res   = await http.get(uri, headers: {
        'Authorization'             : 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      }).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        if (mounted) setState(() { _merchantResults = []; _isLoadingMerchants = false; });
        return;
      }

      final body   = jsonDecode(res.body) as Map<String, dynamic>;
      final offres = body['offres'] as List<dynamic>? ?? [];

      final marchandIds = <int>{};
      for (final o in offres) {
        if (o is Map<String, dynamic>) {
          final id = (o['marchandId'] as num?)?.toInt() ?? 0;
          if (id > 0) marchandIds.add(id);
        }
      }

      final results = <_UserResult>[];
      await Future.wait(marchandIds.map((id) async {
        final r = await _fetchMarchandInfo(id, token);
        if (r != null) results.add(r);
      }));

      if (mounted) setState(() {
        _merchantResults    = results;
        _isLoadingMerchants = false;
      });
    } catch (e) {
      debugPrint('[UserSearch] error: $e');
      if (mounted) setState(() {
        _merchantError      = 'Erreur de connexion';
        _isLoadingMerchants = false;
      });
    }
  }

  Future<void> _contactMerchant(_UserResult user) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF72A843))),
    );

    try {
      final conv = await _chatApi.getOrCreateConversation(
        myUserId: widget.myUserId,
        merchantId: user.id,
        merchantName: user.shopName.isNotEmpty ? '${user.shopName} — ${user.name}' : user.name,
        merchantAvatar: user.avatarUrl,
      );
      if (!mounted) return;
      nav.pop();
      nav.push(MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversationId: conv.conversationId,
          receiverId: user.id,
          receiverName: user.shopName.isNotEmpty ? '${user.shopName} — ${user.name}' : user.name,
          receiverAvatar: user.avatarUrl,
          myUserId: widget.myUserId,
          myToken: widget.myToken,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Impossible de contacter cet utilisateur'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _detectGpsLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Please enable location in settings');
        return;
      }
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      final List<Placemark> placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address =
            '${p.street ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}'
                .replaceAll(RegExp(r'^,\s*|,\s*$'), '')
                .replaceAll(RegExp(r',\s*,'), ',');
        if (!mounted) return;
        setState(() {
          _locationText = address;
          _locationController.text = address;
          _placeSuggestions = [];
        });
      }
    } catch (e) {
      _showLocationError('Could not get location. Try again.');
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  void _showLocationError(String msg) {
    if (!mounted) return;
    setState(() => _isLoadingGps = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade400),
    );
  }

  void _onLocationTyped(String input) {
    _debounce?.cancel();
    if (input.trim().isEmpty) {
      setState(() => _placeSuggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchPlaceSuggestions(input);
    });
  }

  Future<void> _fetchPlaceSuggestions(String input) async {
    if (_googleApiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
      if (!mounted) return;
      setState(() {
        _placeSuggestions = [
          {'description': 'Alger, Algérie', 'place_id': 'mock1'},
          {'description': 'Oran, Algérie', 'place_id': 'mock2'},
          {'description': 'Annaba, Algérie', 'place_id': 'mock3'},
          {'description': 'Constantine, Algérie', 'place_id': 'mock4'},
        ]
            .where((s) => (s['description'] as String)
                .toLowerCase()
                .contains(input.toLowerCase()))
            .toList();
      });
      return;
    }
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&components=country:dz'
        '&key=$_googleApiKey',
      );
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions = data['predictions'] as List<dynamic>;
        setState(() {
          _placeSuggestions = predictions
              .map((p) => {
                    'description': p['description'] as String,
                    'place_id': p['place_id'] as String,
                  })
              .toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _placeSuggestions = []);
    }
  }

  void _selectPlace(String description) {
    setState(() {
      _locationText = description;
      _locationController.text = description;
      _placeSuggestions = [];
    });
  }

  Color get _activeColor {
    if (_selectedCategory == null) return const Color(0xFF72A843);
    final cat = widget.categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => {'nameColor': const Color(0xFF72A843)},
    );
    return cat['nameColor'] as Color;
  }

  List<Offer> get _filteredOffers => _backendResults;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),

            // ── Toggle Offers / Merchants ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF72A843).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildToggleTab('Offers', !_isMerchantTab),
                    _buildToggleTab('Merchants', _isMerchantTab),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Search bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isMerchantTab
                            ? const Color(0xFF72A843).withValues(alpha: 0.1)
                            : _activeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller:
                            _isMerchantTab ? _merchantController : null,
                        onChanged: _isMerchantTab
                            ? null
                            : (val) {
                                setState(() => _offerQuery = val);
                                _debounce?.cancel();
                                _debounce = Timer(
                                  const Duration(milliseconds: 400),
                                  _doBackendSearch,
                                );
                              },
                        decoration: InputDecoration(
                          hintText: _isMerchantTab
                              ? _t.searchMerchant
                              : _t.searchOffers,
                          prefixIcon: Icon(Icons.search,
                              color: _isMerchantTab
                                  ? const Color(0xFF72A843)
                                  : _activeColor),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  // Filtre uniquement pour les offres
                  if (!_isMerchantTab) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _showFilters = true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _activeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.tune, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Résultats ──────────────────────────────────────────
            Expanded(
              child: _isMerchantTab
                  ? _buildMerchantResults()
                  : _buildOfferResults(),
            ),
          ],
        ),

        // ── Filtres (uniquement mode offres) ───────────────────────
        if (_showFilters && !_isMerchantTab) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _showFilters = false),
              child: Container(color: Colors.black26),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFilterSheet(),
          ),
        ],
      ],
    );
  }

  // ── Toggle tab widget ──────────────────────────────────────────
  Widget _buildToggleTab(String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _isMerchantTab = label == 'Merchants';
          if (!_isMerchantTab) {
            _merchantController.clear();
            _merchantQuery   = '';
            _merchantResults = List.from(_allMerchants);
          } else if (!_merchantsLoaded && !_isLoadingMerchants) {
            //  Charge tous les marchands dès qu'on clique sur l'onglet
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadAllMerchants('');
            });
          } else if (_merchantsLoaded) {
            _merchantResults = List.from(_allMerchants);
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF72A843) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF72A843),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Merchant results ───────────────────────────────────────────
  Widget _buildMerchantResults() {
    if (_isLoadingMerchants) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF72A843)));
    }
    if (_merchantError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(_merchantError!, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _merchantsLoaded = false;
                _loadAllMerchants(_merchantQuery);
              },
              child: const Text('Réessayer', style: TextStyle(color: Color(0xFF72A843))),
            ),
          ],
        ),
      );
    }
    if (!_merchantsLoaded && _merchantResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF72A843)),
            SizedBox(height: 12),
            Text('Loading merchants...', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }
    if (_merchantResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _merchantQuery.isNotEmpty
                  ? '${_t.noMerchantFound} "$_merchantQuery"'
                  : 'No merchants available',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _merchantQuery.isEmpty
                ? 'All Merchants (${_merchantResults.length})'
                : 'Results for "$_merchantQuery" (${_merchantResults.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF72A843)),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _merchantResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildMerchantCard(_merchantResults[index]),
          ),
        ),
      ],
    );
  }

  // ── Merchant card — marchands uniquement, pas de clients ───────
  Widget _buildMerchantCard(_UserResult user) {
    final displayName = user.shopName.isNotEmpty ? user.shopName : user.name;
    final subName     = user.shopName.isNotEmpty && user.name.isNotEmpty
        ? 'Chez ${user.name}'
        : '';
    final initial     = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    void goToProfile() {
      // ✅ Tous les résultats sont des marchands — plus de ClientPublicProfilePage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MerchantProfilePage(
            merchantId:   user.id,
            merchantName: user.name,
            shopName:     user.shopName,
            avatarUrl:    user.avatarUrl,
            wilaya:       user.wilaya,
            category:     user.category,
            isVerified:   user.isVerified,
            isMerchant:   true,
            onContact:    () => _contactMerchant(user),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: goToProfile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset:     const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ─────────────────────────────────────────────
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF72A843).withValues(alpha: 0.15),
              child: user.avatarUrl.isNotEmpty
                  ? ClipOval(
                      child: AppNetworkImage(
                        url:    user.avatarUrl,
                        width:  52,
                        height: 52,
                        fit:    BoxFit.cover,
                      ),
                    )
                  : Text(
                      initial,
                      style: const TextStyle(
                          fontSize:   20,
                          fontWeight: FontWeight.bold,
                          color:      Color(0xFF72A843)),
                    ),
            ),
            const SizedBox(width: 12),

            // ── Infos ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom boutique
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName.isNotEmpty ? displayName : 'Merchant',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize:   14,
                              color:      Color(0xFF1A1A1A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 14, color: Color(0xFF72A843)),
                      ],
                    ],
                  ),
                  // "Chez NomGerant" sous le nom boutique
                  if (subName.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      subName,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 3),
                  // Wilaya + Catégorie
                  Wrap(
                    spacing: 6,
                    children: [
                      if (user.wilaya.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(user.wilaya, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      if (user.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC9D7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.category,
                            style: const TextStyle(fontSize: 10, color: Color(0xFFCB1B5F), fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── View Profile button ────────────────────────────────
            GestureDetector(
              onTap: goToProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: const Color(0xFF72A843), width: 1.2),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(fontSize: 12, color: Color(0xFF72A843), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildOfferResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(_t.categories,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = widget.categories[index];
              final isSelected = _selectedCategory == cat['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory =
                        isSelected ? null : cat['name'] as String;
                    _filterCategory =
                        isSelected ? null : cat['name'] as String;
                  });
                  _doBackendSearch();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (cat['nameColor'] as Color)
                        : (cat['color'] as Color).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat['name'] as String,
                    style: TextStyle(
                      fontSize: cat['nameSize'] as double,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : cat['nameColor'] as Color,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        if (_filterWilaya != null ||
            _minPrice > 0 ||
            _maxPrice < 10000 ||
            _minDistance > 0 ||
            _maxDistance < 500 ||
            _locationText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Wrap(
              spacing: 6,
              children: [
                if (_filterWilaya != null)
                  _filterChip(_filterWilaya!.split(' - ').last,
                      () => setState(() => _filterWilaya = null)),
                if (_minPrice > 0 || _maxPrice < 10000)
                  _filterChip(
                      '${_minPrice.toInt()}-${_maxPrice.toInt()} DA',
                      () => setState(() {
                            _minPrice = 0;
                            _maxPrice = 10000;
                          })),
                if (_minDistance > 0 || _maxDistance < 500)
                  _filterChip(
                      '${_minDistance.toInt()}-${_maxDistance.toInt()} km',
                      () => setState(() {
                            _minDistance = 0;
                            _maxDistance = 500;
                          })),
                if (_locationText.isNotEmpty)
                  _filterChip(
                    _locationText.length > 20
                        ? '📍 ${_locationText.substring(0, 20)}...'
                        : '📍 $_locationText',
                    () => setState(() {
                      _locationText = '';
                      _locationController.clear();
                    }),
                  ),
              ],
            ),
          ),
        Expanded(
          child: _filteredOffers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        _offerQuery.isNotEmpty
                            ? '${_t.noResultsFor} "$_offerQuery"'
                            : _selectedCategory != null
                                ? '${_t.noOffersIn} $_selectedCategory'
                                : _t.noOffersMatch,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _filteredOffers.length,
                  itemBuilder: (context, index) {
                    final offer = _filteredOffers[index];
                    return _buildOfferCard(
                      title: offer.title,
                      subtitle: offer.description,
                      shop: offer.location,
                      price: offer.price,
                      imageUrl:
                          offer.imageUrl.isNotEmpty ? offer.imageUrl : '',
                      availableUntil: offer.availableUntil,
                      status: offer.status,
                      quantity: offer.quantity,
                      offerId: offer.id,
                      index: index + 2000,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF72A843))),
      deleteIcon:
          const Icon(Icons.close, size: 14, color: Color(0xFF72A843)),
      onDeleted: onRemove,
      backgroundColor: const Color(0xFF72A843).withValues(alpha: 0.1),
      side: const BorderSide(color: Color(0xFF72A843), width: 0.8),
      visualDensity: VisualDensity.compact,
    );
  }

  // ── Offer card ─────────────────────────────────────────────────
  Widget _buildOfferCard({
    required String title,
    required String subtitle,
    required String shop,
    required String price,
    required String imageUrl,
    required int index,
    required String offerId,
    String availableUntil = '',
    String status = 'active',
    String quantity = '',
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ViewOfferPage(
            offerId: offerId,
            title: title,
            description: subtitle,
            location: shop,
            price: price,
            imageUrl: imageUrl,
            availableUntil: availableUntil,
            status: status,
            quantity: quantity,
          ),
        ),
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl.isEmpty
                      ? Container(
                          height: 110,
                          width: 160,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.fastfood,
                              color: Colors.grey, size: 36),
                        )
                      : AppNetworkImage(
                          url: imageUrl,
                          height: 110,
                          width: 160,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: FavoriButton(offerId: offerId),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 11)),
                  Text(shop,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(price,
                      style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter sheet ───────────────────────────────────────────────
  Widget _buildFilterSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          _showFilters = false;
                          _placeSuggestions = [];
                        }),
                        child: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 12),
                      Text(_t.filters,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          _minPrice = 0;
                          _maxPrice = 10000;
                          _filterWilaya = null;
                          _filterCategory = null;
                          _selectedCategory = null;
                          _minDistance = 0;
                          _maxDistance = 500;
                          _locationText = '';
                          _locationController.clear();
                          _placeSuggestions = [];
                        }),
                        child: Text(_t.reset,
                            style:
                                const TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_t.priceRange,
                      style: TextStyle(
                          color: _activeColor,
                          fontWeight: FontWeight.w600)),
                  RangeSlider(
                    values: RangeValues(_minPrice, _maxPrice),
                    min: 0,
                    max: 10000,
                    divisions: 100,
                    activeColor: _activeColor,
                    inactiveColor: _activeColor.withValues(alpha: 0.2),
                    labels: RangeLabels('${_minPrice.toInt()} DA',
                        '${_maxPrice.toInt()} DA'),
                    onChanged: (v) => setState(
                        () {
                          _minPrice = v.start;
                          _maxPrice = v.end;
                        }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_minPrice.toInt()} DA',
                          style: const TextStyle(fontSize: 12)),
                      Text('${_maxPrice.toInt()} DA',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t.city,
                                style: TextStyle(
                                    color: _activeColor,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text(_t.selectWilaya,
                                      style:
                                          const TextStyle(fontSize: 12)),
                                  value: _filterWilaya,
                                  items: widget.wilayas
                                      .map((w) => DropdownMenuItem(
                                          value: w,
                                          child: Text(w,
                                              style: const TextStyle(
                                                  fontSize: 12))))
                                      .toList(),
                                  onChanged: (val) => setState(
                                      () => _filterWilaya = val),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t.categories,
                                style: TextStyle(
                                    color: _activeColor,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text(_t.selectCategory,
                                      style:
                                          const TextStyle(fontSize: 12)),
                                  value: _filterCategory,
                                  items: widget.categories
                                      .map((c) => DropdownMenuItem(
                                          value: c['name'] as String,
                                          child: Text(c['name'] as String,
                                              style: const TextStyle(
                                                  fontSize: 12))))
                                      .toList(),
                                  onChanged: (val) => setState(() {
                                    _filterCategory = val;
                                    _selectedCategory = val;
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_t.location,
                      style: TextStyle(
                          color: _activeColor,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _isLoadingGps ? null : _detectGpsLocation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _activeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _activeColor.withValues(alpha: 0.4),
                            width: 1),
                      ),
                      child: Row(
                        children: [
                          _isLoadingGps
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _activeColor),
                                )
                              : Icon(Icons.my_location,
                                  color: _activeColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isLoadingGps
                                  ? _t.detectingPosition
                                  : _locationText.isNotEmpty
                                      ? _locationText
                                      : _t.useGps,
                              style: TextStyle(
                                fontSize: 13,
                                color: _locationText.isNotEmpty &&
                                        !_isLoadingGps
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_locationText.isNotEmpty && !_isLoadingGps)
                            GestureDetector(
                              onTap: () => setState(() {
                                _locationText = '';
                                _locationController.clear();
                                _placeSuggestions = [];
                              }),
                              child: Icon(Icons.close,
                                  size: 16, color: Colors.grey.shade400),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('OR',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
                      ),
                      Expanded(
                          child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _locationController,
                      onChanged: (val) {
                        setState(() => _locationText = val);
                        _onLocationTyped(val);
                      },
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _t.typeCity,
                        hintStyle: TextStyle(
                            fontSize: 13, color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey.shade400, size: 18),
                        suffixIcon: _locationController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () => setState(() {
                                  _locationText = '';
                                  _locationController.clear();
                                  _placeSuggestions = [];
                                }),
                                child: Icon(Icons.close,
                                    size: 16,
                                    color: Colors.grey.shade400),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 4),
                      ),
                    ),
                  ),
                  if (_placeSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        children: _placeSuggestions.map((s) {
                          return InkWell(
                            onTap: () =>
                                _selectPlace(s['description']!),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 16, color: _activeColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(s['description']!,
                                        style: const TextStyle(
                                            fontSize: 13),
                                        overflow:
                                            TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(_t.distanceRange,
                      style: TextStyle(
                          color: _activeColor,
                          fontWeight: FontWeight.w600)),
                  RangeSlider(
                    values: RangeValues(_minDistance, _maxDistance),
                    min: 0,
                    max: 500,
                    divisions: 50,
                    activeColor: _activeColor,
                    inactiveColor: _activeColor.withValues(alpha: 0.2),
                    labels: RangeLabels('${_minDistance.toInt()} km',
                        '${_maxDistance.toInt()} km'),
                    onChanged: (v) => setState(() {
                      _minDistance = v.start;
                      _maxDistance = v.end;
                    }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_minDistance.toInt()} km',
                          style: const TextStyle(fontSize: 12)),
                      Text('${_maxDistance.toInt()} km',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showFilters = false;
                          _placeSuggestions = [];
                        });
                        _doBackendSearch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _activeColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_t.applyFilters,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}