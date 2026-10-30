import 'package:flow_tv/features/player/data/mpv_stats.dart';
import 'package:flow_tv/features/player/domain/stream_info.dart';
import 'package:flow_tv/features/player/domain/timeshift_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StreamInfo', () {
    test('lit les propriétés mpv et produit les libellés', () {
      final info = MpvStats.parseStreamInfo({
        'video-params/w': '1920',
        'video-params/h': '1080',
        'container-fps': '50.000000',
        'estimated-vf-fps': '49.9',
        'video-format': 'h264',
        'video-bitrate': '6245000',
      });
      expect(info.qualityLabel, 'FHD 1080p');
      expect(info.fpsLabel, '50 ips');
      expect(info.bitrateLabel, '6,2 Mb/s');
      expect(info.videoCodec, 'H.264');
      expect(info.resolutionLabel, '1920×1080');
    });

    test('propriétés absentes : repli sur estimated-vf-fps, libellés nuls', () {
      final info = MpvStats.parseStreamInfo({'container-fps': '', 'estimated-vf-fps': '29.97'});
      expect(info.fpsLabel, '29,97 ips');
      expect(info.qualityLabel, isNull);
      expect(const StreamInfo().isEmpty, isTrue);
    });

    test('paliers de qualité', () {
      expect(const StreamInfo(height: 2160).qualityLabel, '4K');
      expect(const StreamInfo(height: 720).qualityLabel, 'HD 720p');
      expect(const StreamInfo(height: 576).qualityLabel, 'SD 576p');
    });
  });

  group('timeshift', () {
    test('utilise la plage navigable qui contient la lecture', () {
      final window = MpvStats.parseTimeshift(
        cacheStateJson: '{"seekable-ranges":[{"start":10.0,"end":20.0},{"start":100.5,"end":400.0}],"cache-end":400.0}',
        timePos: '250.0',
      )!;
      expect(window.start, const Duration(milliseconds: 100500));
      expect(window.liveEdge, const Duration(seconds: 400));
      expect(window.behindLive, const Duration(seconds: 150));
      expect(window.isLive, isFalse);
      expect(window.canGoBack, isTrue);
    });

    test('sans JSON exploitable : repli sur la première position vue', () {
      final window = MpvStats.parseTimeshift(
        cacheStateJson: '',
        timePos: '42',
        earliestSeen: const Duration(seconds: 5),
      )!;
      expect(window.start, const Duration(seconds: 5));
      expect(window.liveEdge, const Duration(seconds: 42));
      expect(window.isLive, isTrue);
    });

    test('pas de position : pas de fenêtre', () {
      expect(MpvStats.parseTimeshift(cacheStateJson: '{}', timePos: ''), isNull);
    });

    test('clamp garde la cible dans la fenêtre', () {
      const window = TimeshiftWindow(
        start: Duration(seconds: 10),
        liveEdge: Duration(seconds: 100),
        position: Duration(seconds: 50),
      );
      expect(window.clamp(Duration.zero), const Duration(seconds: 10));
      expect(window.clamp(const Duration(seconds: 500)), const Duration(seconds: 100));
    });
  });
}
