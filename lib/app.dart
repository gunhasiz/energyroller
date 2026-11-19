import 'package:material_ui/material_ui.dart';
import 'screens/roller_screen.dart';

class EnergyRollerApp extends StatelessWidget {
  const EnergyRollerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EnergyRoller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF76FF03),
          brightness: Brightness.light,
        ),
      ),
      home: const RollerScreen(),
    );
  }
}