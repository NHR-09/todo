import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'providers/task_provider.dart';
import 'providers/lecture_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/leetcode_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/lectures_screen.dart';
import 'screens/hero_mode_screen.dart';
import 'screens/leetcode_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Dark icons on light bg
    systemNavigationBarColor: NHRColors.milk,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const NHRApp());
}

class NHRApp extends StatelessWidget {
  const NHRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => LectureProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => LeetCodeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'NHR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

// Keep old name for backward compat
typedef MarvelTodoApp = NHRApp;

/// Decides whether to show Login or the main App.
/// If user has previously skipped login or is signed in, go directly to AppShell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return FutureBuilder<bool>(
      future: _hasSkippedLogin(),
      builder: (context, snapshot) {
        final skipped = snapshot.data ?? false;

        // If signed in or previously skipped login, go to main app
        if (auth.isSignedIn || skipped) {
          return AppShell(key: AppShell.shellKey);
        }

        // Show login screen
        return LoginScreen(
          onSkip: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('login_skipped', true);
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => AppShell(key: AppShell.shellKey)),
              );
            }
          },
        );
      },
    );
  }

  Future<bool> _hasSkippedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('login_skipped') ?? false;
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static final GlobalKey<_AppShellState> shellKey = GlobalKey<_AppShellState>();

  static void navigateToTab(int index) {
    shellKey.currentState?._switchTab(index);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _loaded = false;

  void _switchTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _currentIndex = index);
    }
  }

  final _pages = const [
    DashboardScreen(),
    TasksScreen(),
    LecturesScreen(),
    HeroModeScreen(),
    LeetCodeScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Defer data loading to after the first frame to prevent ANR
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final taskProv = context.read<TaskProvider>();
    final lecProv = context.read<LectureProvider>();
    final statsProv = context.read<StatsProvider>();
    final lcProv = context.read<LeetCodeProvider>();
    final notifProv = context.read<NotificationProvider>();

    // Load local data first (instant, offline)
    await Future.wait([
      taskProv.loadTasks(),
      lecProv.loadLectures(),
      statsProv.loadStats(),
      lcProv.loadSavedUsername(),
      notifProv.loadNotifications(),
    ]);
    setState(() => _loaded = true);

    // Then pull remote changes in background (non-blocking)
    SyncService.pullRemoteChanges().then((_) {
      // Refresh local data after sync
      taskProv.loadTasks();
      lecProv.loadLectures();
      statsProv.refreshStats();
    });
    
    // Also fetch new notifications in background
    notifProv.fetchNewNotifications();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: NHRColors.milk,
        body: Center(
          child: Text('NHR', style: GoogleFonts.poppins(
            fontSize: 32, fontWeight: FontWeight.w800, color: NHRColors.charcoal, letterSpacing: 4)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: NHRColors.milk,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: NHRColors.milk,
        border: Border(top: BorderSide(color: NHRColors.fog, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _navItem(1, Icons.check_circle_outline, Icons.check_circle_rounded, 'Tasks'),
              _navItem(2, Icons.play_circle_outline, Icons.play_circle_rounded, 'Learn'),
              _navItem(3, Icons.adjust_outlined, Icons.adjust_rounded, 'Focus'),
              _navItem(4, Icons.code_outlined, Icons.code_rounded, 'LC'),
              _navItem(5, Icons.tune_outlined, Icons.tune_rounded, 'More'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);
          if (index == 0) context.read<StatsProvider>().refreshStats();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Active indicator — a tiny dot above
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: selected ? 16 : 0,
            height: 2.5,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: NHRColors.charcoal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(
            selected ? activeIcon : icon,
            color: selected ? NHRColors.charcoal : NHRColors.dusty,
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? NHRColors.charcoal : NHRColors.dusty,
              letterSpacing: 0.3,
            ),
          ),
        ]),
      ),
    );
  }
}
