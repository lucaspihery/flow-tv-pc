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

  /// Libellé court de la qualité : « 4K », « FHD 1080p », « HD 720p », « SD 576p »…
  String? get qualityLabel {
    final h = height;
    if (h == null || h <= 0) return null;
    return switch (h) {
      >= 2000 => '4K',
      >= 1400 => 'QHD ${h}p',
      >= 1000 => 'FHD ${h}p',
      >= 700 => 'HD ${h}p',
      _ => 'SD ${h}p',
    };
  }

  /// « 50 ips », « 29,97 ips »…
  String? get fpsLabel {
    final f = fps;
    if (f == null || f <= 0) return null;
    final rounded = f.roundToDouble();
    final text = (f - rounded).abs() < 0.01 ? rounded.toInt().toString() : f.toStringAsFixed(2).replaceAll('.', ',');
    return '$text ips';
  }

  /// « 6,2 Mb/s » ou « 850 kb/s ».
  String? get bitrateLabel {
    final b = bitrate;
    if (b == null || b <= 0) return null;
    if (b >= 1e6) return '${(b / 1e6).toStringAsFixed(1).replaceAll('.', ',')} Mb/s';
    return '${(b / 1e3).round()} kb/s';
  }

  String? get resolutionLabel => (width != null && height != null) ? '$width×$height' : null;
}
