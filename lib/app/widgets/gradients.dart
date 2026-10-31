import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fond bleu nuit éclairé par deux halos aux couleurs du logo.
class GlowBackground extends StatelessWidget {
  const GlowBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Halos plein écran mis en cache dans leur propre calque : ils ne sont pas repeints
          // à chaque animation (survol, chargement, lecteur) du contenu par-dessus.
          const RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Glow(alignment: Alignment(-1.1, -1.2), color: AppColors.blue, opacity: 0.28),
                _Glow(alignment: Alignment(1.2, 1.2), color: AppColors.magenta, opacity: 0.16),
                _Glow(alignment: Alignment(1.0, -1.1), color: AppColors.violet, opacity: 0.14),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.alignment, required this.color, required this.opacity});

  final Alignment alignment;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: alignment,
            radius: 1.1,
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton principal rempli avec le dégradé de la marque.
class GradientButton extends StatefulWidget {
  const GradientButton({super.key, required this.onPressed, required this.child, this.icon, this.loading = false});

  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final bool loading;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: AppColors.actionGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: AppColors.violet.withValues(alpha: _hover ? 0.55 : 0.3),
                blurRadius: _hover ? 24 : 14,
                spreadRadius: -6,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                child: IconTheme.merge(
                  data: const IconThemeData(color: Colors.white, size: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.loading)
                        const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else ...[
                        if (widget.icon != null) ...[Icon(widget.icon), const SizedBox(width: 10)],
                        widget.child,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Boîte avec une fine bordure en dégradé (effet « verre »).
class GradientBorderBox extends StatelessWidget {
  const GradientBorderBox({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.borderWidth = 1.2,
    this.gradient = AppColors.brandGradient,
    this.background = AppColors.panelGradient,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Gradient gradient;
  final Gradient background;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(borderRadius)),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: background,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Texte rempli avec un dégradé.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, required this.style, this.gradient = AppColors.brandGradient});

  final String text;
  final TextStyle style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (bounds) => gradient.createShader(Offset.zero & bounds.size),
    child: Text(text, style: style),
  );
}
