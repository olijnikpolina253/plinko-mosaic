import 'package:flutter/material.dart';

import '../assets.dart';
import '../theme.dart';

/// Shared press feedback: 1.0 -> 0.96 over 110ms, released on up/cancel.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child});

  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// 60px gradient CTA carrying the generated button art plus a glow shadow.
/// Icon 24 and text lineHeight 24 keep the row on one optical baseline.
class PrimaryCta extends StatelessWidget {
  const PrimaryCta({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.height = 60,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: AssetImage(AppAssets.buttonCta),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              AppColors.cyan.withValues(alpha: 0.92),
              AppColors.violet.withValues(alpha: 0.95),
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.38),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 24, color: AppColors.bgDeep),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 24 / 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                        color: AppColors.bgDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 48px glass button. Same icon size and lineHeight as the primary CTA.
class SecondaryCta extends StatelessWidget {
  const SecondaryCta({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent = AppColors.cyan,
    this.height = 48,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.42)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 24, color: accent),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 24 / 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
