import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/brand.dart';
import '../../../app/widgets/gradients.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../player/presentation/player_panel.dart';
import 'live_tv_providers.dart';
import 'widgets/channel_tile.dart';
import 'widgets/group_sidebar.dart';

/// Écran principal : catégories, grille des chaînes et lecteur.
class LiveTvScreen extends ConsumerWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(channelsProvider);
    return Scaffold(
      body: GlowBackground(
        child: switch (channels) {
          AsyncData() => const Row(
            children: [
              GroupSidebar(),
              Expanded(child: _ChannelsView()),
            ],
          ),
          AsyncError(:final error) => _LoadError(message: error.toString()),
          _ => const _Loading(),
        },
      ),
    );
  }
}

class _ChannelsView extends ConsumerWidget {
  const _ChannelsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(visibleChannelsProvider);
    final current = ref.watch(currentChannelProvider);
    final group = ref.watch(selectedGroupProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (current != null) ...[
              SizedBox(
                height: constraints.maxHeight * 0.55,
                child: PlayerPanel(channel: current, onClose: () => ref.read(currentChannelProvider.notifier).stop()),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              group,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _CountChip(count: channels.length),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Actualiser la liste',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(channelsProvider),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 320,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher une chaîne…',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
                      ),
                    ),
                    onChanged: (q) => ref.read(searchQueryProvider.notifier).set(q),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: channels.isEmpty
                  ? Center(
                      child: Text(
                        group == favoritesGroup && ref.watch(searchQueryProvider).isEmpty
                            ? 'Aucun favori pour l\'instant. Survolez une chaîne et cliquez sur l\'étoile pour l\'ajouter.'
                            : 'Aucune chaîne ne correspond.',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : GridView.builder(
                      // Marge pour que l'agrandissement au survol et le halo ne soient pas rognés.
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 24),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 170,
                        mainAxisExtent: 150,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: channels.length,
                      itemBuilder: (context, i) {
                        final channel = channels[i];
                        return ChannelTile(
                          channel: channel,
                          selected: channel == current,
                          onTap: () => ref.read(currentChannelProvider.notifier).play(channel),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(size: 96),
          SizedBox(height: 24),
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des chaînes…', style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _LoadError extends ConsumerWidget {
  const _LoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger les chaînes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                GradientButton(
                  onPressed: () => ref.invalidate(channelsProvider),
                  icon: Icons.refresh,
                  child: const Text('Réessayer'),
                ),
                OutlinedButton.icon(
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Changer de compte'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$count chaîne${count > 1 ? 's' : ''}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD5D7F5)),
      ),
    );
  }
}
