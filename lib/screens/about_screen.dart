import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_animations.dart';
import '../widgets/animated_3d_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 24,
        vertical: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'About UrbanSight',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: colorScheme.onSurface,
            ),
          )
              .animateEntrance(delayMs: 0),
          const SizedBox(height: 12),
          Text(
            'We help citizens and cities work together to fix local issues.',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
              .animateEntrance(delayMs: 80),
          const SizedBox(height: 48),
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _MissionCard(textTheme: textTheme, colorScheme: colorScheme)),
                    const SizedBox(width: 24),
                    Expanded(child: _StatsCard(colorScheme: colorScheme, textTheme: textTheme)),
                  ],
                )
              : Column(
                  children: [
                    _MissionCard(textTheme: textTheme, colorScheme: colorScheme),
                    const SizedBox(height: 24),
                    _StatsCard(colorScheme: colorScheme, textTheme: textTheme),
                  ],
                ),
          const SizedBox(height: 32),
          _ValuesSection(colorScheme: colorScheme, textTheme: textTheme),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.textTheme, required this.colorScheme});

  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Animated3DCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_rounded, size: 40, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Our mission',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'UrbanSight connects residents with local government by making it easy to report potholes, broken streetlights, graffiti, trash, and other issues. Every report helps city teams prioritize and fix problems faster.',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    )
        .animateStagger(1, stepMs: 100);
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.colorScheme, required this.textTheme});

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Animated3DCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(value: '10k+', label: 'Reports filed', colorScheme: colorScheme),
              _StatItem(value: '50+', label: 'Cities', colorScheme: colorScheme),
              _StatItem(value: '24/7', label: 'Available', colorScheme: colorScheme),
            ],
          ),
        ],
      ),
    )
        .animateStagger(2, stepMs: 100);
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.colorScheme,
  });

  final String value;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ValuesSection extends StatelessWidget {
  const _ValuesSection({required this.colorScheme, required this.textTheme});

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final values = [
      (Icons.public_rounded, 'Transparency', 'All reports are visible on the map so everyone can see what’s been reported and resolved.'),
      (Icons.verified_user_rounded, 'Trust', 'We use trust scores and moderation so reports are reliable and actionable.'),
      (Icons.eco_rounded, 'Impact', 'Every report helps make streets safer and neighborhoods cleaner.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What we stand for',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        )
            .animateEntrance(delayMs: 400),
        const SizedBox(height: 24),
        ...values.asMap().entries.map((e) {
          final (icon, title, body) = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Animated3DCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: colorScheme.primary, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animateStagger(4 + e.key, stepMs: 80),
          );
        }),
      ],
    );
  }
}
