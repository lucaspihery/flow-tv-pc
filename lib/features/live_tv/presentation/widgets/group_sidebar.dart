import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/iptv_account.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../live_tv_providers.dart';

/// Barre latérale : logo, catégories et compte connecté.
class GroupSidebar extends ConsumerWidget {
  const GroupSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final groups = ref.watch(groupsProvider);
    final counts = ref.watch(groupCountsProvider);
    final selected = ref.watch(selectedGroupProvider);

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
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final group = groups[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    dense: true,
                    selected: group == selected,
                    selectedColor: Colors.white,
                    selectedTileColor: accent.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    title: Text(group, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      '${counts[group] ?? 0}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    onTap: () => ref.read(selectedGroupProvider.notifier).select(group),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          const _AccountTile(),
        ],
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authControllerProvider);
    if (account == null) return const SizedBox.shrink();
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
      leading: Icon(account is XtreamAccount ? Icons.dns : Icons.playlist_play, color: AppColors.textMuted),
      title: Text(account.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        account is XtreamAccount ? 'Xtream Codes' : 'Playlist M3U',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: IconButton(
        tooltip: 'Se déconnecter',
        icon: const Icon(Icons.logout),
        onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
      ),
    );
  }
}
