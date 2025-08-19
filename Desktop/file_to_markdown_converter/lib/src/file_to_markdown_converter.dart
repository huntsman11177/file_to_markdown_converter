import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'converters/csv_converter.dart';
import 'converters/excel_converter.dart';
import 'converters/pdf_converter.dart';
import 'models/conversion_result.dart';
import 'models/conversion_options.dart';
import 'utils/password_protection.dart';

class FileToMarkdownConverter {
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

      // Check if file is password-protected (encrypted)
      if (PasswordProtection.isPasswordProtected(filePath)) {
        if (password == null || password.isEmpty) {
          return ConversionResult.error('Password required for encrypted file: $filePath');
        }
        
        // Decrypt the file temporarily
        final decryptedBytes = await PasswordProtection.decryptFile(filePath, password);
        if (decryptedBytes == null) {
          return ConversionResult.error('Failed to decrypt file. Incorrect password or corrupted file.');
        }
        
        // Process the decrypted bytes
        return await _convertDecryptedBytes(decryptedBytes, filePath, options: options, sheetName: sheetName);
      }

      // Regular file processing
      final extension = path.extension(filePath).toLowerCase();
      return await _convertByExtension(filePath, extension, options: options, sheetName: sheetName, password: password);
    } catch (e) {
      return ConversionResult.error('Error converting file: $e');
    }
  }

  static Future<ConversionResult> _convertDecryptedBytes(
    Uint8List bytes,
    String originalFilePath, {
    ConversionOptions? options,
    String? sheetName,
  }) async {
    final extension = path.extension(originalFilePath).toLowerCase();
    
    switch (extension) {
      case '.csv':
        final content = String.fromCharCodes(bytes);
        return CsvToMarkdownConverter.convertString(content, options: options);

      case '.xlsx':
      case '.xls':
        return ExcelToMarkdownConverter.convertBytes(
          bytes,
          options: options,
          sheetName: sheetName,
        );

      case '.pdf':
        return PdfToMarkdownConverter.convertBytes(bytes, options: options);

      default:
        return ConversionResult.error('Unsupported file format: $extension');
    }
  }

  static Future<ConversionResult> _convertByExtension(
    String filePath,
    String extension, {
    ConversionOptions? options,
    String? sheetName,
    String? password,
  }) async {
    switch (extension) {
      case '.csv':
        return await CsvToMarkdownConverter.convertFile(filePath, options: options);

      case '.xlsx':
      case '.xls':
        return await ExcelToMarkdownConverter.convertFile(
          filePath,
          options: options,
          sheetName: sheetName,
          password: password,
        );

      case '.pdf':
        return await PdfToMarkdownConverter.convertFile(filePath, options: options);

      default:
        return ConversionResult.error('Unsupported file format: $extension');
    }
  }

  static ConversionResult convertBytes(
    Uint8List bytes,
    String fileType, {
    ConversionOptions? options,
    String? sheetName,
    String? password,
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
            password: password,
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

  /// Encrypts a file with password protection
  static Future<bool> protectFile(
    String inputFilePath,
    String password, {
    String? outputFilePath,
  }) async {
    try {
      final outputPath = outputFilePath ?? PasswordProtection.getProtectedFilePath(inputFilePath);
      return await PasswordProtection.protectFile(inputFilePath, outputPath, password);
    } catch (e) {
      print('Error protecting file: $e');
      return false;
    }
  }

  /// Decrypts a password-protected file
  static Future<Uint8List?> decryptFile(
    String encryptedFilePath,
    String password,
  ) async {
    return await PasswordProtection.decryptFile(encryptedFilePath, password);
  }

  /// Checks if a file is password-protected
  static bool isPasswordProtected(String filePath) {
    return PasswordProtection.isPasswordProtected(filePath);
  }
}
