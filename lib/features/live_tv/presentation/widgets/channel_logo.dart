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
    // Teinte stable par chaîne, choisie dans la palette du logo.
    const palette = [AppColors.cyan, AppColors.blue, AppColors.violet, AppColors.magenta];
    final tint = palette[name.codeUnits.fold(0, (a, b) => a + b) % palette.length];
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.55), AppColors.violet.withValues(alpha: 0.25)],
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}
