import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';
import 'core/di.dart';
import 'app_router.dart';
import 'views/splash_screen.dart';
import 'widgets/loading_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DI.init();                     // jangan await yang panjang di sini
  runApp(const MyApp());         // jalankan secepatnya biar tidak terlihat hitam
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _themeReady = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    DI.theme.addListener(_onTheme);
  }

  void _onTheme() => setState(() {});
  Future<void> _loadTheme() async {
    await DI.theme.load();       // load async setelah app hidup
    if (mounted) setState(() => _themeReady = true);
  }

  @override
  void dispose() {
    DI.theme.removeListener(_onTheme);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.cyan,
      brightness: Brightness.light,
    );
    final dark = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.cyan,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Kosanku',
      theme: light,
      darkTheme: dark,
      themeMode: DI.theme.mode,
      routes: AppRouter.routes,
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      home: _themeReady
          ? const SplashScreen()
          : const Scaffold(                 // sementara (theme loading cepat)
        backgroundColor: Color(0xFF00BCD4),
        body: Center(child: LoadingWidget(color: Colors.white, size: 60)),
      ),
    );
  }
}
