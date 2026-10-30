import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/brand.dart';
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
      body: switch (channels) {
        AsyncData() => const Row(
          children: [
            GroupSidebar(),
            Expanded(child: _ChannelsView()),
          ],
        ),
        AsyncError(:final error) => _LoadError(message: error.toString()),
        _ => const _Loading(),
      },
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
      padding: const EdgeInsets.all(20),
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
                  child: Text(
                    group,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
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
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une chaîne…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (q) => ref.read(searchQueryProvider.notifier).set(q),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${channels.length} chaîne${channels.length > 1 ? 's' : ''}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
            Expanded(
              child: channels.isEmpty
                  ? const Center(
                      child: Text('Aucune chaîne ne correspond.', style: TextStyle(color: AppColors.textMuted)),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 170,
                        mainAxisExtent: 150,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
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
                FilledButton.icon(
                  onPressed: () => ref.invalidate(channelsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
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
