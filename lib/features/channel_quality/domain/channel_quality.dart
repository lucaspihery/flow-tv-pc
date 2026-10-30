/// Qualité vidéo d'une chaîne, telle que le lecteur l'a mesurée la dernière fois qu'elle a été regardée.
class ChannelQuality {
  const ChannelQuality({required this.resolution, this.frameRate});

  /// Classe de résolution telle que le lecteur l'affiche, ex. `4K` ou `1080p`.
  final String resolution;

  /// Images par seconde, `null` quand le lecteur n'a pas pu les mesurer.
  final int? frameRate;

  /// Ex. `4K · 50 fps`, ou seulement `4K` si les fps sont inconnus.
  String get label => frameRate == null ? resolution : '$resolution · $frameRate fps';

  Map<String, Object?> toJson() => {'resolution': resolution, 'frameRate': frameRate};

  static ChannelQuality? fromJson(Object? json) {
    if (json is! Map) return null;
    final resolution = json['resolution'];
    if (resolution is! String) return null;
    final frameRate = json['frameRate'];
    return ChannelQuality(resolution: resolution, frameRate: frameRate is int ? frameRate : null);
  }

  @override
  bool operator ==(Object other) =>
      other is ChannelQuality && other.resolution == resolution && other.frameRate == frameRate;

  @override
  int get hashCode => Object.hash(resolution, frameRate);
}
