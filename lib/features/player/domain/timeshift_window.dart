/// Fenêtre de timeshift : portion du direct gardée en cache, dans laquelle on peut revenir en arrière.
///
/// Les durées sont des horodatages du flux (temps de lecture mpv), pas des heures réelles.
class TimeshiftWindow {
  const TimeshiftWindow({required this.start, required this.liveEdge, required this.position});

  /// Instant le plus ancien encore disponible dans le cache.
  final Duration start;

  /// Instant le plus récent reçu : le « direct ».
  final Duration liveEdge;

  /// Position de lecture actuelle.
  final Duration position;

  /// En dessous de ce retard, on considère que la lecture est en direct.
  static const liveTolerance = Duration(seconds: 6);

  Duration get length => liveEdge - start;

  /// Retard par rapport au direct (jamais négatif).
  Duration get behindLive {
    final behind = liveEdge - position;
    return behind.isNegative ? Duration.zero : behind;
  }

  bool get isLive => behindLive <= liveTolerance;

  bool get canGoBack => position - start > const Duration(seconds: 1);

  /// Ramène une position demandée dans les bornes de la fenêtre.
  Duration clamp(Duration target) {
    if (target < start) return start;
    if (target > liveEdge) return liveEdge;
    return target;
  }
}
