import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/conversion_result.dart';
import '../models/conversion_options.dart';

class OcrToMarkdownConverter {
  /// Converts an image file to Markdown text via ML Kit OCR.
  /// Use [script] to override script detection; defaults to latin.
  static Future<ConversionResult> convertImageToMarkdown(
    File imageFile, {
    ConversionOptions? options,
    TextRecognitionScript script = TextRecognitionScript.latin,
  }) async {
    try {
      options ??= const ConversionOptions();

      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(script: script);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final markdown = _formatRecognizedText(recognizedText, options.ocrStyle);

      if (markdown.trim().isEmpty) {
        return ConversionResult.error('No text recognized in image.');
      }

      return ConversionResult.success(
        markdown,
        metadata: {
          'type': 'ocr',
          'blocks': recognizedText.blocks.length,
          'style': options.ocrStyle,
          'script': script.name,
        },
      );
    } catch (e) {
      return ConversionResult.error('OCR failed: $e');
    }
  }

  /// Preserve blocks/lines for better readability; then render with style.
  static String _formatRecognizedText(RecognizedText text, String style) {
    final lines = <String>[];
    for (final block in text.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.isNotEmpty) lines.add(t);
      }
      // Add a blank line between blocks to hint paragraph breaks.
      lines.add('');
    }

    // Remove trailing empties.
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }

    final body = lines.join('\n');

    switch (style) {
      case 'code':
        return '```\n$body\n```';
      case 'list':
        return lines.map((l) => l.isEmpty ? '' : '- $l').join('\n');
      case 'plain':
      default:
        return body;
    }
  }
}
