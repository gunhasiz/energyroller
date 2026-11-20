import 'package:material_ui/material_ui.dart';

import '../models/energy_drink.dart';
import '../services/api_service.dart';
import '../widgets/add_drink_dialog.dart';
import '../widgets/drink_card.dart';
import '../widgets/login_dialog.dart';

class RollerScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const RollerScreen({super.key, required this.onToggleTheme});

  @override
  State<RollerScreen> createState() => _RollerScreenState();
}

class _RollerScreenState extends State<RollerScreen> {
  final _apiService = DrinkApiService();

  List<EnergyDrink> _rolledDrinks = const [];
  int _totalInDb = 0;
  bool _hasRolled = false;
  bool _isRolling = false;
  String? _userErrorMessage;

  @override
  void initState() {
    super.initState();
    _refreshDrinkCount();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _refreshDrinkCount() async {
    try {
      final allDrinks = await _apiService.fetchAll();

      if (!mounted) return;

      setState(() => _totalInDb = allDrinks.length);
    } catch (e) {
      debugPrint('Failed to fetch drink count: $e');

      if (!mounted) return;

      setState(() {
        _userErrorMessage = 'Nie udało się połączyć z serwerem.';
      });
    }
  }

  Future<void> _rollDrinks() async {
    setState(() {
      _isRolling = true;
      _userErrorMessage = null;
    });

    try {
      final rolled = await _apiService.rollThree();

      if (!mounted) return;

      setState(() {
        _rolledDrinks = rolled;
        _hasRolled = true;
      });
    } catch (e) {
      debugPrint('Failed to roll drinks: $e');

      if (!mounted) return;

      setState(() {
        _userErrorMessage = 'Nie udało się wylosować napojów.';
      });
    } finally {
      if (mounted) {
        setState(() => _isRolling = false);
      }
    }
  }

  Future<void> _openLoginDialog() async {
    final loggedIn = await showDialog<bool>(
      context: context,
      builder: (_) => LoginDialog(apiService: _apiService),
    );

    if (loggedIn == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openAddDrinkDialog() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => AddDrinkDialog(onSubmit: _handleAddDrink),
    );

    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zapisano napój w bazie.')),
      );
    }
  }

  Future<void> _logout() async {
    await _apiService.logout();

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Wylogowano')));
  }

  Future<void> _handleAddDrink(EnergyDrink drink) async {
    try {
      await _apiService.addDrink(drink);
      await _refreshDrinkCount();
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        setState(() {});
      }

      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = _apiService.isAuthenticated;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Drink Roulette'),
        actions: [
          Chip(
            avatar: const Icon(Icons.storage, size: 18),
            label: Text('W bazie: $_totalInDb'),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: widget.onToggleTheme,
            tooltip: isDarkMode
                ? 'Przełącz na jasny motyw'
                : 'Przełącz na ciemny motyw',
            icon: Icon(
              isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
          if (isAuthenticated) ...[
            FilledButton.tonalIcon(
              onPressed: _openAddDrinkDialog,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Wyloguj'),
            ),
          ] else
            TextButton.icon(
              onPressed: _openLoginDialog,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Zaloguj'),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: _buildRollerSection(context),
          ),
        ),
      ),
    );
  }

  Widget _buildRollerSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_userErrorMessage != null) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _userErrorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (!_hasRolled) ...[
          Icon(
            Icons.casino_outlined,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Wylosuj zestaw 3 energetyków',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Naciśnij przycisk poniżej, aby wylosować napoje z bazy.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ] else if (_isRolling && _rolledDrinks.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ] else if (_rolledDrinks.isEmpty) ...[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Baza jest pusta.', textAlign: TextAlign.center),
            ),
          ),
        ] else ...[
          Text(
            'Wylosowana trójka',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: _rolledDrinks
                .map((drink) => DrinkCard(drink: drink))
                .toList(),
          ),
        ],
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _isRolling ? null : _rollDrinks,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
          icon: _isRolling
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.casino),
          label: Text(_hasRolled ? 'Losuj ponownie' : 'Losuj 3 energetyki'),
        ),
      ],
    );
  }
}
