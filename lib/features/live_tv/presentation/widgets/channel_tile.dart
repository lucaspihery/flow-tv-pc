import 'package:flutter/material.dart';

import '../../domain/channel.dart';
import '../../../../app/theme/app_theme.dart';
import 'channel_logo.dart';

class ChannelTile extends StatefulWidget {
  const ChannelTile({super.key, required this.channel, required this.selected, required this.onTap});

  final Channel channel;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<ChannelTile> createState() => _ChannelTileState();
}

class _ChannelTileState extends State<ChannelTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.cyan;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
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
    );
  }
}
