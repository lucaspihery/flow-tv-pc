import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/live_tv/presentation/live_tv_screen.dart';
import 'theme/app_theme.dart';

class FlowTvApp extends ConsumerWidget {
  const FlowTvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authControllerProvider);
    return MaterialApp(
      title: 'Flow TV',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Pas de compte enregistré → écran de connexion ; sinon → TV en direct.
      home: account == null ? const LoginScreen() : const LiveTvScreen(),
    );
  }
}
