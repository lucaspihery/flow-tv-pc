import '../../domain/channel.dart';
import '../../domain/channel_repository.dart';
import 'xtream_api_client.dart';
import 'xtream_models.dart';

class XtreamChannelRepository implements ChannelRepository {
  XtreamChannelRepository(this._api);

  final XtreamApiClient _api;

  @override
  Future<List<Channel>> fetchChannels() async {
    final results = await Future.wait<Object>([_api.liveCategories(), _api.liveStreams()]);
    final categories = results[0] as List<XtreamCategory>;
    final streams = results[1] as List<XtreamLiveStream>;

    final names = {for (final c in categories) c.id: c.name};
    final order = {for (final (i, c) in categories.indexed) c.id: i};

    final sorted = [...streams]
      ..sort((a, b) {
        final byCategory = (order[a.categoryId] ?? order.length).compareTo(order[b.categoryId] ?? order.length);
        return byCategory != 0 ? byCategory : (a.number ?? 0).compareTo(b.number ?? 0);
      });

    return [
      for (final s in sorted)
        Channel(
          id: s.streamId,
          name: s.name,
          streamUrl: _api.liveStreamUrl(s.streamId),
          logoUrl: s.icon,
          group: names[s.categoryId] ?? Channel.defaultGroup,
        ),
    ];
  }
}
