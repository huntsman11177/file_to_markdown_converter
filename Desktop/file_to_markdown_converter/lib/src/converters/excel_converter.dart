import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/conversion_result.dart';
import '../models/conversion_options.dart';

class ExcelToMarkdownConverter {
  static Future<ConversionResult> convertFile(
    String filePath, {
    ConversionOptions? options,
    String? sheetName,
    String? password, // Not supported by package; surfaced for API consistency.
  }) async {
    try {
      if (password != null && password.isNotEmpty) {
        return ConversionResult.error(
          'Password-protected Excel files are not supported by the current Excel package.',
        );
      }

      final file = File(filePath);
      if (!await file.exists()) {
        return ConversionResult.error('File not found: $filePath');
      }
      final bytes = await file.readAsBytes();
      return convertBytes(bytes, options: options, sheetName: sheetName);
    } catch (e) {
      return ConversionResult.error('Error reading Excel file: $e');
    }
  }

  static ConversionResult convertBytes(
    Uint8List bytes, {
    ConversionOptions? options,
    String? sheetName,
  }) {
    try {
      options ??= const ConversionOptions();
      final excel = Excel.decodeBytes(bytes);

      if (excel.sheets.isEmpty) {
        return ConversionResult.error('Excel file contains no sheets');
      }

      Sheet sheet;
      if (sheetName != null) {
        final s = excel.sheets[sheetName];
        if (s == null) return ConversionResult.error('Sheet "$sheetName" not found');
        sheet = s;
      } else {
        sheet = excel.sheets.values.first;
      }

      final markdown = _convertSheetToMarkdown(sheet, options);

      final headerRow = sheet.maxRows > 0 ? sheet.row(0) : <Data>[];
      return ConversionResult.success(
        markdown,
        metadata: {
          'sheetName': sheet.sheetName,
          'columns': headerRow.length,
          'maxRows': sheet.maxRows,
          'type': 'excel',
          'availableSheets': excel.sheets.keys.toList(),
        },
      );
    } catch (e) {
      return ConversionResult.error('Error parsing Excel file: $e');
    }
  }

  static Future<ConversionResult> convertAllSheets(
    String filePath, {
    ConversionOptions? options,
    String? password, // Not supported; API consistency.
  }) async {
    try {
      if (password != null && password.isNotEmpty) {
        return ConversionResult.error(
          'Password-protected Excel files are not supported by the current Excel package.',
        );
      }

      final file = File(filePath);
      if (!await file.exists()) {
        return ConversionResult.error('File not found: $filePath');
      }
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      if (excel.sheets.isEmpty) {
        return ConversionResult.error('Excel file contains no sheets');
      }
      options ??= const ConversionOptions();

      final buffer = StringBuffer();
      final sheetNames = <String>[];
      for (final entry in excel.sheets.entries) {
        final name = entry.key;
        final sheet = entry.value;
        sheetNames.add(name);

        if (options.includeSheetHeadings) {
          buffer.writeln('${options.sheetHeadingPrefix} $name\n');
        }
        buffer.writeln(_convertSheetToMarkdown(sheet, options));
        buffer.writeln();
      }

      return ConversionResult.success(
        buffer.toString(),
        metadata: {
          'sheets': sheetNames,
          'type': 'excel_all_sheets',
        },
      );
    } catch (e) {
      return ConversionResult.error('Error processing Excel file: $e');
    }
  }

  static String _convertSheetToMarkdown(Sheet sheet, ConversionOptions options) {
    if (sheet.maxRows == 0) return 'Sheet is empty';

    final int limit = options.maxRows != null && options.maxRows! > 0
        ? options.maxRows!.clamp(0, sheet.maxRows)
        : sheet.maxRows;

    // Build raw matrix of values up to limit rows.
    final raw = <List<dynamic>>[];
    for (int r = 0; r < limit; r++) {
      final row = sheet.row(r);
      raw.add(row.map(_formatCellValue).toList());
    }

    // Resolve columns by name (when header exists) or index strings.
    final resolved = _resolveColumns(raw, options);
    final projected = _projectColumns(raw, resolved.indices);
    final normalized = _normalizeRows(projected);

    // Render table.
    return _renderMarkdownTable(
      normalized,
      includeHeaderRow: options.includeHeaders,
      alignments: options.columnAlignments,
    );
  }

  static _ColumnResolution _resolveColumns(
    List<List<dynamic>> data,
    ConversionOptions options,
  ) {
    final hasHeader = options.includeHeaders && data.isNotEmpty;
    final header = hasHeader ? data.first.map((e) => e.toString()).toList() : const <String>[];

    if (options.columnsToInclude == null || options.columnsToInclude!.isEmpty) {
      final width = data.fold<int>(0, (m, r) => r.length > m ? r.length : m);
      return _ColumnResolution(
        indices: List<int>.generate(width, (i) => i),
        selectedNames: hasHeader ? header : null,
      );
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
      final width = data.fold<int>(0, (m, r) => r.length > m ? r.length : m);
      return _ColumnResolution(
        indices: List<int>.generate(width, (i) => i),
        selectedNames: hasHeader ? header : null,
      );
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

  static String _renderMarkdownTable(
    List<List<dynamic>> data, {
    required bool includeHeaderRow,
    Map<int, String>? alignments,
  }) {
    if (data.isEmpty) return '';
    final buffer = StringBuffer();
    final columnCount = data.first.length;
    int start = 0;

    if (includeHeaderRow) {
      buffer.write('|');
      for (int c = 0; c < columnCount; c++) {
        buffer.write(' ${_escapeMarkdown(data[0][c].toString())} |');
      }
      buffer.writeln();

      buffer.write('|');
      for (int c = 0; c < columnCount; c++) {
        final align = alignments != null && alignments.containsKey(c)
            ? alignments[c]!
            : '---';
        buffer.write(' $align |');
      }
      buffer.writeln();

      start = 1;
    }

    for (int r = start; r < data.length; r++) {
      buffer.write('|');
      for (int c = 0; c < columnCount; c++) {
        buffer.write(' ${_escapeMarkdown(data[r][c].toString())} |');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  static String _formatCellValue(Data? cell) {
    final v = cell?.value;
    if (v == null) return '';
    if (v is double) {
      return (v == (v as double).truncateToDouble()) ? (v as double).toInt().toString() : v.toString();
    }
    if (v is DateTime) return (v as DateTime).toIso8601String();
    if (v == true) return 'TRUE';
    if (v == false) return 'FALSE';
    return v.toString();
  }

  static String _escapeMarkdown(String text) =>
      text.replaceAll('|', '\\|').replaceAll('\n', ' ').replaceAll('\r', '');
}

class _ColumnResolution {
  final List<int> indices;
  final List<String>? selectedNames;
  _ColumnResolution({required this.indices, this.selectedNames});
}
