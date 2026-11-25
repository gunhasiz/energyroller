import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../models/energy_drink.dart';
import '../services/api_service.dart';
import '../utils/csv_parser.dart';

enum _AddMode { single, csv }

class AddDrinkDialog extends StatefulWidget {
  final Future<void> Function(EnergyDrink drink) onSubmit;
  final Future<void> Function(List<EnergyDrink> drinks)? onSubmitBatch;

  const AddDrinkDialog({
    super.key,
    required this.onSubmit,
    this.onSubmitBatch,
  });

  @override
  State<AddDrinkDialog> createState() => _AddDrinkDialogState();
}

class _AddDrinkDialogState extends State<AddDrinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _flavourCtrl = TextEditingController();
  final _caffeineCtrl = TextEditingController(text: '80');
  final _volumeCtrl = TextEditingController(text: '250');

  _AddMode _mode = _AddMode.single;
  bool _isSubmitting = false;
  String? _userErrorMessage;

  // CSV import state
  String? _selectedFileName;
  CsvParseResult? _csvResult;
  int _importedCount = 0;

  @override
  void dispose() {
    _brandCtrl.dispose();
    _nameCtrl.dispose();
    _flavourCtrl.dispose();
    _caffeineCtrl.dispose();
    _volumeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitSingle() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _userErrorMessage = null;
    });

    final newDrink = EnergyDrink(
      brand: _brandCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      flavour: _flavourCtrl.text.trim(),
      caffeineMg: int.tryParse(_caffeineCtrl.text.trim()) ?? 80,
      volume: int.tryParse(_volumeCtrl.text.trim()) ?? 250,
    );

    try {
      await widget.onSubmit(newDrink);
      if (!mounted) return;
      Navigator.of(context).pop(1);
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

  Future<void> _pickCsvFile() async {
    if (_isSubmitting) return;
  
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
  
      if (file == null) return; // użytkownik anulował
  
      final bytes = await file.readAsBytes();
      if (!mounted) return;
  
      final content = utf8.decode(bytes, allowMalformed: true);
      final parsed = CsvParser.parse(content);
  
      setState(() {
        _selectedFileName = file.name;
        _csvResult = parsed;
        _importedCount = 0;
        _userErrorMessage = null;
      });
    } catch (e) {
      debugPrint('Failed to pick or read CSV file: $e');
      if (!mounted) return;
      setState(() {
        _userErrorMessage = 'Wystąpił błąd podczas wczytywania pliku CSV.';
      });
    }
  }

  Future<void> _submitCsv() async {
    final drinks = _csvResult?.drinks;
    if (_isSubmitting || drinks == null || drinks.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _importedCount = 0;
      _userErrorMessage = null;
    });

    try {
      if (widget.onSubmitBatch != null) {
        await widget.onSubmitBatch!(drinks);
        if (!mounted) return;
        Navigator.of(context).pop(drinks.length);
        return;
      }

      for (var i = 0; i < drinks.length; i++) {
        await widget.onSubmit(drinks[i]);
        if (!mounted) return;
        setState(() => _importedCount = i + 1);
      }

      Navigator.of(context).pop(drinks.length);
    } on ApiException catch (e) {
      debugPrint('CSV import aborted due to API error: $e');
      if (!mounted) return;
      setState(() {
        _userErrorMessage = e.statusCode == 401
            ? 'Sesja wygasła. Zaloguj się ponownie.'
            : 'Przerwano import po zapisaniu $_importedCount z ${drinks.length} pozycji.';
      });
    } catch (e) {
      debugPrint('Unexpected error during CSV import: $e');
      if (!mounted) return;
      setState(() {
        _userErrorMessage =
            'Wystąpił nieoczekiwany błąd podczas importu pliku CSV.';
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
    final parsedDrinks = _csvResult?.drinks ?? const [];

    return AlertDialog(
      title: const Text('Dodaj napoje do bazy'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_AddMode>(
                segments: const [
                  ButtonSegment<_AddMode>(
                    value: _AddMode.single,
                    icon: Icon(Icons.edit_note),
                    label: Text('Pojedynczy napój'),
                  ),
                  ButtonSegment<_AddMode>(
                    value: _AddMode.csv,
                    icon: Icon(Icons.upload_file),
                    label: Text('Import z CSV'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _isSubmitting
                    ? null
                    : (selection) {
                        setState(() {
                          _mode = selection.first;
                          _userErrorMessage = null;
                        });
                      },
              ),
              const SizedBox(height: 20),
              if (_mode == _AddMode.single)
                _buildSingleForm()
              else
                _buildCsvSection(theme),
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
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.of(context).pop(null),
          child: const Text('Anuluj'),
        ),
        if (_mode == _AddMode.single)
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitSingle,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSubmitting ? 'Zapisywanie...' : 'Zapisz'),
          )
        else
          FilledButton.icon(
            onPressed: (_isSubmitting || parsedDrinks.isEmpty)
                ? null
                : _submitCsv,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_check),
            label: Text(
              _isSubmitting
                  ? (_importedCount > 0
                      ? 'Zapisywanie $_importedCount/${parsedDrinks.length}...'
                      : 'Importowanie...')
                  : 'Importuj (${parsedDrinks.length})',
            ),
          ),
      ],
    );
  }

  Widget _buildSingleForm() {
    return Form(
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
            controller: _flavourCtrl,
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
                  onFieldSubmitted: (_) => _submitSingle(),
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
        ],
      ),
    );
  }

  Widget _buildCsvSection(ThemeData theme) {
    final result = _csvResult;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Format kolumn (separator "," lub ";", nagłówek opcjonalny):',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'marka;nazwa;smak;kofeina_mg;pojemnosc_ml',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Przykład:\nMonster;Ultra White;Cytrusowy;150;500\nRed Bull;Classic;;80;250',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSubmitting ? null : _pickCsvFile,
          icon: const Icon(Icons.folder_open_outlined),
          label: Text(
            _selectedFileName ?? 'Wybierz plik .csv',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 12),
          Text(
            'Gotowe do dodania: ${result.drinks.length} pozycji',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          if (result.drinks.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: result.drinks.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final drink = result.drinks[index];
                    final flavourPart =
                        (drink.flavour != null && drink.flavour!.isNotEmpty)
                            ? ' (${drink.flavour})'
                            : '';
                    return ListTile(
                      dense: true,
                      title: Text('${drink.brand} — ${drink.name}$flavourPart'),
                      trailing: Text(
                        '${drink.caffeineMg} mg / ${drink.volume} ml',
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (result.hasErrors) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pominięte wiersze (${result.rowErrors.length}):',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...result.rowErrors.take(5).map(
                        (err) => Text(
                          '• $err',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                  if (result.rowErrors.length > 5)
                    Text(
                      '...oraz ${result.rowErrors.length - 5} innych.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}