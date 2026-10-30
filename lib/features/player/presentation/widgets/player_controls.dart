import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

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
    this.hideDelay = const Duration(seconds: 3),
  });

  final bool playing;

  /// Volume de 0 à 100, comme dans media_kit.
  final double volume;
  final bool fullscreen;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleFullscreen;
  final Duration hideDelay;

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  bool _visible = false;
  Timer? _hideTimer;
  double _volumeBeforeMute = 100;

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

  IconData get _volumeIcon => switch (widget.volume) {
    0 => Icons.volume_off_rounded,
    < 50 => Icons.volume_down_rounded,
    _ => Icons.volume_up_rounded,
  };

  @override
  Widget build(BuildContext context) {
    // En pause, les contrôles restent visibles.
    final visible = _visible || !widget.playing;

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
            // Voile dégradé pour garder les boutons lisibles sur n'importe quelle image.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.55, 1],
                    colors: [Colors.transparent, Color(0xCC02022E)],
                  ),
                ),
              ),
            ),
            Center(
              child: _CenterPlayButton(playing: widget.playing, onPressed: widget.onPlayPause),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: Row(
                children: [
                  _ControlButton(
                    tooltip: widget.playing ? 'Pause' : 'Lecture',
                    icon: widget.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    onPressed: widget.onPlayPause,
                  ),
                  _ControlButton(
                    tooltip: widget.volume == 0 ? 'Réactiver le son' : 'Couper le son',
                    icon: _volumeIcon,
                    onPressed: _toggleMute,
                  ),
                  SizedBox(
                    width: 130,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: AppColors.cyan,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        overlayColor: AppColors.cyan.withValues(alpha: 0.2),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      ),
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
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${widget.volume.round()}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                  const Spacer(),
                  _ControlButton(
                    tooltip: widget.fullscreen ? 'Quitter le plein écran' : 'Plein écran',
                    icon: widget.fullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                    onPressed: widget.onToggleFullscreen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.tooltip, required this.icon, required this.onPressed});

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 28, color: Colors.white),
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
