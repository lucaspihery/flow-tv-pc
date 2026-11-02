import '../../channel_quality/domain/channel_quality.dart';
import 'video_resolution.dart';

/// Caractéristiques techniques du flux en cours de lecture.
class StreamInfo {
  const StreamInfo({this.width, this.height, this.fps, this.videoCodec, this.bitrate});

  final int? width;
  final int? height;

  /// Images par seconde.
  final double? fps;

  /// Codec vidéo, ex. « H.264 ».
  final String? videoCodec;

  /// Débit vidéo en bits par seconde.
  final double? bitrate;

  bool get isEmpty => height == null && fps == null && videoCodec == null && bitrate == null;

  VideoResolution? get resolution => VideoResolution.of(width ?? 0, height ?? 0);

  FrameRate? get frameRate => FrameRate.of(fps);

  /// « SD », « 720p », « 1080p », « 1440p » ou « 4K ».
  String? get qualityLabel => resolution?.label;

  /// « 50 fps » (arrondi).
  String? get fpsLabel => frameRate?.label;

  /// « 6,2 Mb/s » ou « 850 kb/s ».
  String? get bitrateLabel {
    final b = bitrate;
    if (b == null || b <= 0) return null;
    if (b >= 1e6) return '${(b / 1e6).toStringAsFixed(1).replaceAll('.', ',')} Mb/s';
    return '${(b / 1e3).round()} kb/s';
  }

  String? get resolutionLabel => (width != null && height != null) ? '$width×$height' : null;

  @override
  bool operator ==(Object other) =>
      other is StreamInfo &&
      other.width == width &&
      other.height == height &&
      other.fps == fps &&
      other.videoCodec == videoCodec &&
      other.bitrate == bitrate;

  @override
  int get hashCode => Object.hash(width, height, fps, videoCodec, bitrate);
}

/// Qualité à mémoriser pour la chaîne : `null` tant que la résolution est inconnue.
ChannelQuality? channelQualityOf(StreamInfo info) {
  final resolution = info.resolution;
  if (resolution == null) return null;
  return ChannelQuality(resolution: resolution.label, frameRate: info.frameRate?.fps);
}
