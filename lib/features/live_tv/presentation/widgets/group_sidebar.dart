import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/widgets/brand.dart';
import '../../../auth/domain/iptv_account.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../live_tv_providers.dart';

/// Barre latérale : logo, toutes les chaînes, favoris, catégories et compte connecté.
class GroupSidebar extends ConsumerWidget {
  const GroupSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);

    // Material (et non Container) pour que les ListTile puissent peindre leur fond de sélection.
    return Material(
      color: AppColors.surface,
      child: SizedBox(
        width: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  BrandMark(size: 36),
                  SizedBox(width: 12),
                  Text(
                    'Flow TV',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  const _GroupTile(allChannelsGroup, icon: Icons.apps_rounded),
                  const _GroupTile(favoritesGroup, icon: Icons.star_rounded, iconColor: AppColors.favorite),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 16, 10, 8),
                    child: Text(
                      'CATÉGORIES',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2),
                    ),
                  ),
                  for (final group in groups) _GroupTile(group),
                ],
              ),
            ),
            const Divider(height: 1),
            const _AccountTile(),
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends ConsumerWidget {
  const _GroupTile(this.group, {this.icon, this.iconColor});

  final String group;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedGroupProvider) == group;
    final count = ref.watch(groupCountsProvider.select((counts) => counts[group] ?? 0));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        selected: selected,
        selectedColor: Colors.white,
        selectedTileColor: AppColors.accent.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: icon == null ? null : Icon(icon, size: 20, color: iconColor),
        minLeadingWidth: 20,
        title: Text(group, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text('$count', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        onTap: () => ref.read(selectedGroupProvider.notifier).select(group),
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
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
      ),
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
