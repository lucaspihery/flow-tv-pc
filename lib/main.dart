import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'screens/home_screen.dart';
import 'services/channel_controller.dart';
import 'services/playlist_service.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const FlowTvApp());
}

class FlowTvApp extends StatefulWidget {
  const FlowTvApp({super.key});

  @override
  State<FlowTvApp> createState() => _FlowTvAppState();
}

class _FlowTvAppState extends State<FlowTvApp> {
  final _controller = ChannelController(PlaylistService());

  @override
  void initState() {
    super.initState();
    _controller.restoreLastPlaylist();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow TV',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeScreen(controller: _controller),
    );
  }
}
