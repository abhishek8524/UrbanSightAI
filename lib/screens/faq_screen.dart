import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_animations.dart';
import '../widgets/animated_3d_card.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int? _expandedIndex;

  static const _faqs = [
    (
      q: 'How do I report an issue?',
      a: 'Sign up or continue as a guest, then tap “Report Issue” in the nav. Add a photo, choose a category (e.g. Pothole, Streetlight), add a short description, and place the pin on the map. Submit and you’re done.',
    ),
    (
      q: 'Who can see my reports?',
      a: 'Reports appear on the public map so other residents and city staff can see what’s been reported. Your email is not shown publicly. Only admins can see account details for moderation.',
    ),
    (
      q: 'What is a trust score?',
      a: 'Your trust score reflects report quality and community standing. New users start at 50. Accurate, helpful reports can increase it; false or abusive content can lower it. Higher scores help cities prioritize.',
    ),
    (
      q: 'How long until an issue is fixed?',
      a: 'It depends on the city and the type of issue. We send reports to the right department (e.g. Public Works, Sanitation). You can track status (Reported → In progress → Resolved) on the report details page.',
    ),
    (
      q: 'Can I report anonymously?',
      a: 'Yes. Use “Continue as guest” to report without creating an account. You won’t get status updates unless you sign in later with the same device. For the best experience we recommend signing up.',
    ),
    (
      q: 'How do I delete or edit a report?',
      a: 'Open “My Reports” and tap the report. From the details screen you can see status and updates. Editing or deleting is not available after submission to keep the record clear for the city; contact support if something was submitted by mistake.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 24,
        vertical: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Frequently asked questions',
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
            'Quick answers to common questions about UrbanSight.',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
              .animateEntrance(delayMs: 80),
          const SizedBox(height: 32),
          ...List.generate(_faqs.length, (i) {
            final faq = _faqs[i];
            final isExpanded = _expandedIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Animated3DCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => setState(() {
                    _expandedIndex = isExpanded ? null : i;
                  }),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                faq.q,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.expand_more_rounded,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              faq.a,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ),
                          crossFadeState:
                              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animateStagger(i + 2, stepMs: 60),
            );
          }),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
