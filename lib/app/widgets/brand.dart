import 'package:flutter/material.dart';

/// Chemins des logos déclarés dans `pubspec.yaml`.
class BrandAssets {
  static const logo = 'assets/images/logo.png';
  static const banner = 'assets/images/logo_banner.png';
  static const mark = 'assets/images/logo_mark.png';
}

/// Logo « F TV » sans fond.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    BrandAssets.mark,
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
  );
}

/// Logo horizontal « Flow TV » (fond bleu nuit intégré).
///
/// Le format par défaut, plus large que l'image, rogne les marges vides en haut et en bas.
class BrandBanner extends StatelessWidget {
  const BrandBanner({super.key, this.borderRadius = 20, this.aspectRatio = 2.6});

  final double borderRadius;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: AspectRatio(
      aspectRatio: aspectRatio,
      child: Image.asset(BrandAssets.banner, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
    ),
  );
}
