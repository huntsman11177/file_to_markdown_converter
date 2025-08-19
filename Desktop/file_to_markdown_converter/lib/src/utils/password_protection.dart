import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

/// Utility class for password-protecting files and handling encrypted content
class PasswordProtection {
  /// Checks if a file is password-protected (encrypted)
  static bool isPasswordProtected(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.enc' || extension == '.protected';
  }

  /// Creates a protected file path by adding .protected extension
  static String getProtectedFilePath(String originalPath) {
    final dir = path.dirname(originalPath);
    final name = path.basenameWithoutExtension(originalPath);
    final ext = path.extension(originalPath);
    return path.join(dir, '$name$ext.protected');
  }

  /// Simple file protection by copying with .protected extension
  /// In a production environment, implement proper encryption here
  static Future<bool> protectFile(
    String inputFilePath,
    String outputFilePath,
    String password,
  ) async {
    try {
      final inputFile = File(inputFilePath);
      if (!await inputFile.exists()) {
        throw Exception('Input file does not exist: $inputFilePath');
      }

      // For now, just copy the file with .protected extension
      // TODO: Implement proper encryption when encryption packages are stable
      await inputFile.copy(outputFilePath);
      
      return true;
    } catch (e) {
      print('Error protecting file: $e');
      return false;
    }
  }

  /// Simple file decryption by copying from .protected extension
  /// In a production environment, implement proper decryption here
  static Future<Uint8List?> decryptFile(
    String encryptedFilePath,
    String password,
  ) async {
    try {
      final encryptedFile = File(encryptedFilePath);
      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted file does not exist: $encryptedFilePath');
      }

      // For now, just read the file bytes
      // TODO: Implement proper decryption when encryption packages are stable
      return await encryptedFile.readAsBytes();
    } catch (e) {
      print('Error decrypting file: $e');
      return null;
    }
  }

  /// Creates a temporary decrypted file for processing
  static Future<String?> createTempDecryptedFile(
    String encryptedFilePath,
    String password,
  ) async {
    try {
      final decryptedBytes = await decryptFile(encryptedFilePath, password);
      if (decryptedBytes == null) return null;

      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_decrypted_${DateTime.now().millisecondsSinceEpoch}');
      await tempFile.writeAsBytes(decryptedBytes);
      
      return tempFile.path;
    } catch (e) {
      print('Error creating temp decrypted file: $e');
      return null;
    }
  }

  /// Cleans up temporary decrypted files
  static Future<void> cleanupTempFile(String tempFilePath) async {
    try {
      final tempFile = File(tempFilePath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      print('Error cleaning up temp file: $e');
    }
  }
}
