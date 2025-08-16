import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'converters/csv_converter.dart';
import 'converters/excel_converter.dart';
import 'converters/pdf_converter.dart';
import 'models/conversion_result.dart';
import 'models/conversion_options.dart';

class FileToMarkdownConverter {
  static Future<ConversionResult> convertFile(
    String filePath, {
    ConversionOptions? options,
    String? sheetName,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ConversionResult.error('File not found: $filePath');
      }

      final extension = path.extension(filePath).toLowerCase();

      switch (extension) {
        case '.csv':
          return await CsvToMarkdownConverter.convertFile(filePath, options: options);

        case '.xlsx':
        case '.xls':
          return await ExcelToMarkdownConverter.convertFile(
            filePath,
            options: options,
            sheetName: sheetName,
          );

        case '.pdf':
          return await PdfToMarkdownConverter.convertFile(filePath, options: options);

        default:
          return ConversionResult.error('Unsupported file format: $extension');
      }
    } catch (e) {
      return ConversionResult.error('Error converting file: $e');
    }
  }

  static ConversionResult convertBytes(
    Uint8List bytes,
    String fileType, {
    ConversionOptions? options,
    String? sheetName,
  }) {
    try {
      final normalizedType = fileType.toLowerCase().replaceAll('.', '');

      switch (normalizedType) {
        case 'csv':
          final content = String.fromCharCodes(bytes);
          return CsvToMarkdownConverter.convertString(content, options: options);

        case 'xlsx':
        case 'xls':
          return ExcelToMarkdownConverter.convertBytes(
            bytes,
            options: options,
            sheetName: sheetName,
          );

        case 'pdf':
          return PdfToMarkdownConverter.convertBytes(bytes, options: options);

        default:
          return ConversionResult.error('Unsupported file type: $fileType');
      }
    } catch (e) {
      return ConversionResult.error('Error converting file bytes: $e');
    }
  }
}
