import 'package:flutter/widgets.dart';

/// Contrôleur de défilement qui anime les crans de molette au lieu de sauter d'un coup.
///
/// Par défaut, Flutter applique chaque cran de molette (≈ 100 px) instantanément : la grille
/// avance par à-coups et paraît saccadée. Ici chaque cran lance une courte animation vers la
/// cible, et les crans rapprochés s'additionnent. Pendant l'animation, la liste ignore le
/// pointeur : les tuiles qui défilent sous la souris ne déclenchent plus leurs effets de survol.
/// Les pavés tactiles (défilement précis) ne passent pas par ici et restent inchangés.
class SmoothScrollController extends ScrollController {
  SmoothScrollController({this.duration = const Duration(milliseconds: 180), this.curve = Curves.easeOutCubic});

  final Duration duration;
  final Curve curve;

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) =>
      _SmoothScrollPosition(
        duration: duration,
        curve: curve,
        physics: physics,
        context: context,
        oldPosition: oldPosition,
        initialPixels: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
        debugLabel: debugLabel,
      );
}

class _SmoothScrollPosition extends ScrollPositionWithSingleContext {
  _SmoothScrollPosition({
    required this.duration,
    required this.curve,
    required super.physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
    super.keepScrollOffset,
    super.debugLabel,
  });

  final Duration duration;
  final Curve curve;

  /// Destination de l'animation en cours, à laquelle s'ajoutent les crans suivants.
  double? _target;

  @override
  void pointerScroll(double delta) {
    if (delta == 0) return super.pointerScroll(delta);
    final from = _target ?? pixels;
    final target = (from + delta).clamp(minScrollExtent, maxScrollExtent);
    if (target == from) return;
    _target = target;
    animateTo(target, duration: duration, curve: curve).whenComplete(() {
      if (_target == target) _target = null;
    });
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    // Un glisser, un clic dans la barre ou un saut programmé annule la cible en cours.
    if (newActivity is! DrivenScrollActivity) _target = null;
    super.beginActivity(newActivity);
  }
}
