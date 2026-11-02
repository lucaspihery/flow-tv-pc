import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/channel.dart';
import '../../../../app/theme/app_theme.dart';

/// Logo de la chaîne, avec les initiales en repli si l'image est absente ou cassée.
///
/// Le téléchargement ne démarre que si la tuile reste à l'écran un court instant : en faisant
/// défiler une grande catégorie, les centaines de tuiles qui ne font que passer ne lancent plus
/// chacune un téléchargement et un décodage, qui saturaient le réseau et ralentissaient l'affichage.
class ChannelLogo extends StatefulWidget {
  const ChannelLogo({super.key, required this.channel, this.size = 56});

  final Channel channel;
  final double size;

  /// Temps pendant lequel une tuile doit rester construite avant de charger son logo.
  static const loadDelay = Duration(milliseconds: 150);

  @override
  State<ChannelLogo> createState() => _ChannelLogoState();
}

class _ChannelLogoState extends State<ChannelLogo> {
  /// Logos déjà en échec pendant cette session. Flutter ne garde pas les erreurs en cache : sans
  /// ce registre, chaque logo cassé serait retéléchargé à chaque passage de la tuile à l'écran.
  static final _broken = <String>{};

  /// Logos déjà affichés une fois : ils sont en cache, on les montre sans attendre.
  static final _shown = <String>{};

  Timer? _delay;
  bool _load = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(ChannelLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channel.logoUrl != widget.channel.logoUrl) _schedule();
  }

  void _schedule() {
    _delay?.cancel();
    final url = widget.channel.logoUrl;
    _load = url != null && _shown.contains(url);
    if (url == null || _load || _broken.contains(url)) return;
    _delay = Timer(ChannelLogo.loadDelay, () {
      if (mounted) setState(() => _load = true);
    });
  }

  @override
  void dispose() {
    // Tuile sortie de l'écran avant la fin du délai : rien n'est téléchargé.
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final fallback = _Initials(name: widget.channel.name, size: size);
    final url = widget.channel.logoUrl;
    final logo = !_load || url == null || _broken.contains(url) ? null : url;
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
                frameBuilder: (context, child, frame, _) {
                  if (frame == null) return fallback;
                  _shown.add(logo);
                  return child;
                },
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
