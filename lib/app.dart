import 'package:material_ui/material_ui.dart';
import 'screens/roller_screen.dart';

class EnergyRollerApp extends StatefulWidget {
  const EnergyRollerApp({super.key});

  @override
  State<EnergyRollerApp> createState() => _EnergyRollerAppState();
}

class _EnergyRollerAppState extends State<EnergyRollerApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
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