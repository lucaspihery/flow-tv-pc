import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/channel_quality_storage.dart';
import '../domain/channel_quality.dart';

final channelQualitiesProvider = NotifierProvider<ChannelQualitiesController, Map<String, ChannelQuality>>(
  ChannelQualitiesController.new,
);

/// Qualité mesurée par le lecteur pour les chaînes déjà regardées du compte connecté, par identifiant de chaîne.
class ChannelQualitiesController extends Notifier<Map<String, ChannelQuality>> {
  @override
  Map<String, ChannelQuality> build() {
    final account = ref.watch(authControllerProvider);
    if (account == null) return const {};
    return ref.read(channelQualityStorageProvider).read(account.storageKey);
  }

  /// Retient la qualité mesurée sur une chaîne (ne réécrit rien si elle n'a pas changé).
  Future<void> save(String channelId, ChannelQuality quality) async {
    if (state[channelId] == quality) return;
    state = {...state, channelId: quality};
    final account = ref.read(authControllerProvider);
    if (account != null) await ref.read(channelQualityStorageProvider).write(account.storageKey, state);
  }
}
