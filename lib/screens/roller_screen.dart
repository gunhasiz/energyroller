import 'package:material_ui/material_ui.dart';

import '../models/energy_drink.dart';
import '../services/api_service.dart';
import '../widgets/add_drink_applet.dart';
import '../widgets/drink_card.dart';

class RollerScreen extends StatefulWidget {
  const RollerScreen({super.key});

  @override
  State<RollerScreen> createState() => _RollerScreenState();
}

class _RollerScreenState extends State<RollerScreen> {
  final _apiService = DrinkApiService();

  List<EnergyDrink> _rolledDrinks = const [];
  int _totalInDb = 0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.fetchAll(),
        _apiService.rollThree(),
      ]);

      if (!mounted) return;
      setState(() {
        _totalInDb = results[0].length;
        _rolledDrinks = results[1];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rollDrinks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rolled = await _apiService.rollThree();
      if (!mounted) return;
      setState(() => _rolledDrinks = rolled);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAddDrink(EnergyDrink drink) async {
    await _apiService.addDrink(drink);
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Drink Roulette'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Chip(
              avatar: const Icon(Icons.storage, size: 18),
              label: Text('W bazie: $_totalInDb'),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildRollerArea(context)),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 380,
                  child: SingleChildScrollView(
                    child: AddDrinkApplet(onSubmit: _handleAddDrink),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRollerArea(context),
                const Divider(height: 32),
                AddDrinkApplet(onSubmit: _handleAddDrink),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRollerArea(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Wylosowana trójka', style: theme.textTheme.headlineSmall),
              const Spacer(),
              FilledButton.icon(
                onPressed: _isLoading ? null : _rollDrinks,
                icon: const Icon(Icons.casino),
                label: const Text('Losuj 3 energetyki'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_isLoading && _rolledDrinks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_rolledDrinks.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Baza jest pusta.'),
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _rolledDrinks
                  .map((drink) => DrinkCard(drink: drink))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
