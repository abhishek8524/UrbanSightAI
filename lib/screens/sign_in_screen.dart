import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../utils/app_animations.dart';
import '../widgets/tap_scale_button.dart';
import 'sign_up_screen.dart';

/// Password required to access Admin Console from the sign-in screen.
const String _kAdminPassword = 'admin';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.inShell = false, this.onNavigateToSignUp});

  static const String routeName = '/sign-in';

  final bool inShell;
  final VoidCallback? onNavigateToSignUp;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthService>().signInAnonymously();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _humanizeError(e.toString());
          _loading = false;
        });
      }
    }
  }

  void _showAdminLoginDialog() {
    if (_loading) return;
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
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final auth = context.read<AuthService>();
      final appState = context.read<AppState>();
      await auth.signInAnonymously();
      await auth.setRoleAdmin();
      if (!mounted) return;
      setState(() => _loading = false);
      // Defer profile refresh to next frame to avoid _dependents.isEmpty assertion.
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
        setState(() {
          _errorMessage = _humanizeError(e.toString());
          _loading = false;
        });
      }
    }
  }

  Future<void> _signInWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthService>().signInWithEmailPassword(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _humanizeError(e.toString());
          _loading = false;
        });
      }
    }
  }

  String _humanizeError(String message) {
    if (message.contains('user-not-found') || message.contains('wrong-password')) {
      return 'Invalid email or password. Please try again.';
    }
    if (message.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      if (!widget.inShell)
                        IconButton(
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.surfaceContainerHighest,
                          ),
                          alignment: Alignment.centerLeft,
                        ),
                      if (!widget.inShell) const SizedBox(height: 16),
                      _HeroSection(colorScheme: colorScheme, textTheme: textTheme)
                          .animateEntrance(delayMs: 0),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _FormCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (_errorMessage != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: colorScheme.errorContainer,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline_rounded,
                                                size: 20,
                                                color: colorScheme.onErrorContainer,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage!,
                                                  style: textTheme.bodySmall?.copyWith(
                                                    color: colorScheme.onErrorContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                      Text(
                                        'Welcome back',
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autocorrect: false,
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                          hintText: 'you@example.com',
                                          prefixIcon: Icon(
                                            Icons.mail_outline_rounded,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        validator: (v) =>
                                            (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) => _signInWithEmailPassword(),
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: Icon(
                                            Icons.lock_outline_rounded,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                            onPressed: () => setState(
                                                () => _obscurePassword = !_obscurePassword),
                                          ),
                                        ),
                                        validator: (v) =>
                                            (v == null || v.isEmpty) ? 'Enter your password' : null,
                                      ),
                                      const SizedBox(height: 28),
                                      TapScaleButton(
                                        onPressed: _loading ? null : _signInWithEmailPassword,
                                        child: FilledButton(
                                          onPressed: null,
                                          child: _loading
                                              ? SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: colorScheme.onPrimary,
                                                  ),
                                                )
                                              : const Text('Sign in'),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Don't have an account? ",
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _loading
                                                ? null
                                                : () {
                                                    if (widget.inShell && widget.onNavigateToSignUp != null) {
                                                      widget.onNavigateToSignUp!();
                                                    } else {
                                                      Navigator.of(context).pushReplacement(
                                                        MaterialPageRoute<void>(
                                                          builder: (_) => const SignUpScreen(),
                                                        ),
                                                      );
                                                    }
                                                  },
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: const Text('Sign up'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      OutlinedButton.icon(
                                        onPressed: _loading ? null : _signInAnonymously,
                                        icon: const Icon(Icons.person_outline_rounded, size: 20),
                                        label: const Text('Continue as guest'),
                                      ),
                                      const SizedBox(height: 16),
                                      OutlinedButton.icon(
                                        onPressed: _loading
                                            ? null
                                            : _showAdminLoginDialog,
                                        icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                                        label: const Text('Admin Console'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                    .animateScaleIn(delayMs: 120),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.colorScheme,
    required this.textTheme,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Sign in',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Report issues and track your submissions',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
