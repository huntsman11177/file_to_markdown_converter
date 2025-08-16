import 'dart:typed_data';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/conversion_result.dart';
import '../models/conversion_options.dart';

class PdfToMarkdownConverter {
  /// Convert a PDF by file path.
  static Future<ConversionResult> convertFile(
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
      return convertBytes(bytes, options: options, password: password);
    } catch (e) {
      return ConversionResult.error('Error reading PDF file: $e');
    }
  }

  /// Convert a PDF from bytes.
  static ConversionResult convertBytes(
    Uint8List bytes, {
    ConversionOptions? options,
    String? password,
  }) {
    try {
      options ??= const ConversionOptions();

      late PdfDocument document;
      try {
        // Syncfusion supports password-protected PDFs here.
        document = PdfDocument(inputBytes: bytes, password: password);
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('password') || msg.contains('encrypt')) {
          return ConversionResult.error(
            'Incorrect or missing PDF password.',
          );
        }
        return ConversionResult.error('Error opening PDF: $e');
      }

      final textExtractor = PdfTextExtractor(document);
      final buffer = StringBuffer();

      final pageCount = document.pages.count;
      final limit = options.maxPages != null && options.maxPages! > 0
          ? options.maxPages!.clamp(0, pageCount)
          : pageCount;
      final processedPages = limit;

      for (int i = 0; i < processedPages; i++) {
        final pageText = textExtractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );

        if (pageText.isEmpty) continue;

        if (processedPages > 1) {
          buffer.writeln('## Page ${i + 1}\n');
        }

        final formatted = _formatText(pageText, options);
        buffer.writeln(formatted);

        if (i < processedPages - 1) {
          buffer.writeln('\n---\n');
        }
      }

      document.dispose();

      final markdown = buffer.toString().trim();

      return ConversionResult.success(
        markdown,
        metadata: {
          'type': 'pdf',
          'pageCount': pageCount,
          'processedPages': processedPages,
          'passwordProtected': password != null && password.isNotEmpty,
        },
      );
    } catch (e) {
      return ConversionResult.error('Error parsing PDF file: $e');
    }
  }

  static String _formatText(String text, ConversionOptions options) {
    final normalized = _normalizeSpacing(text);
    if (!options.preserveFormatting) {
      return _basicHeuristics(normalized);
    }
    if (options.detectHeadings) {
      return _advancedHeuristics(normalized);
    }
    return normalized;
  }

  static String _basicHeuristics(String text) {
    final lines = text.split('\n');
    final out = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        out.writeln();
        continue;
      }

      // Simple heading guess: short line followed by longer text, not ending with sentence punctuation.
      if (line.length < 60 &&
          i < lines.length - 1 &&
          lines[i + 1].trim().length > line.length &&
          !line.endsWith('.') &&
          !line.endsWith(',') &&
          !line.endsWith(';') &&
          !RegExp(r'^\d+(\.\d+)*$').hasMatch(line)) {
        out.writeln('## $line\n');
      } else {
        out.writeln(line);
      }
    }

    return out.toString();
  }

  static String _advancedHeuristics(String text) {
    final lines = text.split('\n');
    final out = StringBuffer();

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        out.writeln();
        continue;
      }

      // All-caps heading
      final isAllCaps = line.length > 2 &&
          line.length < 80 &&
          line == line.toUpperCase() &&
          RegExp(r'[A-Z]').hasMatch(line);

      if (isAllCaps) {
        out.writeln('## $line\n');
        continue;
      }

      // Title-case short lines as subheadings (best-effort)
      final looksLikeTitle = line.length < 60 &&
          RegExp(r'^[A-Z][a-zA-Z0-9 ,;&:\-()]+$').hasMatch(line) &&
          !line.endsWith('.');

      if (looksLikeTitle) {
        out.writeln('### $line\n');
        continue;
      }

      out.writeln(line);
    }

    return out.toString();
  }

  static String _normalizeSpacing(String text) {
    return text
        .replaceAll(RegExp(r'\r\n|\r'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }
}
