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
    final json = await _call();
    final userInfo = json is Map<String, Object?> ? json['user_info'] : null;
    if (userInfo is! Map<String, Object?>) {
      throw const AuthException('Identifiants refusés ou serveur Xtream invalide.');
    }
    final info = XtreamUserInfo.fromJson(userInfo);
    if (!info.authenticated) throw const AuthException('Nom d\'utilisateur ou mot de passe incorrect.');
    if (!info.isActive) throw AuthException('Abonnement inactif (statut : ${info.status}).');
    return info;
  }

  Future<List<XtreamCategory>> liveCategories() async =>
      _list(await _call('get_live_categories')).map(XtreamCategory.fromJson).toList();

  Future<List<XtreamLiveStream>> liveStreams() async =>
      _list(await _call('get_live_streams')).map(XtreamLiveStream.fromJson).toList();

  String liveStreamUrl(String streamId, {String extension = 'ts'}) {
    final user = Uri.encodeComponent(account.username);
    final pass = Uri.encodeComponent(account.password);
    return '${account.serverUrl}/live/$user/$pass/$streamId.$extension';
  }

  Future<Object?> _call([String? action]) {
    final uri = Uri.parse('${account.serverUrl}/player_api.php')
        .replace(queryParameters: {'username': account.username, 'password': account.password, 'action': ?action});
    return _http.getJson(uri);
  }

  static Iterable<Map<String, Object?>> _list(Object? json) {
    if (json is! List) throw const ParseException('Réponse inattendue du serveur Xtream.');
    return json.whereType<Map<String, Object?>>();
  }
}
