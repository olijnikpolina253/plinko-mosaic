import 'package:flutter/material.dart';

import '../theme.dart';

/// Layer 1 of every screen: the AI background image, a readability gradient and
/// two static aurora blobs. The blobs never animate — a perpetual ticker keeps
/// the window non-idle and starves the capture agent.
class AuroraBackdrop extends StatelessWidget {
  const AuroraBackdrop({
    super.key,
    required this.image,
    required this.overlay,
    required this.child,
    this.topBlob = PMColors.violet,
    this.bottomBlob = PMColors.cyan,
    this.topBlobSize = 260,
    this.bottomBlobSize = 200,
  });

  /// Background decoration built from an `AppAssets` constant.
  final DecorationImage image;

  /// Top-to-bottom readability wash painted over the image.
  final List<Color> overlay;

  final Widget child;
  final Color topBlob;
  final Color bottomBlob;
  final double topBlobSize;
  final double bottomBlobSize;

  Widget _blob(double size, Color color, double alpha) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                color.withValues(alpha: alpha),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: PMColors.bgBase, image: image),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: overlay,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(left: 0, top: 48, child: _blob(topBlobSize, topBlob, 0.38)),
          Positioned(
            right: 0,
            bottom: 90,
            child: _blob(bottomBlobSize, bottomBlob, 0.30),
          ),
          child,
        ],
      ),
    );
  }
}
