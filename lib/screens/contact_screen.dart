import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_animations.dart';
import '../widgets/animated_3d_card.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final message = _messageController.text.trim();
    final subject = Uri.encodeComponent('Contact from UrbanSight');
    final body = Uri.encodeComponent('Name: $name\nEmail: $email\n\nMessage:\n$message');
    final mailto = Uri.parse(
      'mailto:abhishekchauhan8524@gmail.com?subject=$subject&body=$body',
    );
    if (await canLaunchUrl(mailto)) {
      await launchUrl(mailto, mode: LaunchMode.externalApplication);
    }
    if (mounted) {
      setState(() {
        _sending = false;
        _sent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 56 : 24,
        vertical: 48,
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact us',
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
                        'Have a question or feedback? We’d love to hear from you.',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                          .animateEntrance(delayMs: 80),
                      const SizedBox(height: 40),
                      _ContactInfoCard(colorScheme: colorScheme, textTheme: textTheme),
                      const SizedBox(height: 40),
                      _TeamSection(colorScheme: colorScheme, textTheme: textTheme),
                    ],
                  ),
                ),
                const SizedBox(width: 56),
                Expanded(
                  flex: 1,
                  child: _ContactForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    emailController: _emailController,
                    messageController: _messageController,
                    sending: _sending,
                    sent: _sent,
                    onSubmit: _submit,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Contact us',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: colorScheme.onSurface,
                  ),
                )
                    .animateEntrance(delayMs: 0),
                const SizedBox(height: 12),
                Text(
                  'Have a question or feedback? We’d love to hear from you.',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
                    .animateEntrance(delayMs: 80),
                const SizedBox(height: 32),
                _ContactInfoCard(colorScheme: colorScheme, textTheme: textTheme),
                const SizedBox(height: 28),
                _TeamSection(colorScheme: colorScheme, textTheme: textTheme),
                const SizedBox(height: 28),
                _ContactForm(
                  formKey: _formKey,
                  nameController: _nameController,
                  emailController: _emailController,
                  messageController: _messageController,
                  sending: _sending,
                  sent: _sent,
                  onSubmit: _submit,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ],
            ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({required this.colorScheme, required this.textTheme});

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Animated3DCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ContactRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: 'abhishekchauhan8524@gmail.com',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 20),
          _ContactRow(
            icon: Icons.language_rounded,
            label: 'Support',
            value: 'support.urbansight.app',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 20),
          _ContactRow(
            icon: Icons.schedule_rounded,
            label: 'Response time',
            value: 'Usually within 24 hours',
            colorScheme: colorScheme,
          ),
        ],
      ),
    )
        .animateScaleIn(delayMs: 150);
  }
}

/// Team of 4 developers; icons for now, pictures later. Abhishek links to LinkedIn.
class _TeamSection extends StatelessWidget {
  const _TeamSection({required this.colorScheme, required this.textTheme});

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  static const String _abhishekLinkedIn = 'https://www.linkedin.com/in/abhishek8524/';

  Future<void> _openLinkedIn() async {
    final uri = Uri.parse(_abhishekLinkedIn);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = [
      (name: 'Abhishek', role: 'Team Lead', icon: Icons.person_rounded, linkedIn: true),
      (name: 'Jodie', role: 'Member', icon: Icons.person_rounded, linkedIn: false),
      (name: 'Wareesha', role: 'Member', icon: Icons.person_rounded, linkedIn: false),
      (name: 'Arshia', role: 'Member', icon: Icons.person_rounded, linkedIn: false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meet the team',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        )
            .animateEntrance(delayMs: 200),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            const gap = 16.0;
            return isWide
                ? Row(
                    children: [
                      for (var i = 0; i < members.length; i++) ...[
                        if (i > 0) const SizedBox(width: gap),
                        Expanded(
                          child: _TeamCard(
                            name: members[i].name,
                            role: members[i].role,
                            icon: members[i].icon,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            linkedIn: members[i].linkedIn,
                            onLinkedInTap: _openLinkedIn,
                          ),
                        ),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      for (final m in members)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _TeamCard(
                            name: m.name,
                            role: m.role,
                            icon: m.icon,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            linkedIn: m.linkedIn,
                            onLinkedInTap: _openLinkedIn,
                          ),
                        ),
                    ],
                  );
          },
        )
            .animateStagger(2, stepMs: 80),
      ],
    );
  }
}

class _TeamCard extends StatefulWidget {
  const _TeamCard({
    required this.name,
    required this.role,
    required this.icon,
    required this.colorScheme,
    required this.textTheme,
    required this.linkedIn,
    required this.onLinkedInTap,
  });

  final String name;
  final String role;
  final IconData icon;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool linkedIn;
  final VoidCallback onLinkedInTap;

  @override
  State<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<_TeamCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.linkedIn ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.linkedIn ? widget.onLinkedInTap : null,
        child: AnimatedScale(
          scale: _hovered ? 1.04 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Animated3DCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: widget.colorScheme.primaryContainer,
                  child: Icon(widget.icon, size: 36, color: widget.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.name,
                  style: widget.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.role,
                  style: widget.textTheme.bodySmall?.copyWith(
                    color: widget.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.linkedIn) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_rounded, size: 14, color: widget.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'LinkedIn',
                        style: widget.textTheme.labelSmall?.copyWith(
                          color: widget.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContactForm extends StatelessWidget {
  const _ContactForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.messageController,
    required this.sending,
    required this.sent,
    required this.onSubmit,
    required this.colorScheme,
    required this.textTheme,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController messageController;
  final bool sending;
  final bool sent;
  final VoidCallback onSubmit;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    if (sent) {
      return Animated3DCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded, size: 56, color: colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              'Message sent',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'We’ll get back to you soon.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      )
          .animateScaleIn(delayMs: 0);
    }
    return Animated3DCard(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a message' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: sending ? null : onSubmit,
              child: sending
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Text('Send message'),
            ),
          ],
        ),
      ),
    )
        .animateEntrance(delayMs: 300);
  }
}
