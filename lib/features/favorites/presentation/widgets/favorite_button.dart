import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../live_tv/domain/channel.dart';
import '../favorites_controller.dart';

/// Étoile qui ajoute ou retire la chaîne des favoris.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.channel, this.size = 22});

  final Channel channel;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite = ref.watch(favoritesProvider.select((ids) => ids.contains(channel.id)));
    return IconButton(
      tooltip: favorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
      iconSize: size,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        favorite ? Icons.star_rounded : Icons.star_outline_rounded,
        color: favorite ? AppColors.favorite : AppColors.textMuted,
      ),
      onPressed: () => ref.read(favoritesProvider.notifier).toggle(channel),
    );
  }
}
