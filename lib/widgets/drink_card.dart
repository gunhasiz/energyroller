import 'package:material_ui/material_ui.dart';
import '../models/energy_drink.dart';

class DrinkCard extends StatelessWidget {
  final EnergyDrink drink;

  const DrinkCard({super.key, required this.drink});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flavor = drink.flavour;

    return SizedBox(
      width: 260,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drink.brand.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                drink.name,
                style: theme.textTheme.titleLarge,
              ),
              if (flavor != null && flavor.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Smak: $flavor',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SpecBadge(
                    icon: Icons.bolt,
                    label: '${drink.caffeineMg} mg',
                  ),
                  _SpecBadge(
                    icon: Icons.local_drink_outlined,
                    label: '${drink.volume} ml',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SpecBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}