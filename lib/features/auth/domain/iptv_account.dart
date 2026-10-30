/// Compte IPTV de l'utilisateur : soit un accès Xtream Codes, soit une playlist M3U.
sealed class IptvAccount {
  const IptvAccount();

  /// Libellé court affiché dans l'interface.
  String get displayName;

  /// Identifie le compte pour les données qui lui sont propres (favoris…).
  String get storageKey;

  Map<String, Object?> toJson();

  static IptvAccount fromJson(Map<String, Object?> json) => switch (json['type']) {
    XtreamAccount.type => XtreamAccount(
      serverUrl: json['serverUrl']! as String,
      username: json['username']! as String,
      password: json['password']! as String,
    ),
    M3uAccount.type => M3uAccount(location: json['location']! as String, isLocalFile: json['isLocalFile']! as bool),
    final other => throw FormatException('Type de compte inconnu : $other'),
  };
}

class XtreamAccount extends IptvAccount {
  const XtreamAccount({required this.serverUrl, required this.username, required this.password});

  static const type = 'xtream';

  /// URL de base normalisée, sans slash final (ex. `http://exemple.com:8080`).
  final String serverUrl;
  final String username;
  final String password;

  @override
  String get displayName => '$username@${Uri.tryParse(serverUrl)?.host ?? serverUrl}';

  @override
  String get storageKey => 'xtream:$serverUrl:$username';

  @override
  Map<String, Object?> toJson() => {'type': type, 'serverUrl': serverUrl, 'username': username, 'password': password};

  /// Accepte « exemple.com:8080 », « http://exemple.com:8080/ » ou une URL `player_api.php`.
  static String normalizeServerUrl(String input) {
    var url = input.trim();
    if (!url.contains('://')) url = 'http://$url';
    final uri = Uri.parse(url);
    var path = uri.path;
    for (final suffix in ['/player_api.php', '/get.php']) {
      if (path.endsWith(suffix)) path = path.substring(0, path.length - suffix.length);
    }
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return '${uri.scheme}://${uri.authority}$path';
  }
}

class M3uAccount extends IptvAccount {
  const M3uAccount({required this.location, required this.isLocalFile});

  static const type = 'm3u';

  /// URL de la playlist ou chemin du fichier local.
  final String location;
  final bool isLocalFile;

  @override
  String get storageKey => 'm3u:$location';

  @override
  String get displayName => isLocalFile ? location.split(RegExp(r'[\\/]')).last : 'Playlist M3U';

  @override
  Map<String, Object?> toJson() => {'type': type, 'location': location, 'isLocalFile': isLocalFile};
}
