/// Une chaîne issue d'une playlist M3U.
class Channel {
  const Channel({required this.name, required this.url, this.logo, this.group = Channel.defaultGroup, this.tvgId});

  static const defaultGroup = 'Sans catégorie';

  final String name;
  final String url;
  final String? logo;
  final String group;
  final String? tvgId;

  @override
  String toString() => 'Channel($name, $group, $url)';
}
