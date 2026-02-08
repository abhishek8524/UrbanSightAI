import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/report_details_screen.dart';
import 'screens/report_issue_screen.dart';
import 'screens/root_screen.dart';
import 'screens/my_reports_screen.dart';
import 'services/app_state.dart';
import 'services/auth_service.dart';
import 'services/moderation_service.dart';
import 'services/report_service.dart';
import 'utils/firebase_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  runApp(const UrbanSightApp());
}

/// Shown when Firebase initialization fails.
class FirebaseErrorApp extends StatelessWidget {
  const FirebaseErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UrbanSight',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Firebase failed to initialize',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Material 3 theme with Google Fonts (Plus Jakarta Sans) and urban-inspired seed color.
ThemeData _buildTheme(Brightness brightness) {
  const seedColor = Color(0xFF0D7377); // Teal — civic, trustworthy
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
    primary: const Color(0xFF0D7377),
    surface: brightness == Brightness.light
        ? const Color(0xFFF7F9FC)
        : const Color(0xFF121212),
  );
  final textTheme = GoogleFonts.plusJakartaSansTextTheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class UrbanSightApp extends StatelessWidget {
  const UrbanSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<AppState>(
          create: (context) => AppState(authService: context.read<AuthService>()),
        ),
        Provider<ReportService>(create: (_) => ReportService()),
        Provider<ModerationService>(create: (_) => ModerationService()),
      ],
      child: MaterialApp(
        title: 'UrbanSight',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const RootScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == ReportDetailsScreen.routeName) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => ReportDetailsScreen(
                reportId: settings.arguments as String?,
              ),
            );
          }
          if (settings.name == AdminDashboardScreen.routeName) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (ctx) => _AdminRouteGuard(),
            );
          }
          return null;
        },
        routes: {
          HomeScreen.routeName: (_) => const HomeScreen(),
          ReportIssueScreen.routeName: (_) => const ReportIssueScreen(),
          MyReportsScreen.routeName: (_) => const MyReportsScreen(),
        },
      ),
    );
  }
}

/// Protects admin route: non-admin is popped and sees a message.
class _AdminRouteGuard extends StatefulWidget {
  @override
  State<_AdminRouteGuard> createState() => _AdminRouteGuardState();
}

class _AdminRouteGuardState extends State<_AdminRouteGuard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isAdmin = context.read<AppState>().isAdmin;
      if (!isAdmin) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access denied')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AppState>().isAdmin) {
      return const AdminDashboardScreen();
    }
    return const Scaffold(
      body: Center(child: Text('Checking access…')),
    );
  }
}
