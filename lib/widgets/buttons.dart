import 'package:flutter/material.dart';

import '../assets.dart';
import '../theme.dart';

/// Tap-down scale dip shared by every button. One-shot, never looping.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value && mounted) {
      setState(() => _down = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.95 : 1.0,
        duration: Duration(milliseconds: _down ? 110 : 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Icon + label row with a baseline-locked text height.
Widget _buttonRow(String label, IconData icon, Color color, double fontSize) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      Icon(icon, size: 24, color: color),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.6,
            height: 24 / fontSize,
            color: color,
          ),
        ),
      ),
    ],
  );
}

/// Full-width hero CTA. The AI button plate is the fill, the brand gradient
/// rides on top at 0.88 so the label stays readable.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.gradient = const <Color>[PMColors.violet, PMColors.cyan],
    this.glow = PMColors.cyan,
    this.height = 60,
    this.radius = 20,
    this.fontSize = 18,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final List<Color> gradient;
  final Color glow;
  final double height;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: glow.withValues(alpha: 0.38),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(
                AppAssets.buttonCta,
                fit: BoxFit.cover,
                errorBuilder:
                    (BuildContext context, Object error, StackTrace? stack) =>
                        const ColoredBox(color: PMColors.violet),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient
                        .map((Color c) => c.withValues(alpha: 0.88))
                        .toList(),
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buttonRow(
                    label,
                    icon,
                    PMColors.textPrimary,
                    fontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Translucent action button: HINT, RESET, BACK TO MENU, GOT IT.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.borderColor = PMColors.cyan,
    this.height = 52,
    this.radius = 16,
    this.fontSize = 14,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color borderColor;
  final double height;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: PressScale(
        onTap: onTap,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: PMColors.text(0.07),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buttonRow(
                label,
                icon,
                PMColors.textPrimary,
                fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill that opens an overlay panel. Never carries a PLAY/START literal.
class ChipButton extends StatelessWidget {
  const ChipButton({
    super.key,
    required this.label,
    required this.onTap,
    this.borderColor = PMColors.cyan,
  });

  final String label;
  final VoidCallback onTap;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: PMColors.text(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            height: 16 / 11,
            color: PMColors.text(0.86),
          ),
        ),
      ),
    );
  }
}
