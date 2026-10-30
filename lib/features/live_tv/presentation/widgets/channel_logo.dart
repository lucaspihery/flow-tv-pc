import 'package:flutter/material.dart';

import '../../domain/channel.dart';
import '../../../../app/theme/app_theme.dart';

/// Logo de la chaîne, avec les initiales en repli si l'image est absente ou cassée.
class ChannelLogo extends StatelessWidget {
  const ChannelLogo({super.key, required this.channel, this.size = 56});

  final Channel channel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = _Initials(name: channel.name, size: size);
    final logo = channel.logoUrl;
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: logo == null
            ? fallback
            : Image.network(
                logo,
                fit: BoxFit.contain,
                cacheWidth: (size * 2).round(),
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
    final initials = words.map((w) => w.characters.first.toUpperCase()).join();
    return Container(
      color: AppColors.surfaceHigh,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w700, color: AppColors.textMuted),
      ),
    );
  }
}
