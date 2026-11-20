import '../models/energy_drink.dart';

class CsvParseResult {
  final List<EnergyDrink> drinks;
  final List<String> rowErrors;

  const CsvParseResult({
    required this.drinks,
    required this.rowErrors,
  });

  bool get hasValidDrinks => drinks.isNotEmpty;
  bool get hasErrors => rowErrors.isNotEmpty;
}

class CsvParser {
  const CsvParser._();

  static CsvParseResult parse(String rawContent) {
    final content = rawContent.startsWith('\uFEFF')
        ? rawContent.substring(1)
        : rawContent;

    final lines = content
        .split(RegExp(r'\r\n|\r|\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const CsvParseResult(
        drinks: [],
        rowErrors: ['Plik CSV jest pusty.'],
      );
    }

    final delimiter = _detectDelimiter(lines.first);
    final drinks = <EnergyDrink>[];
    final rowErrors = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final lineNumber = i + 1;
      final columns = _splitCsvLine(lines[i], delimiter);

      if (i == 0 && _isHeaderRow(columns)) {
        continue;
      }

      if (columns.length < 2) {
        rowErrors.add(
          'Wiersz $lineNumber: wymagane są co najmniej 2 kolumny (marka, nazwa).',
        );
        continue;
      }

      final brand = columns[0].trim();
      final name = columns[1].trim();
      final flavor = columns.length > 2 ? columns[2].trim() : '';
      final rawCaffeine = columns.length > 3 ? columns[3].trim() : '';
      final rawVolume = columns.length > 4 ? columns[4].trim() : '';

      if (brand.isEmpty || name.isEmpty) {
        rowErrors.add(
          'Wiersz $lineNumber: marka oraz nazwa nie mogą być puste.',
        );
        continue;
      }

      final caffeine = rawCaffeine.isEmpty ? 80 : int.tryParse(rawCaffeine);
      if (caffeine == null || caffeine < 0) {
        rowErrors.add(
          'Wiersz $lineNumber: nieprawidłowa wartość kofeiny ("$rawCaffeine").',
        );
        continue;
      }

      final volume = rawVolume.isEmpty ? 250 : int.tryParse(rawVolume);
      if (volume == null || volume <= 0) {
        rowErrors.add(
          'Wiersz $lineNumber: nieprawidłowa pojemność ("$rawVolume").',
        );
        continue;
      }

      drinks.add(
        EnergyDrink(
          brand: brand,
          name: name,
          flavour: flavor.isNotEmpty ? flavor : null,
          caffeineMg: caffeine,
          volume: volume,
        ),
      );
    }

    return CsvParseResult(
      drinks: drinks,
      rowErrors: rowErrors,
    );
  }

  static String _detectDelimiter(String sampleLine) {
    final semicolons = ';'.allMatches(sampleLine).length;
    final commas = ','.allMatches(sampleLine).length;
    return semicolons > commas ? ';' : ',';
  }

  static bool _isHeaderRow(List<String> columns) {
    if (columns.length < 2) return false;
    final first = columns[0].trim().toLowerCase();
    final second = columns[1].trim().toLowerCase();

    const brandHeaders = {'brand', 'marka'};
    const nameHeaders = {'name', 'nazwa'};

    return brandHeaders.contains(first) && nameHeaders.contains(second);
  }

  static List<String> _splitCsvLine(String line, String delimiter) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == delimiter && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    fields.add(buffer.toString());
    return fields;
  }
}