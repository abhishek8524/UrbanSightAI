import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'report_issue_screen.dart';
import 'my_reports_screen.dart';

/// Bottom nav shell for citizens: Home, Report Issue, My Reports.
class CitizenShell extends StatefulWidget {
  const CitizenShell({super.key});

  @override
  State<CitizenShell> createState() => _CitizenShellState();
}

class _CitizenShellState extends State<CitizenShell> {
  int _currentIndex = 0;

  static const _tabs = [
    (label: 'Home', icon: Icons.home),
    (label: 'Report Issue', icon: Icons.add_circle_outline),
    (label: 'My Reports', icon: Icons.list),
  ];

  void _showProfileDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final auth = context.read<AuthService>();
    final user = appState.appUser;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trust score: ${user?.trustScore ?? 0}'),
            const SizedBox(height: 8),
            Text('Strikes: ${user?.strikes ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _tabs[_currentIndex].label;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => _showProfileDialog(context),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(inShell: true),
          ReportIssueScreen(inShell: true),
          MyReportsScreen(inShell: true),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

/// Content-only version for use inside [AppShell]: shows one of Home, Report, My Reports by index.
class CitizenShellContent extends StatelessWidget {
  const CitizenShellContent({super.key, required this.tabIndex});

  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: tabIndex.clamp(0, 2),
      children: const [
        HomeScreen(inShell: true),
        ReportIssueScreen(inShell: true),
        MyReportsScreen(inShell: true),
      ],
    );
  }
}
