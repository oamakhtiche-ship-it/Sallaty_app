import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════
//  HELP / FAQ PAGE
//
//  Endpoints utilisés :
//  GET    /api/static/help                    → tous les FAQs
//  GET    /api/static/help/{category}         → FAQ par catégorie
//  GET    /api/static/help/{category}/{id}    → une réponse FAQ
//  POST   /api/static/help/add                → ajouter FAQ (ADMIN)
//  PUT    /api/static/help/{category}/{id}    → modifier FAQ (ADMIN)
//  DELETE /api/static/help/{category}/{id}    → supprimer FAQ (ADMIN)
// ═══════════════════════════════════════════════

// ─────────────────────────────────────────────
//  MODEL — FaqItem
// ─────────────────────────────────────────────
class FaqItem {
  final int id;
  final String category;
  final String question;
  final String answer;
  final int displayOrder;

  const FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.displayOrder,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) => FaqItem(
        id:           json['id']           ?? 0,
        category:     json['category']     ?? '',
        question:     json['question']     ?? '',
        answer:       json['answer']       ?? '',
        displayOrder: json['displayOrder'] ?? 0,
      );
}

// ─────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────
class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  // ─────────────────────────────────────────────
  //  CONSTANTS
  // ─────────────────────────────────────────────
  static const String _baseUrl =
      'https://headstand-rosy-chlorine.ngrok-free.dev';

  // ─────────────────────────────────────────────
  //  STATE
  // ─────────────────────────────────────────────
  List<FaqItem> _faqItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Pour le formulaire d'ajout/modification
  int? _editingId;
  String? _editingCategory;
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController   = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  bool _showForm = false;
  bool _isSaving = false;

  // ─────────────────────────────────────────────
  //  LIFECYCLE
  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchAllFaq();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  GET /api/static/help
  // ─────────────────────────────────────────────
  Future<void> _fetchAllFaq() async {
    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/static/help'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _faqItems = data.map((e) => FaqItem.fromJson(e)).toList();
        });
      } else {
        setState(() {
          _errorMessage =
              'Erreur lors du chargement (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connexion impossible : $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────
  //  POST /api/static/help/add  (ADMIN)
  // ─────────────────────────────────────────────
  Future<void> _addFaq() async {
    final category = _categoryController.text.trim().toUpperCase();
    final question = _questionController.text.trim();
    final answer   = _answerController.text.trim();

    if (category.isEmpty || question.isEmpty || answer.isEmpty) {
      _showSnackBar('Tous les champs sont obligatoires.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uri = Uri.parse('$_baseUrl/api/static/help/add').replace(
        queryParameters: {
          'category': category,
          'question': question,
          'answer':   answer,
          'displayOrder': '0',
        },
      );

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          // TODO: 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _showSnackBar('FAQ ajoutée ✅');
        _resetForm();
        await _fetchAllFaq();
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(
          data['message'] ?? 'Erreur lors de l\'ajout.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Connexion impossible : $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────
  //  PUT /api/static/help/{category}/{id}  (ADMIN)
  // ─────────────────────────────────────────────
  Future<void> _updateFaq() async {
    if (_editingId == null || _editingCategory == null) return;

    final question = _questionController.text.trim();
    final answer   = _answerController.text.trim();

    setState(() => _isSaving = true);

    try {
      final uri = Uri.parse(
        '$_baseUrl/api/static/help/$_editingCategory/$_editingId',
      ).replace(
        queryParameters: {
          if (question.isNotEmpty) 'question': question,
          if (answer.isNotEmpty)   'answer':   answer,
        },
      );

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          // TODO: 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _showSnackBar('FAQ mise à jour ✅');
        _resetForm();
        await _fetchAllFaq();
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(
          data['message'] ?? 'Erreur lors de la mise à jour.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Connexion impossible : $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────
  //  DELETE /api/static/help/{category}/{id}  (ADMIN)
  // ─────────────────────────────────────────────
  Future<void> _deleteFaq(FaqItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Supprimer cette FAQ ?',
          style: TextStyle(fontFamily: 'poppins', fontWeight: FontWeight.w600),
        ),
        content: Text(
          item.question,
          style: const TextStyle(fontFamily: 'poppins', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse(
            '$_baseUrl/api/static/help/${item.category}/${item.id}'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          // TODO: 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _showSnackBar('FAQ supprimée ✅');
        await _fetchAllFaq();
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(
          data['message'] ?? 'Erreur lors de la suppression.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Connexion impossible : $e', isError: true);
    }
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────
  void _startEdit(FaqItem item) {
    setState(() {
      _editingId       = item.id;
      _editingCategory = item.category;
      _categoryController.text = item.category;
      _questionController.text = item.question;
      _answerController.text   = item.answer;
      _showForm = true;
    });
  }

  void _resetForm() {
    setState(() {
      _editingId       = null;
      _editingCategory = null;
      _showForm        = false;
    });
    _categoryController.clear();
    _questionController.clear();
    _answerController.clear();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF72A843),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Group FAQ by category
  Map<String, List<FaqItem>> get _groupedFaq {
    final Map<String, List<FaqItem>> map = {};
    for (final item in _faqItems) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4CAF50)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Help / FAQ',
          style: TextStyle(
            fontSize: 24,
            color: Color(0xFF72A843),
            fontFamily: 'poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showForm ? Icons.close : Icons.add_circle_outline,
              color: const Color(0xFF72A843),
            ),
            tooltip: _showForm ? 'Fermer' : 'Ajouter une FAQ',
            onPressed: () {
              if (_showForm) {
                _resetForm();
              } else {
                setState(() => _showForm = true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            // ─── Form (Add / Edit) ──────────────────────────────────
            if (_showForm) _buildForm(),

            // ─── FAQ List ───────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF72A843),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildError()
                      : _faqItems.isEmpty
                          ? _buildEmpty()
                          : _buildFaqList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  WIDGET — Form
  // ─────────────────────────────────────────────
  Widget _buildForm() {
    final isEditing = _editingId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'Modifier FAQ' : 'Ajouter une FAQ',
            style: const TextStyle(
              fontFamily: 'poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          // Category
          if (!isEditing)
            _buildTextField(
              controller: _categoryController,
              hint: 'Catégorie (ex: ORDERS_DELIVERY)',
              icon: Icons.category_outlined,
            ),
          if (!isEditing) const SizedBox(height: 10),
          // Question
          _buildTextField(
            controller: _questionController,
            hint: 'Question',
            icon: Icons.help_outline,
          ),
          const SizedBox(height: 10),
          // Answer
          _buildTextField(
            controller: _answerController,
            hint: 'Réponse',
            icon: Icons.message_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetForm,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF72A843)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(
                      color: Color(0xFF72A843),
                      fontFamily: 'poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : (isEditing ? _updateFaq : _addFaq),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEditing ? 'Modifier' : 'Ajouter',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        fontFamily: 'poppins',
        fontSize: 14,
        color: Color(0xFF333333),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'poppins',
          color: Color(0xFF878986),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF72A843), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FBF6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  WIDGET — FAQ List grouped by category
  // ─────────────────────────────────────────────
  Widget _buildFaqList() {
    final grouped = _groupedFaq;

    return ListView.builder(
      itemCount: grouped.keys.length,
      itemBuilder: (context, idx) {
        final category = grouped.keys.elementAt(idx);
        final items    = grouped[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: const TextStyle(
                      fontFamily: 'poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
            // FAQ items
            ...items.map((item) => _buildFaqCard(item)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildFaqCard(FaqItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconColor: const Color(0xFF72A843),
        collapsedIconColor: const Color(0xFF72A843),
        title: Text(
          item.question,
          style: const TextStyle(
            fontFamily: 'poppins',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF333333),
          ),
        ),
        children: [
          // Answer
          Text(
            item.answer,
            style: const TextStyle(
              fontFamily: 'poppins',
              fontSize: 13,
              color: Color(0xFF555555),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          // Edit / Delete buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionBtn(
                icon: Icons.edit_outlined,
                color: const Color(0xFF72A843),
                tooltip: 'Modifier',
                onTap: () => _startEdit(item),
              ),
              const SizedBox(width: 8),
              _buildActionBtn(
                icon: Icons.delete_outline,
                color: Colors.red,
                tooltip: 'Supprimer',
                onTap: () => _deleteFaq(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  WIDGET — Error
  // ─────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontFamily: 'poppins',
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _fetchAllFaq,
            icon: const Icon(Icons.refresh, color: Color(0xFF72A843)),
            label: const Text(
              'Réessayer',
              style: TextStyle(color: Color(0xFF72A843)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  WIDGET — Empty
  // ─────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline,
              size: 64,
              color: const Color(0xFF72A843).withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text(
            'Aucune FAQ disponible.',
            style: TextStyle(
              fontFamily: 'poppins',
              color: Color(0xFF878986),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _showForm = true),
            icon: const Icon(Icons.add, color: Color(0xFF72A843)),
            label: const Text(
              'Ajouter une FAQ',
              style: TextStyle(color: Color(0xFF72A843)),
            ),
          ),
        ],
      ),
    );
  }
}