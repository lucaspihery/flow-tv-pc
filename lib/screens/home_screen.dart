import 'package:flutter/material.dart';

import '../services/channel_controller.dart';
import '../theme.dart';
import '../widgets/channel_tile.dart';
import '../widgets/group_sidebar.dart';
import '../widgets/player_panel.dart';
import '../widgets/playlist_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final ChannelController controller;

  Future<void> _openPlaylist(BuildContext context) async {
    final source = await showPlaylistDialog(context);
    if (source == null) return;
    final ok = await controller.load(source);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec du chargement : ${controller.error}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (!controller.hasPlaylist) {
            return _Welcome(loading: controller.loading, onOpen: () => _openPlaylist(context));
          }
          return Row(
            children: [
              GroupSidebar(controller: controller, onOpenPlaylist: () => _openPlaylist(context)),
              Expanded(child: _Content(controller: controller)),
            ],
          );
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.controller});

  final ChannelController controller;

  @override
  Widget build(BuildContext context) {
    final channels = controller.visibleChannels;
    final current = controller.current;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (current != null) ...[
              SizedBox(
                height: constraints.maxHeight * 0.55,
                child: PlayerPanel(channel: current, onClose: controller.stop),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.selectedGroup,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (controller.loading)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une chaîne…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: controller.search,
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
                          selected: identical(channel, current),
                          onTap: () => controller.play(channel),
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

class _Welcome extends StatelessWidget {
  const _Welcome({required this.loading, required this.onOpen});

  final bool loading;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.live_tv_rounded, size: 72, color: accent),
          const SizedBox(height: 16),
          const Text('Bienvenue sur Flow TV', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Chargez une playlist M3U pour commencer à regarder vos chaînes.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 28),
          if (loading)
            const CircularProgressIndicator()
          else
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.playlist_add),
              label: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text('Charger une playlist'),
              ),
            ),
        ],
      ),
    );
  }
}
