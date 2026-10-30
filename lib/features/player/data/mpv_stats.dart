import 'dart:convert';

import '../domain/stream_info.dart';
import '../domain/timeshift_window.dart';

/// Conversion des propriétés libmpv (lues en texte) en modèles de l'application.
///
/// Propriétés utilisées : https://mpv.io/manual/master/#properties
class MpvStats {
  const MpvStats._();

  static const streamInfoProperties = [
    'video-params/w',
    'video-params/h',
    'container-fps',
    'estimated-vf-fps',
    'video-format',
    'video-bitrate',
  ];

  /// [values] associe chaque propriété de [streamInfoProperties] à sa valeur texte (vide si indisponible).
  static StreamInfo parseStreamInfo(Map<String, String> values) {
    double? number(String key) => double.tryParse(values[key]?.trim() ?? '');
    final fps = number('container-fps') ?? number('estimated-vf-fps');
    return StreamInfo(
      width: number('video-params/w')?.round(),
      height: number('video-params/h')?.round(),
      fps: fps,
      videoCodec: codecName(values['video-format']),
      bitrate: number('video-bitrate'),
    );
  }

  /// `h264` → `H.264`, `hevc` → `H.265`…
  static String? codecName(String? format) {
    final f = format?.trim().toLowerCase();
    if (f == null || f.isEmpty) return null;
    return switch (f) {
      'h264' => 'H.264',
      'hevc' || 'h265' => 'H.265',
      'mpeg2video' => 'MPEG-2',
      'av1' => 'AV1',
      'vp9' => 'VP9',
      _ => f.toUpperCase(),
    };
  }

  /// Calcule la fenêtre de timeshift depuis `demuxer-cache-state` (JSON) et `time-pos`.
  ///
  /// [earliestSeen] sert de repli si mpv ne fournit pas de plage navigable.
  static TimeshiftWindow? parseTimeshift({
    required String cacheStateJson,
    required String timePos,
    Duration? earliestSeen,
  }) {
    final position = _seconds(double.tryParse(timePos.trim()));
    if (position == null) return null;

    Duration? start;
    Duration? end;
    try {
      final state = jsonDecode(cacheStateJson);
      if (state is Map) {
        final ranges = state['seekable-ranges'];
        if (ranges is List) {
          for (final r in ranges.whereType<Map>()) {
            final s = _seconds(_toDouble(r['start']));
            final e = _seconds(_toDouble(r['end']));
            if (s == null || e == null) continue;
            // La plage qui contient la lecture est celle du timeshift.
            if (s <= position + const Duration(seconds: 1) && e >= position - const Duration(seconds: 1)) {
              start = s;
              end = e;
            }
          }
        }
        end ??= _seconds(_toDouble(state['cache-end']));
      }
    } on FormatException {
      // Pas de JSON exploitable : on garde les replis ci-dessous.
    }

    end ??= position;
    start ??= earliestSeen ?? position;
    if (end < position) end = position;
    if (start > position) start = position;
    return TimeshiftWindow(start: start, liveEdge: end, position: position);
  }

  static double? _toDouble(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');

  static Duration? _seconds(double? s) => s == null ? null : Duration(milliseconds: (s * 1000).round());
}
