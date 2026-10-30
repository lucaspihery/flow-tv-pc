import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/brand.dart';
import 'widgets/m3u_login_form.dart';
import 'widgets/xtream_login_form.dart';

enum _LoginMethod { xtream, m3u }

/// Écran de connexion : Xtream Codes ou playlist M3U.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _LoginMethod _method = _LoginMethod.xtream;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BrandBanner(),
                const SizedBox(height: 20),
                const Text(
                  'Connectez-vous à votre fournisseur IPTV',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<_LoginMethod>(
                        segments: const [
                          ButtonSegment(value: _LoginMethod.xtream, icon: Icon(Icons.dns), label: Text('Xtream Codes')),
                          ButtonSegment(
                            value: _LoginMethod.m3u,
                            icon: Icon(Icons.playlist_play),
                            label: Text('Playlist M3U'),
                          ),
                        ],
                        selected: {_method},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) => setState(() => _method = s.first),
                      ),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: switch (_method) {
                          _LoginMethod.xtream => const XtreamLoginForm(key: ValueKey('xtream')),
                          _LoginMethod.m3u => const M3uLoginForm(key: ValueKey('m3u')),
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
