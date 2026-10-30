import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/http_service.dart';
import '../../auth/domain/iptv_account.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../favorites/presentation/favorites_controller.dart';
import '../data/m3u/m3u_channel_repository.dart';
import '../data/xtream/xtream_api_client.dart';
import '../data/xtream/xtream_channel_repository.dart';
import '../domain/channel.dart';
import '../domain/channel_repository.dart';

/// Choisit l'implémentation selon le type de compte connecté.
final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  final http = ref.watch(httpServiceProvider);
  return switch (ref.watch(authControllerProvider)) {
    final XtreamAccount account => XtreamChannelRepository(XtreamApiClient(http, account)),
    final M3uAccount account => M3uChannelRepository(http, account),
    null => throw StateError('Aucun compte connecté.'),
  };
});

final channelsProvider = FutureProvider<List<Channel>>((ref) => ref.watch(channelRepositoryProvider).fetchChannels());

/// Sélections spéciales de la barre latérale, en plus des catégories de la playlist.
const allChannelsGroup = 'Toutes les chaînes';
const favoritesGroup = 'Favoris';

/// Catégories de la playlist, dans l'ordre d'apparition.
final groupsProvider = Provider<List<String>>((ref) {
  final channels = ref.watch(channelsProvider).value ?? const [];
  return [
    ...{for (final c in channels) c.group},
  ];
});

/// Chaînes favorites présentes dans la playlist, dans l'ordre d'ajout.
final favoriteChannelsProvider = Provider<List<Channel>>((ref) {
  final channels = ref.watch(channelsProvider).value ?? const [];
  final byId = {for (final c in channels) c.id: c};
  return [for (final id in ref.watch(favoritesProvider)) ?byId[id]];
});

final groupCountsProvider = Provider<Map<String, int>>((ref) {
  final channels = ref.watch(channelsProvider).value ?? const [];
  final counts = <String, int>{
    allChannelsGroup: channels.length,
    favoritesGroup: ref.watch(favoriteChannelsProvider).length,
  };
  for (final c in channels) {
    counts[c.group] = (counts[c.group] ?? 0) + 1;
  }
  return counts;
});

final selectedGroupProvider = NotifierProvider<SelectedGroup, String>(SelectedGroup.new);

class SelectedGroup extends Notifier<String> {
  @override
  String build() {
    ref.watch(authControllerProvider);
    return allChannelsGroup;
  }

  void select(String group) => state = group;
}

final searchQueryProvider = NotifierProvider<SearchQuery, String>(SearchQuery.new);

class SearchQuery extends Notifier<String> {
  @override
  String build() {
    ref.watch(authControllerProvider);
    return '';
  }

  void set(String query) => state = query;
}

/// Chaînes de la sélection courante (tout, favoris ou une catégorie), filtrées par la recherche.
final visibleChannelsProvider = Provider<List<Channel>>((ref) {
  final group = ref.watch(selectedGroupProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final source = switch (group) {
    favoritesGroup => ref.watch(favoriteChannelsProvider),
    _ => ref.watch(channelsProvider).value ?? const <Channel>[],
  };
  return [
    for (final c in source)
      if ((group == allChannelsGroup || group == favoritesGroup || c.group == group) &&
          (query.isEmpty || c.name.toLowerCase().contains(query)))
        c,
  ];
});

final currentChannelProvider = NotifierProvider<CurrentChannel, Channel?>(CurrentChannel.new);

class CurrentChannel extends Notifier<Channel?> {
  @override
  Channel? build() {
    ref.watch(authControllerProvider);
    return null;
  }

  void play(Channel channel) => state = channel;

  void stop() => state = null;
}
