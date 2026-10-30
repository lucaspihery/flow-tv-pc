import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/http_service.dart';
import '../../auth/domain/iptv_account.dart';
import '../../auth/presentation/auth_controller.dart';
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

const allChannelsGroup = 'Toutes les chaînes';

/// Catégories dans l'ordre d'apparition, précédées de « Toutes les chaînes ».
final groupsProvider = Provider<List<String>>((ref) {
  final channels = ref.watch(channelsProvider).value ?? const [];
  return [
    allChannelsGroup,
    ...{for (final c in channels) c.group},
  ];
});

final groupCountsProvider = Provider<Map<String, int>>((ref) {
  final channels = ref.watch(channelsProvider).value ?? const [];
  final counts = <String, int>{allChannelsGroup: channels.length};
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

/// Chaînes filtrées par catégorie et par recherche.
final visibleChannelsProvider = Provider<List<Channel>>((ref) {
  final channels = ref.watch(channelsProvider).value ?? const [];
  final group = ref.watch(selectedGroupProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  return [
    for (final c in channels)
      if ((group == allChannelsGroup || c.group == group) && (query.isEmpty || c.name.toLowerCase().contains(query))) c,
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
