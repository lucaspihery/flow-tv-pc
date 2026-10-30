import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/http_service.dart';
import '../../live_tv/data/xtream/xtream_api_client.dart';
import '../data/account_storage.dart';
import '../domain/iptv_account.dart';

final authControllerProvider = NotifierProvider<AuthController, IptvAccount?>(AuthController.new);

/// Compte actuellement connecté (`null` = écran de connexion).
class AuthController extends Notifier<IptvAccount?> {
  @override
  IptvAccount? build() => ref.read(accountStorageProvider).read();

  /// Vérifie les identifiants auprès du serveur avant de les enregistrer.
  Future<void> signInWithXtream({required String server, required String username, required String password}) async {
    final account = XtreamAccount(
      serverUrl: XtreamAccount.normalizeServerUrl(server),
      username: username.trim(),
      password: password,
    );
    await XtreamApiClient(ref.read(httpServiceProvider), account).authenticate();
    await _save(account);
  }

  /// La playlist est téléchargée et validée par l'écran des chaînes.
  Future<void> signInWithM3u({required String location, required bool isLocalFile}) =>
      _save(M3uAccount(location: location.trim(), isLocalFile: isLocalFile));

  Future<void> signOut() async {
    await ref.read(accountStorageProvider).clear();
    state = null;
  }

  Future<void> _save(IptvAccount account) async {
    await ref.read(accountStorageProvider).write(account);
    state = account;
  }
}
