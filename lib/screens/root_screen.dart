import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layout/app_shell.dart';
import '../services/app_state.dart';
import 'admin_dashboard_screen.dart';

/// Decides initial destination: AppShell (sign-up / app / static pages) or AdminDashboard.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final appState = context.watch<AppState>();

    if (appState.isAdmin) {
      return const AdminDashboardScreen();
    }
    return AppShell(
      loggedIn: user != null,
      initialRoute: user == null ? AppShellRoute.signUp : AppShellRoute.home,
    );
  }
}
