import 'package:flutter/foundation.dart';

import '../models/channel.dart';
import 'playlist_service.dart';

/// État de l'application : playlist chargée, filtres et chaîne en cours.
class ChannelController extends ChangeNotifier {
  ChannelController(this._service);

  static const allGroups = 'Toutes les chaînes';

  final PlaylistService _service;

  List<Channel> _channels = const [];
  List<String> _groups = const [];
  String _selectedGroup = allGroups;
  String _query = '';
  Channel? _current;
  bool _loading = false;
  String? _error;
  PlaylistSource? _source;

  List<Channel> get channels => _channels;
  List<String> get groups => _groups;
  String get selectedGroup => _selectedGroup;
  String get query => _query;
  Channel? get current => _current;
  bool get loading => _loading;
  String? get error => _error;
  PlaylistSource? get source => _source;
  bool get hasPlaylist => _channels.isNotEmpty;

  /// Chaînes filtrées par groupe et par recherche.
  List<Channel> get visibleChannels {
    final q = _query.trim().toLowerCase();
    return _channels.where((c) {
      if (_selectedGroup != allGroups && c.group != _selectedGroup) return false;
      if (q.isNotEmpty && !c.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  int countFor(String group) => group == allGroups ? _channels.length : _channels.where((c) => c.group == group).length;

  Future<void> restoreLastPlaylist() async {
    final source = await _service.lastSource();
    if (source != null) await load(source);
  }

  Future<bool> load(PlaylistSource source) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final channels = await _service.load(source);
      _channels = channels;
      _groups = [
        allGroups,
        ...{for (final c in channels) c.group},
      ];
      _selectedGroup = allGroups;
      _query = '';
      _source = source;
      await _service.saveLastSource(source);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectGroup(String group) {
    _selectedGroup = group;
    notifyListeners();
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  void play(Channel channel) {
    _current = channel;
    notifyListeners();
  }

  void stop() {
    _current = null;
    notifyListeners();
  }
}
