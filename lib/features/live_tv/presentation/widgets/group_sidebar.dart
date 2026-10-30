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

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.panelGradient,
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      // Material transparent pour les ListTile et boutons de la barre (fond peint par le DecoratedBox).
      child: Material(
        type: MaterialType.transparency,
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
      ),
    );
  }
}

class _GroupTile extends ConsumerStatefulWidget {
  const _GroupTile(this.group, {this.icon, this.iconColor});

  final String group;
  final IconData? icon;
  final Color? iconColor;

  @override
  ConsumerState<_GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends ConsumerState<_GroupTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedGroupProvider) == widget.group;
    final count = ref.watch(groupCountsProvider.select((counts) => counts[widget.group] ?? 0));
    final foreground = selected ? Colors.white : (_hover ? Colors.white : const Color(0xFFD5D7F5));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () => ref.read(selectedGroupProvider.notifier).select(widget.group),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: selected ? AppColors.actionGradient : null,
              color: selected ? null : (_hover ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: -6,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: selected ? Colors.white : widget.iconColor ?? foreground),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    widget.group,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: selected ? 0.2 : 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(color: selected ? Colors.white : AppColors.textMuted, fontSize: 11.5),
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
