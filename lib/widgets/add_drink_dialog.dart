import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../models/energy_drink.dart';
import '../services/api_service.dart';

class AddDrinkDialog extends StatefulWidget {
  final Future<void> Function(EnergyDrink drink) onSubmit;

  const AddDrinkDialog({super.key, required this.onSubmit});

  @override
  State<AddDrinkDialog> createState() => _AddDrinkDialogState();
}

class _AddDrinkDialogState extends State<AddDrinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _flavorCtrl = TextEditingController();
  final _caffeineCtrl = TextEditingController(text: '80');
  final _volumeCtrl = TextEditingController(text: '250');

  bool _isSubmitting = false;
  String? _userErrorMessage;

  @override
  void dispose() {
    _brandCtrl.dispose();
    _nameCtrl.dispose();
    _flavorCtrl.dispose();
    _caffeineCtrl.dispose();
    _volumeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _userErrorMessage = null;
    });

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
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      debugPrint('Failed to save drink: $e');
      if (!mounted) return;
      setState(() {
        _userErrorMessage = e.statusCode == 401
            ? 'Sesja wygasła. Zaloguj się ponownie.'
            : 'Nie udało się zapisać napoju.';
      });
    } catch (e) {
      debugPrint('Unexpected error while saving drink: $e');
      if (!mounted) return;
      setState(() {
        _userErrorMessage = 'Wystąpił nieoczekiwany błąd zapisu.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Dodaj nowy napój'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _brandCtrl,
                  enabled: !_isSubmitting,
                  autofocus: true,
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
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
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
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
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
                if (_userErrorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _userErrorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Anuluj'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_isSubmitting ? 'Zapisywanie...' : 'Zapisz'),
        ),
      ],
    );
  }
}