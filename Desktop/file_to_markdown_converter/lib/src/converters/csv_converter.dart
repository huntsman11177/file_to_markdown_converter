import 'dart:io';
import 'package:csv/csv.dart';
import '../models/conversion_result.dart';
import '../models/conversion_options.dart';

class CsvToMarkdownConverter {
  static Future<ConversionResult> convertFile(
    String filePath, {
    ConversionOptions? options,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ConversionResult.error('File not found: $filePath');
      }
      final content = await file.readAsString();
      return convertString(content, options: options);
    } catch (e) {
      return ConversionResult.error('Error reading CSV file: $e');
    }
  }

  static ConversionResult convertString(
    String csvContent, {
    ConversionOptions? options,
  }) {
    try {
      options ??= const ConversionOptions();

      final converter = CsvToListConverter(
        fieldDelimiter: options.delimiter ?? ',',
        eol: options.eol,
        shouldParseNumbers: false,
      );
      final csvData = converter.convert(csvContent);

      if (csvData.isEmpty) {
        return ConversionResult.error('CSV file is empty');
      }

      // Limit rows if requested.
      final dataToProcess = (options.maxRows != null && options.maxRows! > 0)
          ? csvData.take(options.maxRows!).toList()
          : csvData;

      // Resolve column indices by name or index string.
      final resolved = _resolveColumns(dataToProcess, options);
      final filtered = _projectColumns(dataToProcess, resolved.indices);

      // Normalize every row to equal length.
      final normalized = _normalizeRows(filtered);

      final markdown = _generateMarkdownTable(
        normalized,
        includeHeaderRow: options.includeHeaders,
        alignments: options.columnAlignments,
      );

      return ConversionResult.success(
        markdown,
        metadata: {
          'rows': normalized.length,
          'columns': normalized.isEmpty ? 0 : normalized.first.length,
          'type': 'csv',
          'columnsSelected': resolved.selectedNames,
        },
      );
    } catch (e) {
      return ConversionResult.error('Error parsing CSV: $e');
    }
  }

  /// Returns column indices and friendly selected names if headers exist.
  static _ColumnResolution _resolveColumns(
    List<List<dynamic>> data,
    ConversionOptions options,
  ) {
    final hasHeader = options.includeHeaders && data.isNotEmpty;
    final header = hasHeader ? data.first.map((e) => e.toString()).toList() : const <String>[];

    if (options.columnsToInclude == null || options.columnsToInclude!.isEmpty) {
      final allIdx = List<int>.generate(
        data.fold<int>(0, (m, r) => r.length > m ? r.length : m),
        (i) => i,
      );
      return _ColumnResolution(indices: allIdx, selectedNames: hasHeader ? header : null);
    }

    final indices = <int>[];
    final selected = <String>[];

    for (final token in options.columnsToInclude!) {
      final idx = int.tryParse(token);
      if (idx != null) {
        indices.add(idx);
        selected.add(hasHeader && idx < header.length ? header[idx] : 'col$idx');
      } else if (hasHeader) {
        final nameIndex = header.indexOf(token);
        if (nameIndex != -1) {
          indices.add(nameIndex);
          selected.add(token);
        }
      }
    }

    if (indices.isEmpty) {
      // Fallback to all columns if nothing matched.
      final allIdx = List<int>.generate(
        data.fold<int>(0, (m, r) => r.length > m ? r.length : m),
        (i) => i,
      );
      return _ColumnResolution(indices: allIdx, selectedNames: hasHeader ? header : null);
    }

    return _ColumnResolution(indices: indices, selectedNames: selected);
  }

  static List<List<dynamic>> _projectColumns(
    List<List<dynamic>> data,
    List<int> indices,
  ) {
    return data
        .map((row) => indices.map((i) => (i < row.length ? row[i] : '')).toList())
        .toList();
  }

  static List<List<dynamic>> _normalizeRows(List<List<dynamic>> data) {
    if (data.isEmpty) return data;
    final width = data.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    return data
        .map((row) => List.generate(width, (i) => i < row.length ? row[i] : ''))
        .toList();
  }

  static String _generateMarkdownTable(
    List<List<dynamic>> data, {
    required bool includeHeaderRow,
    Map<int, String>? alignments,
  }) {
    if (data.isEmpty) return '';
    final buffer = StringBuffer();
    final columnCount = data.first.length;

    int dataStart = 0;

    // Header row
    if (includeHeaderRow) {
      buffer.write('|');
      for (int c = 0; c < columnCount; c++) {
        buffer.write(' ${_escapeMarkdown(data[0][c].toString())} |');
      }
      buffer.writeln();

      // Separator with alignments
      buffer.write('|');
      for (int c = 0; c < columnCount; c++) {
        final align = alignments != null && alignments.containsKey(c)
            ? alignments[c]!
            : '---';
        buffer.write(' $align |');
      }
      buffer.writeln();
      dataStart = 1;
    }

    // Rows
    for (int r = dataStart; r < data.length; r++) {
      buffer.write('|');
      for (int c = 0; c < columnCount; c++) {
        buffer.write(' ${_escapeMarkdown(data[r][c].toString())} |');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  static String _escapeMarkdown(String text) =>
      text.replaceAll('|', '\\|').replaceAll('\n', ' ').replaceAll('\r', '');
}

class _ColumnResolution {
  final List<int> indices;
  final List<String>? selectedNames;
  _ColumnResolution({required this.indices, this.selectedNames});
}
