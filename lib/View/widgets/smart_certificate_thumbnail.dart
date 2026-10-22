import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../Services/fetch_data_from_server_service.dart';

/// An optimized image widget for certificate thumbnails that:
/// 1. Caches remote server thumbnails on disk via [CachedNetworkImage].
/// 2. Seamlessly falls back to local assets if offline/server unavailable.
/// 3. Downsamples image decoding via [memCacheWidth] to prevent memory spikes on low-end devices.
class SmartCertificateThumbnail extends StatelessWidget {
  final String thumbnailPath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartCertificateThumbnail({
    super.key,
    required this.thumbnailPath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (thumbnailPath.isEmpty) {
      return _buildErrorPlaceholder();
    }

    final double dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    final int? memWidth = width != null ? (width! * dpr).round() : null;

    final String fullUrl = FetchDataFromServerServices.resolveThumbnailUrl(thumbnailPath);

    if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: fullUrl,
        fit: fit,
        memCacheWidth: memWidth,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) => placeholder ?? Container(
          color: const Color(0xFFE2E8F0),
        ),
        errorWidget: (context, url, error) {
          if (errorWidget != null) return errorWidget!;
          // Fallback to local asset if bundled
          final String localAsset = thumbnailPath.startsWith('assets/')
              ? thumbnailPath
              : 'assets/$thumbnailPath';
          return Image.asset(
            localAsset,
            fit: fit,
            cacheWidth: memWidth,
            errorBuilder: (ctx, err, stack) => errorWidget ?? _buildErrorPlaceholder(),
          );
        },
      );
    }

    // Direct local asset
    final String localAsset = thumbnailPath.startsWith('assets/')
        ? thumbnailPath
        : 'assets/$thumbnailPath';
    return Image.asset(
      localAsset,
      fit: fit,
      cacheWidth: memWidth,
      errorBuilder: (ctx, err, stack) => _buildErrorPlaceholder(),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF94A3B8),
          size: 24,
        ),
      ),
    );
  }
}
