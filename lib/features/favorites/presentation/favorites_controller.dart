import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../live_tv/domain/channel.dart';
import '../data/favorites_storage.dart';

final favoritesProvider = NotifierProvider<FavoritesController, Set<String>>(FavoritesController.new);

/// Identifiants des chaînes favorites du compte connecté, dans l'ordre d'ajout.
class FavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final account = ref.watch(authControllerProvider);
    if (account == null) return const {};
    return ref.read(favoritesStorageProvider).read(account.storageKey).toSet();
  }

  bool isFavorite(Channel channel) => state.contains(channel.id);

  Future<void> toggle(Channel channel) => isFavorite(channel) ? remove(channel) : add(channel);

  Future<void> add(Channel channel) => _save({...state, channel.id});

  Future<void> remove(Channel channel) => _save({...state}..remove(channel.id));

  Future<void> _save(Set<String> ids) async {
    state = ids;
    final account = ref.read(authControllerProvider);
    if (account != null) await ref.read(favoritesStorageProvider).write(account.storageKey, ids);
  }
}
