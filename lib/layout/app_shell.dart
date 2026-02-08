import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../screens/about_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/citizen_shell.dart';
import '../screens/faq_screen.dart';
import '../screens/sign_in_screen.dart';
import '../screens/sign_up_screen.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';

/// Global shell for the whole web app: header nav bar + body + footer.
/// Handles both guest (sign up/sign in, about, contact, faq) and logged-in (app tabs + static pages) flows.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.loggedIn,
    this.initialRoute = AppShellRoute.signUp,
  });

  final bool loggedIn;
  final AppShellRoute initialRoute;

  @override
  State<AppShell> createState() => _AppShellState();
}

enum AppShellRoute {
  signUp,
  signIn,
  home,
  reportIssue,
  myReports,
  about,
  contact,
  faq,
}

class _AppShellState extends State<AppShell> {
  late AppShellRoute _route;

  @override
  void initState() {
    super.initState();
    _route = widget.initialRoute;
  }

  @override
  void didUpdateWidget(covariant AppShell widget) {
    super.didUpdateWidget(widget);
    if (!widget.loggedIn && _route == AppShellRoute.home) {
      _route = AppShellRoute.signUp;
    }
  }

  void _navigateTo(AppShellRoute r) {
    setState(() => _route = r);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      body: Column(
        children: [
          _AppHeader(
            loggedIn: widget.loggedIn,
            currentRoute: _route,
            onNavigate: _navigateTo,
            isWide: isWide,
          ),
          Expanded(
            child: _buildBody(),
          ),
          const _AppFooter(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!widget.loggedIn) {
      return switch (_route) {
        AppShellRoute.signUp => SignUpScreen(
            inShell: true,
            onNavigateToSignIn: () => _navigateTo(AppShellRoute.signIn),
          ),
        AppShellRoute.signIn => SignInScreen(
            inShell: true,
            onNavigateToSignUp: () => _navigateTo(AppShellRoute.signUp),
          ),
        AppShellRoute.about => const AboutScreen(),
        AppShellRoute.contact => const ContactScreen(),
        AppShellRoute.faq => const FaqScreen(),
        _ => SignUpScreen(
            inShell: true,
            onNavigateToSignIn: () => _navigateTo(AppShellRoute.signIn),
          ),
      };
    }
    return switch (_route) {
      AppShellRoute.home => const CitizenShellContent(tabIndex: 0),
      AppShellRoute.reportIssue => const CitizenShellContent(tabIndex: 1),
      AppShellRoute.myReports => const CitizenShellContent(tabIndex: 2),
      AppShellRoute.about => const AboutScreen(),
      AppShellRoute.contact => const ContactScreen(),
      AppShellRoute.faq => const FaqScreen(),
      _ => const CitizenShellContent(tabIndex: 0),
    };
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({
    required this.loggedIn,
    required this.currentRoute,
    required this.onNavigate,
    required this.isWide,
  });

  final bool loggedIn;
  final AppShellRoute currentRoute;
  final void Function(AppShellRoute) onNavigate;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final navItems = loggedIn
        ? <(AppShellRoute, String)>[
            (AppShellRoute.home, 'Home'),
            (AppShellRoute.reportIssue, 'Report Issue'),
            (AppShellRoute.myReports, 'My Reports'),
            (AppShellRoute.about, 'About'),
            (AppShellRoute.contact, 'Contact'),
            (AppShellRoute.faq, 'FAQ'),
          ]
        : <(AppShellRoute, String)>[
            (AppShellRoute.about, 'About'),
            (AppShellRoute.contact, 'Contact'),
            (AppShellRoute.faq, 'FAQ'),
          ];

    return Material(
      elevation: 0,
      color: colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 12,
            ),
            child: isWide
                ? Row(
                    children: [
                      _Logo(onTap: () => onNavigate(loggedIn ? AppShellRoute.home : AppShellRoute.signUp)),
                      const SizedBox(width: 32),
                      ...navItems.map((e) => _NavChip(
                            label: e.$2,
                            selected: currentRoute == e.$1,
                            onTap: () => onNavigate(e.$1),
                          )),
                      const Spacer(),
                      if (loggedIn) _ProfileButton() else _AuthButtons(onNavigate: onNavigate),
                    ],
                  )
                : Row(
                    children: [
                      _Logo(onTap: () => onNavigate(loggedIn ? AppShellRoute.home : AppShellRoute.signUp)),
                      const Spacer(),
                      PopupMenuButton<AppShellRoute>(
                        icon: const Icon(Icons.menu_rounded),
                        onSelected: onNavigate,
                        itemBuilder: (ctx) => [
                          ...navItems.map((e) => PopupMenuItem(
                                value: e.$1,
                                child: Text(e.$2),
                              )),
                          if (!loggedIn) ...[
                            const PopupMenuItem(value: AppShellRoute.signIn, child: Text('Sign in')),
                          ],
                        ],
                      ),
                      if (loggedIn) _ProfileButton(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              'UrbanSight',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          backgroundColor: selected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
        ),
        child: Text(label),
      ),
    );
  }
}

class _AuthButtons extends StatelessWidget {
  const _AuthButtons({required this.onNavigate});

  final void Function(AppShellRoute) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => onNavigate(AppShellRoute.signIn),
          child: const Text('Sign in'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => onNavigate(AppShellRoute.signUp),
          child: const Text('Sign up'),
        ),
      ],
    );
  }
}

class _ProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final appState = context.read<AppState>();
    final user = appState.appUser;

    return PopupMenuButton<String>(
      icon: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          (user?.email?.isNotEmpty == true)
              ? (user!.email!.substring(0, 1).toUpperCase())
              : '?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          enabled: false,
          child: Text('Trust: ${user?.trustScore ?? 0}'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'signout',
          child: ListTile(
            leading: Icon(Icons.logout_rounded),
            title: Text('Sign out'),
          ),
        ),
      ],
      onSelected: (v) {
        if (v == 'signout') {
          auth.signOut();
        }
      },
    );
  }
}

class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 24, vertical: 40),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: isWide
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.eco_rounded, size: 20, color: colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                'UrbanSight',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Report issues. Improve your city.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _FooterColumn(
                      title: 'Product',
                      links: ['Report Issue', 'My Reports', 'Map'],
                    ),
                    const _FooterColumn(
                      title: 'Company',
                      links: ['About', 'Contact', 'FAQ'],
                    ),
                    const _FooterColumn(
                      title: 'Legal',
                      links: ['Privacy', 'Terms'],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    '© ${DateTime.now().year} UrbanSight. All rights reserved.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco_rounded, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'UrbanSight',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Report issues. Improve your city.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  '© ${DateTime.now().year} UrbanSight. All rights reserved.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.links});

  final String title;
  final List<String> links;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...links.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
