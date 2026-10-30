import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../data/mpv_stats.dart';
import '../domain/stream_info.dart';
import '../domain/timeshift_window.dart';

/// Pilote une instance libmpv : lecture, volume, infos du flux et timeshift.
///
/// Le timeshift s'appuie sur le cache du démultiplexeur de mpv : le direct déjà reçu est gardé
/// (sur disque) et reste navigable. Plus il y a de cache, plus on peut remonter loin.
class PlayerSession extends ChangeNotifier {
  PlayerSession() : player = Player(configuration: const PlayerConfiguration(bufferSize: 64 * 1024 * 1024)) {
    _subscriptions = [
      player.stream.playing.listen((_) => notifyListeners()),
      player.stream.volume.listen((_) => notifyListeners()),
      player.stream.buffering.listen((_) => notifyListeners()),
      player.stream.error.listen((message) {
        error = message;
        notifyListeners();
      }),
    ];
    _configured = _configureCache();
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _refreshStats());
  }

  /// Taille maximale du cache de retour arrière (~25 min en Full HD à 5 Mb/s).
  static const timeshiftCache = '1GiB';

  final Player player;
  late final List<StreamSubscription<Object?>> _subscriptions;
  late final Future<void> _configured;
  Timer? _poll;
  bool _disposed = false;

  String? error;
  StreamInfo info = const StreamInfo();
  TimeshiftWindow? timeshift;
  Duration? _earliestPosition;

  bool get playing => player.state.playing;
  double get volume => player.state.volume;
  bool get buffering => player.state.buffering;
  bool get isLive => timeshift?.isLive ?? true;

  NativePlayer? get _native => player.platform is NativePlayer ? player.platform! as NativePlayer : null;

  Future<void> _configureCache() async {
    final native = _native;
    if (native == null) return;
    for (final (name, value) in [
      ('cache', 'yes'),
      ('cache-on-disk', 'yes'),
      ('demuxer-seekable-cache', 'yes'),
      ('force-seekable', 'yes'),
      ('demuxer-max-back-bytes', timeshiftCache),
    ]) {
      await native.setProperty(name, value);
    }
  }

  Future<void> open(String url) async {
    error = null;
    info = const StreamInfo();
    timeshift = null;
    _earliestPosition = null;
    notifyListeners();
    await _configured;
    if (_disposed) return;
    await player.open(Media(url));
  }

  Future<void> playOrPause() => player.playOrPause();

  Future<void> setVolume(double volume) => player.setVolume(volume);

  /// Recule (durée négative) ou avance dans la fenêtre de timeshift.
  Future<void> seekBy(Duration delta) async {
    final window = timeshift;
    if (window == null) return;
    await seekTo(window.position + delta);
  }

  Future<void> seekTo(Duration target) async {
    final window = timeshift;
    if (window == null) return;
    final clamped = window.clamp(target);
    timeshift = TimeshiftWindow(start: window.start, liveEdge: window.liveEdge, position: clamped);
    notifyListeners();
    await player.seek(clamped);
  }

  /// Revient au direct (fin du cache) et relance la lecture si elle était en pause.
  Future<void> goLive() async {
    final window = timeshift;
    if (window != null) await seekTo(window.liveEdge - const Duration(milliseconds: 500));
    if (!player.state.playing) await player.play();
  }

  Future<void> _refreshStats() async {
    final native = _native;
    if (native == null || _disposed) return;
    try {
      final values = <String, String>{
        for (final p in MpvStats.streamInfoProperties) p: await native.getProperty(p, waitForInitialization: false),
      };
      final timePos = await native.getProperty('time-pos', waitForInitialization: false);
      final cacheState = await native.getProperty('demuxer-cache-state', waitForInitialization: false);
      if (_disposed) return;

      info = MpvStats.parseStreamInfo(values);
      final window = MpvStats.parseTimeshift(
        cacheStateJson: cacheState,
        timePos: timePos,
        earliestSeen: _earliestPosition,
      );
      if (window != null && (_earliestPosition == null || window.position < _earliestPosition!)) {
        _earliestPosition = window.position;
      }
      timeshift = window;
      notifyListeners();
    } catch (e) {
      debugPrint('Lecture des statistiques mpv impossible : $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    player.dispose();
    super.dispose();
  }
}
