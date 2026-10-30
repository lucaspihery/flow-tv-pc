import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/stream_info.dart';
import '../../domain/timeshift_window.dart';

/// Contrôles du lecteur aux couleurs de Flow TV, affichés au survol de la vidéo.
///
/// Indépendants de media_kit : l'état et les actions sont passés en paramètres,
/// ce qui permet de les tester et de les prévisualiser sans libmpv.
class PlayerControls extends StatefulWidget {
  const PlayerControls({
    super.key,
    required this.playing,
    required this.volume,
    required this.fullscreen,
    required this.onPlayPause,
    required this.onVolumeChanged,
    required this.onToggleFullscreen,
    this.info = const StreamInfo(),
    this.timeshift,
    this.onSeekTo,
    this.onGoLive,
    this.hideDelay = const Duration(seconds: 3),
  });

  final bool playing;

  /// Volume de 0 à 100, comme dans media_kit.
  final double volume;
  final bool fullscreen;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleFullscreen;

  /// Qualité du flux, affichée en haut à droite.
  final StreamInfo info;

  /// Fenêtre de retour arrière ; `null` tant que le flux n'a pas démarré.
  final TimeshiftWindow? timeshift;
  final ValueChanged<Duration>? onSeekTo;
  final VoidCallback? onGoLive;
  final Duration hideDelay;

  /// Pas des boutons « reculer » / « avancer ».
  static const seekStep = Duration(seconds: 10);

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  bool _visible = false;
  Timer? _hideTimer;
  double _volumeBeforeMute = 100;

  /// Position en cours de glissement sur la barre de timeshift.
  double? _dragSeconds;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  /// Affiche les contrôles puis les masque après [PlayerControls.hideDelay] sans mouvement.
  void _show() {
    _hideTimer?.cancel();
    if (!_visible) setState(() => _visible = true);
    _hideTimer = Timer(widget.hideDelay, _hide);
  }

  void _hide() {
    _hideTimer?.cancel();
    if (mounted && _visible) setState(() => _visible = false);
  }

  void _toggleMute() {
    if (widget.volume > 0) {
      _volumeBeforeMute = widget.volume;
      widget.onVolumeChanged(0);
    } else {
      widget.onVolumeChanged(_volumeBeforeMute > 0 ? _volumeBeforeMute : 100);
    }
  }

  void _seekBy(Duration delta) {
    final window = widget.timeshift;
    if (window == null) return;
    _show();
    widget.onSeekTo?.call(window.clamp(window.position + delta));
  }

  IconData get _volumeIcon => switch (widget.volume) {
    0 => Icons.volume_off_rounded,
    < 50 => Icons.volume_down_rounded,
    _ => Icons.volume_up_rounded,
  };

  @override
  Widget build(BuildContext context) {
    // En pause, les contrôles restent visibles.
    final visible = _visible || !widget.playing;
    final window = widget.timeshift;

    return MouseRegion(
      onHover: (_) => _show(),
      onExit: (_) => _hide(),
      cursor: visible ? SystemMouseCursors.basic : SystemMouseCursors.none,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Clic sur l'image : lecture/pause ; double-clic : plein écran.
            // Placé sous les boutons (et non autour) pour ne pas retarder leurs clics.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPlayPause,
              onDoubleTap: widget.onToggleFullscreen,
            ),
            // Voiles dégradés pour garder les boutons lisibles sur n'importe quelle image.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.2, 0.5, 1],
                    colors: [Color(0x9902022E), Colors.transparent, Colors.transparent, Color(0xDD02022E)],
                  ),
                ),
              ),
            ),
            if (!widget.info.isEmpty) Positioned(top: 12, right: 12, child: StreamInfoChips(info: widget.info)),
            Center(
              child: _CenterPlayButton(playing: widget.playing, onPressed: widget.onPlayPause),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (window != null && window.length > const Duration(seconds: 2)) _timeline(window),
                  Row(
                    children: [
                      _ControlButton(
                        tooltip: 'Reculer de 10 s',
                        icon: Icons.replay_10_rounded,
                        onPressed: window != null && window.canGoBack ? () => _seekBy(-PlayerControls.seekStep) : null,
                      ),
                      _ControlButton(
                        tooltip: widget.playing ? 'Pause' : 'Lecture',
                        icon: widget.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        onPressed: widget.onPlayPause,
                      ),
                      _ControlButton(
                        tooltip: 'Avancer de 10 s',
                        icon: Icons.forward_10_rounded,
                        onPressed: window != null && !window.isLive ? () => _seekBy(PlayerControls.seekStep) : null,
                      ),
                      const SizedBox(width: 4),
                      _ControlButton(
                        tooltip: widget.volume == 0 ? 'Réactiver le son' : 'Couper le son',
                        icon: _volumeIcon,
                        onPressed: _toggleMute,
                      ),
                      SizedBox(
                        width: 110,
                        child: SliderTheme(
                          data: _sliderTheme(context),
                          child: Slider(
                            value: widget.volume.clamp(0, 100),
                            max: 100,
                            onChanged: (v) {
                              _show();
                              widget.onVolumeChanged(v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      LiveButton(
                        live: window?.isLive ?? true,
                        behind: window?.behindLive ?? Duration.zero,
                        onGoLive: widget.onGoLive,
                      ),
                      const Spacer(),
                      _ControlButton(
                        tooltip: widget.fullscreen ? 'Quitter le plein écran' : 'Plein écran',
                        icon: widget.fullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                        onPressed: widget.onToggleFullscreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barre de timeshift : de l'instant le plus ancien en cache (gauche) jusqu'au direct (droite).
  Widget _timeline(TimeshiftWindow window) {
    final min = window.start.inMilliseconds / 1000;
    final max = window.liveEdge.inMilliseconds / 1000;
    final value = (_dragSeconds ?? window.position.inMilliseconds / 1000).clamp(min, max);
    final behind = Duration(milliseconds: ((max - value) * 1000).round());

    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            '-${formatDuration(window.length)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: _sliderTheme(context).copyWith(activeTrackColor: AppColors.magenta),
            child: Slider(
              min: min,
              max: max,
              value: value,
              onChangeStart: (_) => _hideTimer?.cancel(),
              onChanged: (v) => setState(() => _dragSeconds = v),
              onChangeEnd: (v) {
                setState(() => _dragSeconds = null);
                _show();
                widget.onSeekTo?.call(Duration(milliseconds: (v * 1000).round()));
              },
            ),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            behind <= TimeshiftWindow.liveTolerance ? 'DIRECT' : '-${formatDuration(behind)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ],
    );
  }

  SliderThemeData _sliderTheme(BuildContext context) => SliderTheme.of(context).copyWith(
    trackHeight: 4,
    activeTrackColor: AppColors.cyan,
    inactiveTrackColor: Colors.white24,
    thumbColor: Colors.white,
    overlayColor: AppColors.cyan.withValues(alpha: 0.2),
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
  );
}

/// « 1:05:09 » ou « 04:32 ».
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// Pastille « EN DIRECT » ; en différé, devient le bouton « Revenir au direct ».
class LiveButton extends StatelessWidget {
  const LiveButton({super.key, required this.live, required this.behind, this.onGoLive, this.compact = false});

  final bool live;
  final Duration behind;
  final VoidCallback? onGoLive;

  /// Version sans action, pour la barre d'informations.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = live ? 'EN DIRECT' : (compact ? 'DIFFÉRÉ -${formatDuration(behind)}' : 'REVENIR AU DIRECT');
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: live ? const LinearGradient(colors: [AppColors.magenta, AppColors.violet]) : null,
        color: live ? null : Colors.white.withValues(alpha: 0.1),
        border: live ? null : Border.all(color: Colors.white38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            live ? Icons.circle : (compact ? Icons.history_rounded : Icons.skip_next_rounded),
            size: live ? 8 : 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.white),
          ),
        ],
      ),
    );
    if (live || compact || onGoLive == null) return pill;
    return Tooltip(
      message: 'Revenir au direct',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onGoLive, child: pill),
      ),
    );
  }
}

/// Puces « FHD 1080p », « 50 ips », « 6,2 Mb/s », « H.264 ».
class StreamInfoChips extends StatelessWidget {
  const StreamInfoChips({super.key, required this.info, this.detailed = true});

  final StreamInfo info;

  /// `false` : uniquement la qualité et les ips.
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final quality = info.qualityLabel;
    final labels = [
      ?info.fpsLabel,
      if (detailed) ...[?info.bitrateLabel, ?info.videoCodec],
    ];
    return Wrap(
      spacing: 6,
      children: [if (quality != null) _Chip(quality, highlighted: true), for (final l in labels) _Chip(l)],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: highlighted ? AppColors.actionGradient : null,
        color: highlighted ? null : Colors.black.withValues(alpha: 0.45),
        border: highlighted ? null : Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.tooltip, required this.icon, required this.onPressed});

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 28),
      color: Colors.white,
      disabledColor: Colors.white30,
      hoverColor: Colors.white.withValues(alpha: 0.12),
      onPressed: onPressed,
    );
  }
}

class _CenterPlayButton extends StatelessWidget {
  const _CenterPlayButton({required this.playing, required this.onPressed});

  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.actionGradient,
          boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: -4)],
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 44, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
