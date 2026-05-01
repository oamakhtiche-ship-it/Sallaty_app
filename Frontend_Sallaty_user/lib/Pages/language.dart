import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'apiservice.dart';
import 'usersession.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _selectedLanguage = 'English';
  bool   _isSaving         = false;

  final List<String> _languages = ['English', 'French', 'Arabic'];

  final Map<String, Locale> _localeMap = {
    'English': const Locale('en'),
    'French' : const Locale('fr'),
    'Arabic' : const Locale('ar'),
  };

  // Backend attend 'en', 'fr', 'ar'
  final Map<String, String> _langCodeMap = {
    'English': 'en',
    'French' : 'fr',
    'Arabic' : 'ar',
  };

  @override
  void initState() {
    super.initState();
    // Pré-sélectionne la langue actuelle de l'app
    final currentLocale = appLocale.value.languageCode;
    _selectedLanguage = _localeMap.entries
        .firstWhere((e) => e.value.languageCode == currentLocale,
            orElse: () => _localeMap.entries.first)
        .key;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    // 1. Change la langue localement
    appLocale.value = _localeMap[_selectedLanguage]!;

    // 2. Sauvegarde dans le backend
    final userId = UserSession().id;
    if (userId != null) {
      try {
        final langCode = _langCodeMap[_selectedLanguage] ?? 'en';
        await http.put(
          Uri.parse(
              '${ApiConfig.baseUrl}/api/settings/$userId/language/$langCode'),
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Authorization': 'Bearer ${UserSession().token ?? ''}',
          },
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('[LanguagePage] sync error: $e');
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F7EC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Language',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Select Language',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  ..._languages.asMap().entries.map((entry) {
                    final index  = entry.key;
                    final lang   = entry.value;
                    final isLast = index == _languages.length - 1;

                    return Column(
                      children: [
                        InkWell(
                          onTap: () =>
                              setState(() => _selectedLanguage = lang),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(lang,
                                    style:
                                        const TextStyle(fontSize: 16)),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _selectedLanguage == lang
                                        ? const Color(0xFF72A843)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _selectedLanguage == lang
                                          ? const Color(0xFF72A843)
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF72A843),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Save Preferences',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}