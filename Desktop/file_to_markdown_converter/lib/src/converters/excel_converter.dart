import 'dart:io';
import 'dart:typed_data';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import '../models/conversion_result.dart';
import '../models/conversion_options.dart';

class ExcelToMarkdownConverter {
  static Future<ConversionResult> convertFile(
    String filePath, {
    ConversionOptions? options,
    String? sheetName,
    String? password,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ConversionResult.error('File not found: $filePath');
      }

      final bytes = await file.readAsBytes();
      return await _convertWithSpreadsheetDecoder(bytes, options: options, sheetName: sheetName, password: password);
    } catch (e) {
      return ConversionResult.error('Error reading Excel file: $e');
    }
  }

  static Future<ConversionResult> _convertWithSpreadsheetDecoder(
    Uint8List bytes, {
    ConversionOptions? options,
    String? sheetName,
    String? password,
  }) async {
    try {
      options ??= const ConversionOptions();
      
      // Decode the spreadsheet - note: spreadsheet_decoder doesn't support passwords directly
      // We'll handle password errors gracefully
      final decoder = SpreadsheetDecoder.decodeBytes(bytes);
      
      if (decoder.tables.isEmpty) {
        return ConversionResult.error('Excel file contains no sheets');
      }

      // Get the specified sheet or first available sheet
      String targetSheetName;
      if (sheetName != null) {
        if (decoder.tables.containsKey(sheetName)) {
          targetSheetName = sheetName;
        } else {
          return ConversionResult.error('Sheet "$sheetName" not found. Available sheets: ${decoder.tables.keys.join(", ")}');
        }
      } else {
        targetSheetName = decoder.tables.keys.first;
      }

      final table = decoder.tables[targetSheetName]!;
      final markdown = _convertTableToMarkdown(table, options);

      return ConversionResult.success(
        markdown,
        metadata: {
          'sheetName': targetSheetName,
          'columns': table.rows.isNotEmpty ? table.rows.first.length : 0,
          'maxRows': table.rows.length,
          'type': 'excel',
          'availableSheets': decoder.tables.keys.toList(),
          'isPasswordProtected': password != null && password.isNotEmpty,
          'note': password != null && password.isNotEmpty 
              ? 'Password parameter provided but spreadsheet_decoder may not support password-protected files'
              : null,
        },
      );
    } catch (e) {
      if (e.toString().contains('password') || e.toString().contains('Password')) {
        return ConversionResult.error('Failed to open password-protected file. Please provide the correct password.');
      }
      return ConversionResult.error('Error parsing Excel file: $e');
    }
  }

  static ConversionResult convertBytes(
    Uint8List bytes, {
    ConversionOptions? options,
    String? sheetName,
    String? password,
  }) {
    try {
      // For bytes, we need to handle them synchronously
      // We'll create a temporary approach for password-protected files
      if (password != null && password.isNotEmpty) {
        return ConversionResult.error(
          'Password-protected Excel files require file path conversion. Use convertFile() method instead.'
        );
      }
      
      return _convertBytesWithoutPassword(bytes, options: options, sheetName: sheetName);
    } catch (e) {
      return ConversionResult.error('Error parsing Excel file bytes: $e');
    }
  }

  static ConversionResult _convertBytesWithoutPassword(
    Uint8List bytes, {
    ConversionOptions? options,
    String? sheetName,
  }) {
    try {
      options ??= const ConversionOptions();
      
      final decoder = SpreadsheetDecoder.decodeBytes(bytes);
      
      if (decoder.tables.isEmpty) {
        return ConversionResult.error('Excel file contains no sheets');
      }

      String targetSheetName;
      if (sheetName != null) {
        if (decoder.tables.containsKey(sheetName)) {
          targetSheetName = sheetName;
        } else {
          return ConversionResult.error('Sheet "$sheetName" not found. Available sheets: ${decoder.tables.keys.join(", ")}');
        }
      } else {
        targetSheetName = decoder.tables.keys.first;
      }

      final table = decoder.tables[targetSheetName]!;
      final markdown = _convertTableToMarkdown(table, options);

      return ConversionResult.success(
        markdown,
        metadata: {
          'sheetName': targetSheetName,
          'columns': table.rows.isNotEmpty ? table.rows.first.length : 0,
          'maxRows': table.rows.length,
          'type': 'excel',
          'availableSheets': decoder.tables.keys.toList(),
        },
      );
    } catch (e) {
      return ConversionResult.error('Error parsing Excel file: $e');
    }
  }

  static Future<ConversionResult> convertAllSheets(
    String filePath, {
    ConversionOptions? options,
    String? password,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ConversionResult.error('File not found: $filePath');
      }

      final bytes = await file.readAsBytes();
      return await _convertAllSheetsWithSpreadsheetDecoder(bytes, options: options, password: password);
    } catch (e) {
      return ConversionResult.error('Error processing Excel file: $e');
    }
  }

  static Future<ConversionResult> _convertAllSheetsWithSpreadsheetDecoder(
    Uint8List bytes, {
    ConversionOptions? options,
    String? password,
  }) async {
    try {
      options ??= const ConversionOptions();
      
      final decoder = SpreadsheetDecoder.decodeBytes(bytes);
      
      if (decoder.tables.isEmpty) {
        return ConversionResult.error('Excel file contains no sheets');
      }

      final buffer = StringBuffer();
      final sheetNames = <String>[];

      for (final entry in decoder.tables.entries) {
        final name = entry.key;
        final table = entry.value;
        sheetNames.add(name);

        if (options.includeSheetHeadings) {
          buffer.writeln('${options.sheetHeadingPrefix} $name\n');
        }
        buffer.writeln(_convertTableToMarkdown(table, options));
        buffer.writeln();
      }

      return ConversionResult.success(
        buffer.toString(),
        metadata: {
          'sheets': sheetNames,
          'type': 'excel_all_sheets',
          'isPasswordProtected': password != null && password.isNotEmpty,
          'note': password != null && password.isNotEmpty 
              ? 'Password parameter provided but spreadsheet_decoder may not support password-protected files'
              : null,
        },
      );
    } catch (e) {
      if (e.toString().contains('password') || e.toString().contains('Password')) {
        return ConversionResult.error('Failed to open password-protected file. Please provide the correct password.');
      }
      return ConversionResult.error('Error processing Excel file: $e');
    }
  }

  static String _convertTableToMarkdown(SpreadsheetTable table, ConversionOptions options) {
    if (table.rows.isEmpty) return 'Sheet is empty';

    final int limit = options.maxRows != null && options.maxRows! > 0
        ? options.maxRows!.clamp(0, table.rows.length)
        : table.rows.length;

    // Get the data up to the limit
    final data = table.rows.take(limit).toList();
    
    // Resolve columns by name (when header exists) or index strings
    final resolved = _resolveColumns(data, options);
    final projected = _projectColumns(data, resolved.indices);
    final normalized = _normalizeRows(projected);

    // Render table
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

  static String _escapeMarkdown(String text) =>
      text.replaceAll('|', '\\|').replaceAll('\n', ' ').replaceAll('\r', '');
}

class _ColumnResolution {
  final List<int> indices;
  final List<String>? selectedNames;
  _ColumnResolution({required this.indices, this.selectedNames});
}
