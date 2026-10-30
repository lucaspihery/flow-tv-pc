import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../favorites/presentation/widgets/favorite_button.dart';
import '../../live_tv/domain/channel.dart';
import '../../../app/theme/app_theme.dart';
import '../../live_tv/presentation/widgets/channel_logo.dart';

/// Lecteur vidéo intégré (libmpv via media_kit).
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
    return Container(
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Video(controller: _video),
                StreamBuilder<bool>(
                  stream: _player.stream.buffering,
                  builder: (context, snapshot) => snapshot.data == true && _error == null
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox.shrink(),
                ),
                if (_error != null) _ErrorOverlay(message: _error!, onRetry: _open),
              ],
            ),
          ),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ChannelLogo(channel: widget.channel, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        widget.channel.group,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                FavoriteButton(channel: widget.channel),
                IconButton(tooltip: 'Recharger le flux', icon: const Icon(Icons.refresh), onPressed: _open),
                IconButton(tooltip: 'Fermer le lecteur', icon: const Icon(Icons.close), onPressed: widget.onClose),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text('Impossible de lire ce flux', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
            ],
          ),
        ),
      ),
    );
  }
}
