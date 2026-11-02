import 'package:flutter/material.dart';

import '../../domain/channel.dart';
import '../../../../app/theme/app_theme.dart';

/// Logo de la chaîne, avec les initiales en repli si l'image est absente ou cassée.
class ChannelLogo extends StatelessWidget {
  const ChannelLogo({super.key, required this.channel, this.size = 56});

  final Channel channel;
  final double size;

  /// Logos déjà en échec pendant cette session. Flutter ne garde pas les erreurs en cache : sans
  /// ce registre, chaque logo cassé serait retéléchargé à chaque passage de la tuile à l'écran.
  static final _broken = <String>{};

  @override
  Widget build(BuildContext context) {
    final fallback = _Initials(name: channel.name, size: size);
    final url = channel.logoUrl;
    final logo = url == null || _broken.contains(url) ? null : url;
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: logo == null
            ? fallback
            : Image.network(
                logo,
                fit: BoxFit.contain,
                // Décodé à la taille affichée (×2 pour les écrans haute densité), pas en pleine résolution.
                cacheWidth: (size * 2).round(),
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) {
                  _broken.add(logo);
                  return fallback;
                },
              ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size});

  static final _spaces = RegExp(r'\s+');

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final words = name.split(_spaces).where((w) => w.isNotEmpty).take(2);
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
