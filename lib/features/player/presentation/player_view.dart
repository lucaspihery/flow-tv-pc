import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/gradients.dart';
import '../../favorites/presentation/widgets/favorite_button.dart';
import '../../live_tv/domain/channel.dart';
import '../../live_tv/presentation/widgets/channel_logo.dart';

/// Habillage du lecteur : image vidéo, chargement, erreur et barre d'informations.
class PlayerView extends StatelessWidget {
  const PlayerView({
    super.key,
    required this.channel,
    required this.video,
    required this.onRetry,
    required this.onClose,
    this.buffering = false,
    this.error,
  });

  final Channel channel;
  final Widget video;
  final bool buffering;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                video,
                if (buffering && error == null) const Center(child: CircularProgressIndicator()),
                if (error != null) _ErrorOverlay(message: error!, onRetry: onRetry),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(gradient: AppColors.panelGradient),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ChannelLogo(channel: channel, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        channel.group,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const _LiveBadge(),
                const SizedBox(width: 8),
                FavoriteButton(channel: channel),
                IconButton(tooltip: 'Recharger le flux', icon: const Icon(Icons.refresh), onPressed: onRetry),
                IconButton(tooltip: 'Fermer le lecteur', icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text('Impossible de lire ce flux', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              GradientButton(onPressed: onRetry, icon: Icons.refresh, child: const Text('Réessayer')),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.magenta, AppColors.violet]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: Colors.white),
          SizedBox(width: 6),
          Text('EN DIRECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}
