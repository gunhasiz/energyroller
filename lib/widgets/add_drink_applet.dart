import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../models/energy_drink.dart';

class AddDrinkApplet extends StatefulWidget {
  final Future<void> Function(EnergyDrink drink) onSubmit;

  const AddDrinkApplet({super.key, required this.onSubmit});

  @override
  State<AddDrinkApplet> createState() => _AddDrinkAppletState();
}

class _AddDrinkAppletState extends State<AddDrinkApplet> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _flavorCtrl = TextEditingController();
  final _caffeineCtrl = TextEditingController(text: '80');
  final _volumeCtrl = TextEditingController(text: '250');

  bool _isSubmitting = false;

  @override
  void dispose() {
    _brandCtrl.dispose();
    _nameCtrl.dispose();
    _flavorCtrl.dispose();
    _caffeineCtrl.dispose();
    _volumeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final newDrink = EnergyDrink(
      brand: _brandCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      flavour: _flavorCtrl.text.trim(),
      caffeineMg: int.tryParse(_caffeineCtrl.text.trim()) ?? 80,
      volume: int.tryParse(_volumeCtrl.text.trim()) ?? 250,
    );

    try {
      await widget.onSubmit(newDrink);
      if (!mounted) return;

      _brandCtrl.clear();
      _nameCtrl.clear();
      _flavorCtrl.clear();
      _caffeineCtrl.text = '80';
      _volumeCtrl.text = '250';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Zapisano napój w bazie')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się zapisać: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aplet dodawania do bazy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandCtrl,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Marka * (np. Monster, Red Bull)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Podaj markę' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nazwa * (np. Ultra White, Classic)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Podaj nazwę' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _flavorCtrl,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Smak (opcjonalnie)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _caffeineCtrl,
                    enabled: !_isSubmitting,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Kofeina (mg)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wymagane' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _volumeCtrl,
                    enabled: !_isSubmitting,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Pojemność (ml)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wymagane' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _isSubmitting ? null : _handleSave,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_isSubmitting ? 'Zapisywanie...' : 'Zapisz'),
            ),
          ],
        ),
      ),
    );
  }
}
