import 'package:flutter/material.dart';

import '../services/channel_controller.dart';
import '../theme.dart';

/// Barre latérale : logo de l'app, liste des groupes et bouton de playlist.
class GroupSidebar extends StatelessWidget {
  const GroupSidebar({super.key, required this.controller, required this.onOpenPlaylist});

  final ChannelController controller;
  final VoidCallback onOpenPlaylist;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: 260,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Icon(Icons.live_tv_rounded, color: accent, size: 28),
                const SizedBox(width: 10),
                const Text('Flow TV', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text('CATÉGORIES', style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: controller.groups.length,
              itemBuilder: (context, i) {
                final group = controller.groups[i];
                final selected = group == controller.selectedGroup;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    dense: true,
                    selected: selected,
                    selectedColor: Colors.white,
                    selectedTileColor: accent.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    title: Text(group, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      '${controller.countFor(group)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    onTap: () => controller.selectGroup(group),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: onOpenPlaylist,
              icon: const Icon(Icons.playlist_add),
              label: const Text('Changer de playlist'),
            ),
          ),
        ],
      ),
    );
  }
}
