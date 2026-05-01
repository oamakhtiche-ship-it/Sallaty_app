import 'package:flutter/material.dart';
import 'favori_store.dart';
import 'usersession.dart';

class FavoriButton extends StatefulWidget {
  final String offerId;
  const FavoriButton({super.key, required this.offerId});

  @override
  State<FavoriButton> createState() => _FavoriButtonState();
}

class _FavoriButtonState extends State<FavoriButton> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    FavoriStore().addListener(_rebuild);
  }

  @override
  void dispose() {
    FavoriStore().removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (UserSession().token == null) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    debugPrint('[FavoriButton] toggle offerId="${widget.offerId}"');
    debugPrint('[FavoriButton] avant isFav=${FavoriStore().isFavori(widget.offerId)}');

    await FavoriStore().toggleFavori(widget.offerId);

    debugPrint('[FavoriButton] après isFav=${FavoriStore().isFavori(widget.offerId)}');

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isFav = FavoriStore().isFavori(widget.offerId);

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
            ),
          ],
        ),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(7),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.red,
                ),
              )
            : Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : Colors.grey.shade400,
                size: 18,
              ),
      ),
    );
  }
}