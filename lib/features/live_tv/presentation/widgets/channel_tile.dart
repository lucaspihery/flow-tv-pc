import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/channel.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import 'channel_logo.dart';

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
    const accent = AppColors.cyan;
    final favorite = ref.watch(favoritesProvider.select((ids) => ids.contains(widget.channel.id)));
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hover ? AppColors.surfaceHigh : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: widget.selected ? accent : Colors.transparent, width: 2),
                ),
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
                      style: TextStyle(fontSize: 13, fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            // L'étoile n'apparaît qu'au survol, sauf si la chaîne est déjà en favori.
            if (_hover || favorite)
              Positioned(top: 2, right: 2, child: FavoriteButton(channel: widget.channel, size: 20)),
          ],
        ),
      ),
    );
  }
}
