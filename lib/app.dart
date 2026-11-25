import 'package:material_ui/material_ui.dart';

import 'services/theme_service.dart';
import 'screens/roller_screen.dart';

class EnergyRollerApp extends StatefulWidget {
  final ThemeService themeService;
  final ThemeMode initialThemeMode;

  const EnergyRollerApp({
    super.key,
    required this.themeService,
    this.initialThemeMode = ThemeMode.light,
  });

  @override
  State<EnergyRollerApp> createState() => _EnergyRollerAppState();
}

class _EnergyRollerAppState extends State<EnergyRollerApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  void _toggleTheme() {
    final nextMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    setState(() {
      _themeMode = nextMode;
    });

    widget.themeService.saveThemeMode(nextMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EnergyRoller',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 0, 255, 255),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 115, 255, 0),
          brightness: Brightness.dark,
        ),
      ),
      home: RollerScreen(
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}