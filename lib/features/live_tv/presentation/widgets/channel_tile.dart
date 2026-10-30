import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../domain/channel.dart';
import 'channel_logo.dart';

/// Tuile d'une chaîne : légère mise en avant au survol, bordure en dégradé quand elle est en lecture.
class ChannelTile extends ConsumerStatefulWidget {
  const ChannelTile({super.key, required this.channel, required this.selected, required this.onTap});

  final Channel channel;
  final bool selected;
  final VoidCallback onTap;

  @override
  ConsumerState<ChannelTile> createState() => _ChannelTileState();
}

class _ChannelTileState extends ConsumerState<ChannelTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final favorite = ref.watch(favoritesProvider.select((ids) => ids.contains(widget.channel.id)));
    final highlighted = _hover || widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.04 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // La « bordure » est le dégradé visible autour du contenu.
              gradient: widget.selected
                  ? AppColors.brandGradient
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: _hover ? 0.18 : 0.06),
                        Colors.white.withValues(alpha: _hover ? 0.06 : 0.02),
                      ],
                    ),
              boxShadow: [
                if (highlighted)
                  BoxShadow(
                    color: (widget.selected ? AppColors.violet : AppColors.blue).withValues(alpha: 0.35),
                    blurRadius: 22,
                    spreadRadius: -8,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.5), gradient: AppColors.tileGradient),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(child: ChannelLogo(channel: widget.channel, size: 64)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.channel.name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: highlighted ? Colors.white : const Color(0xFFD5D7F5),
                              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.selected) const Positioned(top: 10, left: 10, child: _PlayingBadge()),
                  // L'étoile n'apparaît qu'au survol, sauf si la chaîne est déjà en favori.
                  if (_hover || favorite)
                    Positioned(top: 2, right: 2, child: FavoriteButton(channel: widget.channel, size: 20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayingBadge extends StatelessWidget {
  const _PlayingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.actionGradient),
      child: const Icon(Icons.graphic_eq_rounded, size: 14, color: Colors.white),
    );
  }
}
