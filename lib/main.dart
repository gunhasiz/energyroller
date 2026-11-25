import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeService = await ThemeService.init();

  runApp(
    EnergyRollerApp(
      themeService: themeService,
      initialThemeMode: themeService.loadThemeMode(),
    ),
  );
}