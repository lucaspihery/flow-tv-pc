import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../channel_quality/presentation/channel_qualities_controller.dart';
import '../../live_tv/domain/channel.dart';
import '../domain/stream_info.dart';
import 'player_session.dart';
import 'player_view.dart';
import 'widgets/player_controls.dart';

/// Construit le lecteur d'une chaîne. Surchargeable dans les tests, où libmpv n'est pas disponible.
typedef PlayerPanelBuilder = Widget Function(Channel channel, VoidCallback onClose);

final playerPanelBuilderProvider = Provider<PlayerPanelBuilder>(
  (ref) =>
      (channel, onClose) => PlayerPanel(channel: channel, onClose: onClose),
);

/// Lecteur vidéo intégré (libmpv via media_kit) : gère le flux, l'affichage est délégué à [PlayerView].
class PlayerPanel extends ConsumerStatefulWidget {
  const PlayerPanel({super.key, required this.channel, required this.onClose});

  final Channel channel;
  final VoidCallback onClose;

  @override
  ConsumerState<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends ConsumerState<PlayerPanel> {
  /// Une chaîne réellement regardée (pas seulement zappée) mémorise sa qualité, comme sur Android.
  static const qualityAfter = Duration(seconds: 10);

  final _session = PlayerSession();
  late final VideoController _video = VideoController(_session.player);

  /// Créé une seule fois : les mises à jour de la session (chaque seconde) ne reconstruisent pas la vidéo.
  late final Widget _videoWidget = Video(
    controller: _video,
    controls: (state) => _MediaKitControls(state: state, session: _session),
  );
  Timer? _qualityTimer;
  bool _watched = false;

  @override
  void initState() {
    super.initState();
    _session.addListener(_saveQuality);
    _open();
  }

  @override
  void didUpdateWidget(PlayerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channel.streamUrl != widget.channel.streamUrl) _open();
  }

  void _open() {
    _qualityTimer?.cancel();
    _watched = false;
    _qualityTimer = Timer(qualityAfter, () {
      _watched = true;
      _saveQuality();
    });
    _session.open(widget.channel.streamUrl);
  }

  /// Mémorise la qualité affichée sur la tuile, puis la tient à jour si le flux s'adapte.
  void _saveQuality() {
    if (!_watched || !mounted) return;
    final quality = channelQualityOf(_session.info);
    if (quality != null) ref.read(channelQualitiesProvider.notifier).save(widget.channel.id, quality);
  }

  @override
  void dispose() {
    _qualityTimer?.cancel();
    _session.removeListener(_saveQuality);
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) => PlayerView(
        channel: widget.channel,
        video: _videoWidget,
        buffering: _session.buffering,
        error: _session.error,
        info: _session.info,
        timeshift: _session.timeshift,
        onGoLive: _session.goLive,
        onRetry: () => _session.open(widget.channel.streamUrl),
        onClose: widget.onClose,
      ),
    );
  }
}

/// Relie [PlayerControls] à la session (y compris en plein écran, où media_kit reconstruit les contrôles).
class _MediaKitControls extends StatelessWidget {
  const _MediaKitControls({required this.state, required this.session});

  final VideoState state;
  final PlayerSession session;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => PlayerControls(
        playing: session.playing,
        volume: session.volume,
        fullscreen: state.isFullscreen(),
        info: session.info,
        timeshift: session.timeshift,
        onPlayPause: session.playOrPause,
        onVolumeChanged: session.setVolume,
        onSeekTo: session.seekTo,
        onGoLive: session.goLive,
        onToggleFullscreen: state.toggleFullscreen,
      ),
    );
  }
}
