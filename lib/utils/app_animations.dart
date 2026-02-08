import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Mobbin / Wix / Figma-style animation presets for consistent entrance and micro-interactions.
/// Use with flutter_animate: `widget.animate().fadeUp().slideY(...)` etc.
class AppAnimations {
  AppAnimations._();

  /// Stagger delay per child index (Wix-style list reveal).
  static Duration stagger(int index, {int stepMs = 80}) =>
      Duration(milliseconds: index * stepMs);

  /// Default entrance: fade + slide up (Mobbin/Figma hero).
  static const Duration entranceDuration = Duration(milliseconds: 500);
  static const Duration entranceDurationFast = Duration(milliseconds: 350);
  static const Curve entranceCurve = Curves.easeOutCubic;

  /// Fade-up with slight slide (Wix scroll-reveal style).
  static const double fadeUpSlideBegin = 0.12;
  static const double fadeUpSlideEnd = 0;

  /// Scale-in for cards/modals (Figma modal enter).
  static const double scaleInBegin = 0.92;
  static const double scaleInEnd = 1.0;

  /// Blur-in for overlays (optional).
  static const double blurBegin = 4;
  static const double blurEnd = 0;
}

/// Extension to apply common entrance animations (Mobbin/Wix/Figma style).
extension AppAnimateExtension on Widget {
  /// Fade in + slide up (hero / section title).
  Widget animateEntrance({
    int delayMs = 0,
    Duration duration = AppAnimations.entranceDuration,
    double slideY = AppAnimations.fadeUpSlideBegin,
  }) {
    return animate(delay: delayMs.ms)
        .fadeIn(duration: duration, curve: AppAnimations.entranceCurve)
        .slideY(begin: slideY, end: 0, duration: duration, curve: AppAnimations.entranceCurve);
  }

  /// Staggered entrance for list items (index = 0, 1, 2...).
  Widget animateStagger(int index, {int stepMs = 80}) {
    final delay = AppAnimations.stagger(index, stepMs: stepMs);
    return animate(delay: delay)
        .fadeIn(duration: AppAnimations.entranceDuration, curve: AppAnimations.entranceCurve)
        .slideY(
          begin: AppAnimations.fadeUpSlideBegin,
          end: 0,
          duration: AppAnimations.entranceDuration,
          curve: AppAnimations.entranceCurve,
        );
  }

  /// Scale-in (Figma modal / card pop).
  Widget animateScaleIn({
    int delayMs = 0,
    Duration duration = AppAnimations.entranceDuration,
  }) {
    return animate(delay: delayMs.ms)
        .fadeIn(duration: duration, curve: AppAnimations.entranceCurve)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.0, 1.0),
          duration: duration,
          curve: AppAnimations.entranceCurve,
        );
  }

  /// Subtle blur-in (Wix-style overlay). Blur sigma animates from begin to 0.
  Widget animateBlurIn({
    int delayMs = 0,
    Duration duration = AppAnimations.entranceDuration,
  }) {
    return animate(delay: delayMs.ms)
        .fadeIn(duration: duration, curve: AppAnimations.entranceCurve)
        .blur(
          begin: const Offset(4, 4),
          end: Offset.zero,
          duration: duration,
          curve: AppAnimations.entranceCurve,
        );
  }

  /// Shimmer once (Mobbin-style highlight).
  Widget animateShimmer({
    int delayMs = 0,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    return animate(delay: delayMs.ms)
        .shimmer(
          duration: duration,
          curve: AppAnimations.entranceCurve,
          color: Colors.white.withValues(alpha: 0.15),
        );
  }
}
