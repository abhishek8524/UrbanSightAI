import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

const String _adminMenuValue = 'admin_console';

/// Global shell for the whole web app: header nav bar + body + footer.
/// Handles both guest (sign up/sign in, about, contact, faq) and logged-in (app tabs + static pages) flows.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.loggedIn,
    this.initialRoute = AppShellRoute.signIn,
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
      _route = AppShellRoute.signIn;
    }
  }

  void _navigateTo(AppShellRoute r) {
    setState(() => _route = r);
  }

  static const String _kAdminPassword = 'admin';

  void _showAdminLoginDialog() {
    final controller = TextEditingController();
    final key = GlobalKey<FormState>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Admin Console'),
          content: Form(
            key: key,
            child: TextFormField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Admin password',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter password';
                if (v.trim() != _kAdminPassword) return 'Incorrect password';
                return null;
              },
              onFieldSubmitted: (_) => _submitAdminLogin(ctx, key, controller),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                controller.dispose();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _submitAdminLogin(ctx, key, controller),
              child: const Text('Login'),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }

  Future<void> _submitAdminLogin(
    BuildContext dialogContext,
    GlobalKey<FormState> key,
    TextEditingController controller,
  ) async {
    if (!key.currentState!.validate()) return;
    Navigator.of(dialogContext).pop();
    if (!mounted) return;
    try {
      final auth = context.read<AuthService>();
      final appState = context.read<AppState>();
      await auth.signInAnonymously();
      await auth.setRoleAdmin();
      if (!mounted) return;
      // Defer profile refresh to next frame to avoid _dependents.isEmpty assertion
      // when RootScreen switches from AppShell to AdminDashboardScreen.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await appState.refreshProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome to Admin Console')),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
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
            onAdminPressed: _showAdminLoginDialog,
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
            onAdminPressed: _showAdminLoginDialog,
          ),
        AppShellRoute.signIn => SignInScreen(
            inShell: true,
            onNavigateToSignUp: () => _navigateTo(AppShellRoute.signUp),
          ),
        AppShellRoute.about => const AboutScreen(),
        AppShellRoute.contact => const ContactScreen(),
        AppShellRoute.faq => const FaqScreen(),
        _ => SignInScreen(
            inShell: true,
            onNavigateToSignUp: () => _navigateTo(AppShellRoute.signUp),
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
    this.onAdminPressed,
  });

  final bool loggedIn;
  final AppShellRoute currentRoute;
  final void Function(AppShellRoute) onNavigate;
  final bool isWide;
  final VoidCallback? onAdminPressed;

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
                      _Logo(onTap: () => onNavigate(loggedIn ? AppShellRoute.home : AppShellRoute.signIn))
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.05, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(width: 32),
                      ...navItems.map((e) => _NavChip(
                            label: e.$2,
                            selected: currentRoute == e.$1,
                            onTap: () => onNavigate(e.$1),
                          )),
                      const Spacer(),
                      if (loggedIn)
                        _ProfileButton()
                      else
                        _AuthButtons(
                          onNavigate: onNavigate,
                          onAdminPressed: onAdminPressed,
                        ),
                    ],
                  )
                : Row(
                    children: [
                      _Logo(onTap: () => onNavigate(loggedIn ? AppShellRoute.home : AppShellRoute.signIn))
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.05, end: 0, curve: Curves.easeOutCubic),
                      const Spacer(),
                      PopupMenuButton<Object>(
                        icon: const Icon(Icons.menu_rounded),
                        onSelected: (value) {
                          if (value == _adminMenuValue) {
                            onAdminPressed?.call();
                          } else {
                            onNavigate(value as AppShellRoute);
                          }
                        },
                        itemBuilder: (ctx) => [
                          ...navItems.map((e) => PopupMenuItem<Object>(
                                value: e.$1,
                                child: Text(e.$2),
                              )),
                          if (!loggedIn) ...[
                            const PopupMenuItem<Object>(
                              value: AppShellRoute.signIn,
                              child: Text('Sign in'),
                            ),
                            if (onAdminPressed != null)
                              const PopupMenuItem<Object>(
                                value: _adminMenuValue,
                                child: ListTile(
                                  leading: Icon(Icons.admin_panel_settings_outlined, size: 20),
                                  title: Text('Admin Console'),
                                ),
                              ),
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
  const _AuthButtons({
    required this.onNavigate,
    this.onAdminPressed,
  });

  final void Function(AppShellRoute) onNavigate;
  final VoidCallback? onAdminPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onAdminPressed != null) ...[
          TextButton.icon(
            onPressed: onAdminPressed,
            icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
            label: const Text('Admin'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
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

    final email = user?.email ?? '';
    final hasEmail = email.isNotEmpty;
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: hasEmail
            ? Text(
                email.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Icon(
                Icons.menu_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
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
