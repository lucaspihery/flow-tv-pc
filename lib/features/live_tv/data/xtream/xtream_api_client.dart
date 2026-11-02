import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/http_service.dart';
import '../../../auth/domain/iptv_account.dart';
import 'xtream_models.dart';

/// Client de l'API Xtream Codes.
///
/// Endpoints utilisés :
/// - `player_api.php?username=…&password=…` : infos du compte
/// - `…&action=get_live_categories` / `get_live_streams` : TV en direct
/// - `/live/{user}/{pass}/{stream_id}.{ext}` : URL de lecture
class XtreamApiClient {
  XtreamApiClient(this._http, this.account);

  final HttpService _http;
  final XtreamAccount account;

  Future<XtreamUserInfo> authenticate() async {
    final json = await _call(null, _identity);
    final userInfo = json is Map<String, Object?> ? json['user_info'] : null;
    if (userInfo is! Map<String, Object?>) {
      throw const AuthException('Identifiants refusés ou serveur Xtream invalide.');
    }
    final info = XtreamUserInfo.fromJson(userInfo);
    if (!info.authenticated) throw const AuthException('Nom d\'utilisateur ou mot de passe incorrect.');
    if (!info.isActive) throw AuthException('Abonnement inactif (statut : ${info.status}).');
    return info;
  }

  Future<List<XtreamCategory>> liveCategories() => _call('get_live_categories', _parseCategories);

  /// Peut compter des dizaines de milliers d'entrées : décodée hors du thread de l'interface.
  Future<List<XtreamLiveStream>> liveStreams() => _call('get_live_streams', _parseStreams);

  String liveStreamUrl(String streamId, {String extension = 'ts'}) {
    final user = Uri.encodeComponent(account.username);
    final pass = Uri.encodeComponent(account.password);
    return '${account.serverUrl}/live/$user/$pass/$streamId.$extension';
  }

  Future<T> _call<T>(String? action, T Function(Object? json) convert) {
    final uri = Uri.parse('${account.serverUrl}/player_api.php')
        .replace(queryParameters: {'username': account.username, 'password': account.password, 'action': ?action});
    return _http.getJson(uri, convert);
  }

  // Fonctions statiques : elles peuvent être exécutées dans un isolate.
  static Object? _identity(Object? json) => json;

  static List<XtreamCategory> _parseCategories(Object? json) => _list(json).map(XtreamCategory.fromJson).toList();

  static List<XtreamLiveStream> _parseStreams(Object? json) => _list(json).map(XtreamLiveStream.fromJson).toList();

  static Iterable<Map<String, Object?>> _list(Object? json) {
    if (json is! List) throw const ParseException('Réponse inattendue du serveur Xtream.');
    return json.whereType<Map<String, Object?>>();
  }
}
