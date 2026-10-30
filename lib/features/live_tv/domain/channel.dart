/// Une chaîne en direct, quelle que soit sa source (M3U ou Xtream Codes).
class Channel {
  const Channel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.group = defaultGroup,
  });

  static const defaultGroup = 'Sans catégorie';

  /// Identifiant stable dans la source (stream_id Xtream, ou URL du flux en M3U).
  /// Sert de clé pour les favoris.
  final String id;
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String group;

  @override
  bool operator ==(Object other) => other is Channel && other.id == id && other.streamUrl == streamUrl;

  @override
  int get hashCode => Object.hash(id, streamUrl);

  @override
  String toString() => 'Channel($name, $group)';
}
