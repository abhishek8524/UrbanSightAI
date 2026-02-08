import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Lottie animations from Figma / Spline / LottieFiles.
///
/// To add a Lottie:
/// 1. Export JSON from Figma (LottieFiles plugin) or use .json from LottieFiles.com / Spline.
/// 2. Add the file under assets/ e.g. assets/lottie/success.json.
/// 3. Register in pubspec.yaml: flutter: assets: [ assets/lottie/ ]
/// 4. Use: LottiePlaceholder(assetPath: 'assets/lottie/success.json', size: 120)
class LottiePlaceholder extends StatelessWidget {
  const LottiePlaceholder({
    super.key,
    this.assetPath,
    this.networkUrl,
    this.size = 120,
    this.repeat = true,
  });

  /// Path to Lottie JSON asset (e.g. 'assets/lottie/hero.json').
  final String? assetPath;
  /// Optional URL for Lottie from network (e.g. LottieFiles CDN).
  final String? networkUrl;
  final double size;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: assetPath != null
          ? _buildLottieAsset()
          : networkUrl != null
              ? _buildLottieNetwork()
              : _buildPlaceholder(context),
    );
  }

  Widget _buildLottieAsset() {
    return Lottie.asset(
      assetPath!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: repeat,
    );
  }

  Widget _buildLottieNetwork() {
    return Lottie.network(
      networkUrl!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: repeat,
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.05),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: size * 0.6,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}
