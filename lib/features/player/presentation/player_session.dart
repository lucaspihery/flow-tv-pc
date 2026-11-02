import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../data/mpv_background.dart';
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
  MpvBackground? _background;
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
    await _pendingStats;
    final background = _background;
    if (_deinterlacing && background != null && !_disposed) {
      // La chaîne suivante est peut-être progressive : on réévaluera avec ses propres images.
      _deinterlacing = false;
      final reset = background.run(const [], set: const {'deinterlace': 'no'});
      _pendingStats = reset;
      await reset;
      _pendingStats = null;
    }
    if (_disposed) return;
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

  /// Indique si mpv marque l'image affichée comme entrelacée.
  static const _interlacedProperty = 'video-frame-info/interlaced';

  static const _statsProperties = [
    ...MpvStats.streamInfoProperties,
    'time-pos',
    'demuxer-cache-state',
    _interlacedProperty,
  ];

  /// Accès à mpv en cours dans un isolate : le lecteur n'est libéré qu'après sa fin.
  Future<void>? _pendingStats;

  /// Le désentrelacement est-il demandé pour la chaîne en cours ?
  bool _deinterlacing = false;

  Future<void> _refreshStats() async {
    final native = _native;
    if (native == null || _disposed || _pendingStats != null) return;
    final pending = _readStats(native);
    _pendingStats = pending;
    await pending;
    _pendingStats = null;
  }

  Future<void> _readStats(NativePlayer native) async {
    try {
      // Hors du thread de l'interface : la lecture peut attendre que mpv soit disponible.
      final background = _background ??= MpvBackground(native);
      final values = await background.run(_statsProperties);
      if (_disposed || values.isEmpty) return;
      // Beaucoup de chaînes TV sont diffusées en entrelacé (1080i) : sans désentrelacement,
      // l'image est hachée (effet de peigne, mouvements saccadés). On ne l'active que pour ces
      // flux, et une seule fois par chaîne : l'image désentrelacée n'est plus marquée comme telle.
      if (values[_interlacedProperty] == 'yes' && !_deinterlacing) {
        _deinterlacing = true;
        await background.run(const [], set: const {'deinterlace': 'yes'});
      }

      final newInfo = MpvStats.parseStreamInfo(values);
      final window = MpvStats.parseTimeshift(
        cacheStateJson: values['demuxer-cache-state']!,
        timePos: values['time-pos']!,
        earliestSeen: _earliestPosition,
      );
      if (window != null && (_earliestPosition == null || window.position < _earliestPosition!)) {
        _earliestPosition = window.position;
      }
      // Ne reconstruit le lecteur que si quelque chose a réellement changé (rien en pause, par exemple).
      if (_disposed || (newInfo == info && window == timeshift)) return;
      info = newInfo;
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
    // Une lecture en cours dans un isolate utilise encore le contexte mpv : on attend sa fin.
    final pending = _pendingStats;
    if (pending == null) {
      player.dispose();
    } else {
      pending.whenComplete(player.dispose);
    }
    super.dispose();
  }
}
