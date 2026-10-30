import 'channel.dart';

/// Source de chaînes. Une implémentation par type de compte.
abstract interface class ChannelRepository {
  /// Chaînes triées dans l'ordre d'affichage, catégories comprises.
  Future<List<Channel>> fetchChannels();
}
