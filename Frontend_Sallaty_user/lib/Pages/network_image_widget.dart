import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'apiservice.dart';

class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final fullUrl = ApiService.buildImageUrl(url);

    assert(() {
      debugPrint('[AppNetworkImage] url="${fullUrl.isNotEmpty ? fullUrl : '<empty — showing placeholder>'}"}');
      return true;
    }());

    if (fullUrl.isEmpty) {
      return placeholder ?? _defaultPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: fullUrl,
      width: width,
      height: height,
      fit: fit,
      // ✅ Forces a fresh cache entry per URL — prevents stale HTML
      //    responses (from ngrok warning page) being reused
      cacheKey: fullUrl,
      httpHeaders: const {
        'ngrok-skip-browser-warning': 'true',
        'Accept': 'image/*, */*',
      },
      placeholder: (_, __) => _loadingWidget(),
      errorWidget: (context, errUrl, error) {
        debugPrint('[AppNetworkImage] ERROR loading: $errUrl\n  → $error');
        return placeholder ?? _defaultPlaceholder();
      },
    );
  }

  Widget _loadingWidget() => Container(
        width: width,
        height: height,
        color: Colors.grey.shade100,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF72A843),
            ),
          ),
        ),
      );

  Widget _defaultPlaceholder() => Container(
        width: width,
        height: height,
        color: Colors.grey.shade100,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
}