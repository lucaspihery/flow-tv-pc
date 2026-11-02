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

/// Chaînes rangées par catégorie, dans l'ordre d'apparition. Calculé une seule fois par playlist,
/// pour que changer de catégorie ne reparcoure pas toute la liste.
final channelsByGroupProvider = Provider<Map<String, List<Channel>>>((ref) {
  final channels = ref.watch(channelsProvider).value ?? const [];
  final byGroup = <String, List<Channel>>{};
  for (final c in channels) {
    (byGroup[c.group] ??= []).add(c);
  }
  return byGroup;
});

/// Catégories de la playlist, dans l'ordre d'apparition.
final groupsProvider = Provider<List<String>>((ref) => ref.watch(channelsByGroupProvider).keys.toList());

/// Chaînes favorites présentes dans la playlist, dans l'ordre d'ajout.
final favoriteChannelsProvider = Provider<List<Channel>>((ref) {
  final channels = ref.watch(channelsProvider).value ?? const [];
  final byId = {for (final c in channels) c.id: c};
  return [for (final id in ref.watch(favoritesProvider)) ?byId[id]];
});

final groupCountsProvider = Provider<Map<String, int>>((ref) {
  final byGroup = ref.watch(channelsByGroupProvider);
  return {
    allChannelsGroup: ref.watch(channelsProvider).value?.length ?? 0,
    favoritesGroup: ref.watch(favoriteChannelsProvider).length,
    for (final MapEntry(:key, :value) in byGroup.entries) key: value.length,
  };
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

/// Noms en minuscules, calculés une fois par chaîne : la recherche ne refait pas `toLowerCase()`
/// sur des milliers de noms à chaque touche tapée.
final _searchKeys = Expando<String>('searchKey');

String _searchKey(Channel c) => _searchKeys[c] ??= c.name.toLowerCase();

/// Chaînes de la sélection courante (tout, favoris ou une catégorie), filtrées par la recherche.
final visibleChannelsProvider = Provider<List<Channel>>((ref) {
  final group = ref.watch(selectedGroupProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final source = switch (group) {
    allChannelsGroup => ref.watch(channelsProvider).value ?? const <Channel>[],
    favoritesGroup => ref.watch(favoriteChannelsProvider),
    _ => ref.watch(channelsByGroupProvider)[group] ?? const <Channel>[],
  };
  if (query.isEmpty) return source;
  return [
    for (final c in source)
      if (_searchKey(c).contains(query)) c,
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
