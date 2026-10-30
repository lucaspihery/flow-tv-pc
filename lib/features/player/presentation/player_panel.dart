import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../live_tv/domain/channel.dart';
import 'player_view.dart';
import 'widgets/player_controls.dart';

/// Construit le lecteur d'une chaîne. Surchargeable dans les tests, où libmpv n'est pas disponible.
typedef PlayerPanelBuilder = Widget Function(Channel channel, VoidCallback onClose);

final playerPanelBuilderProvider = Provider<PlayerPanelBuilder>(
  (ref) =>
      (channel, onClose) => PlayerPanel(channel: channel, onClose: onClose),
);

/// Lecteur vidéo intégré (libmpv via media_kit) : gère le flux, l'affichage est délégué à [PlayerView].
class PlayerPanel extends StatefulWidget {
  const PlayerPanel({super.key, required this.channel, required this.onClose});

  final Channel channel;
  final VoidCallback onClose;

  @override
  State<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends State<PlayerPanel> {
  late final Player _player = Player();
  late final VideoController _video = VideoController(_player);
  StreamSubscription<String>? _errors;
  String? _error;

  @override
  void initState() {
    super.initState();
    _errors = _player.stream.error.listen((message) {
      if (mounted) setState(() => _error = message);
    });
    _open();
  }

  @override
  void didUpdateWidget(PlayerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channel.streamUrl != widget.channel.streamUrl) _open();
  }

  void _open() {
    setState(() => _error = null);
    _player.open(Media(widget.channel.streamUrl));
  }

  @override
  void dispose() {
    _errors?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _player.stream.buffering,
      builder: (context, snapshot) => PlayerView(
        channel: widget.channel,
        video: Video(
          controller: _video,
          controls: (state) => _MediaKitControls(state: state),
        ),
        buffering: snapshot.data ?? false,
        error: _error,
        onRetry: _open,
        onClose: widget.onClose,
      ),
    );
  }
}

/// Relie [PlayerControls] au lecteur media_kit (lecture, volume, plein écran).
class _MediaKitControls extends StatelessWidget {
  const _MediaKitControls({required this.state});

  final VideoState state;

  @override
  Widget build(BuildContext context) {
    final player = state.widget.controller.player;
    return StreamBuilder<bool>(
      stream: player.stream.playing,
      initialData: player.state.playing,
      builder: (context, playing) => StreamBuilder<double>(
        stream: player.stream.volume,
        initialData: player.state.volume,
        builder: (context, volume) => PlayerControls(
          playing: playing.data ?? false,
          volume: volume.data ?? 100,
          fullscreen: state.isFullscreen(),
          onPlayPause: player.playOrPause,
          onVolumeChanged: player.setVolume,
          onToggleFullscreen: state.toggleFullscreen,
        ),
      ),
    );
  }
}
