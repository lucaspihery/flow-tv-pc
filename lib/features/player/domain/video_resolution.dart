/// Classe de résolution de la vidéo, comme dans l'application Flow TV Android.
enum VideoResolution {
  sd('SD'),
  hd('720p'),
  fullHd('1080p'),
  qhd('1440p'),
  uhd('4K');

  const VideoResolution(this.label);

  final String label;

  /// Classe selon la largeur ou la hauteur, la première qui atteint un palier : un flux au format cinéma
  /// est pleine largeur mais avec des bandes (3840×1608 reste du 4K). `null` tant que la taille est inconnue.
  static VideoResolution? of(int width, int height) {
    if (width <= 0 || height <= 0) return null;
    if (width >= 3840 || height >= 2160) return uhd;
    if (width >= 2560 || height >= 1440) return qhd;
    if (width >= 1920 || height >= 1080) return fullHd;
    if (width >= 1280 || height >= 720) return hd;
    return sd;
  }
}

/// Images par seconde arrondies (59,94 s'affiche 60), comme dans l'application Flow TV Android.
extension type const FrameRate(int fps) {
  String get label => '$fps fps';

  static const _min = 5.0;
  static const _max = 300.0;

  /// `null` pour une valeur inconnue ou invraisemblable.
  static FrameRate? of(double? fps) {
    if (fps == null || !fps.isFinite || fps < _min || fps > _max) return null;
    return FrameRate(fps.round());
  }
}
