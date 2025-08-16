# file\_to\_markdown\_converter

A **Dart/Flutter package** to convert **PDFs, CSVs, Excel, and Images (via OCR)** into Markdown format.

This package is ideal for building cross-platform apps that need lightweight text extraction, document digitization, and easy data sharing.

-----

## 🚀 Features

  - 📄 **PDF to Markdown**: Extracts text, detects headings, and supports **password-protected PDFs**.
  - 📊 **CSV to Markdown**: Generates clean Markdown tables with options for column filtering and row limits.
  - 📑 **Excel (XLS/XLSX) to Markdown**:
      - Convert single sheets or **all sheets**.
      - Include/exclude headers and specific columns.
      - *(Note: password-protected Excel files are not supported due to a limitation of the underlying Excel package.)*
  - 🖼 **Image OCR to Markdown**:
      - Extracts text from images (JPG, PNG, etc.) using **Google ML Kit**.
      - Perfect for digitizing receipts, cash slips, or handwritten notes.
  - 🔗 **Flutter-ready**: Can be integrated directly into your mobile, desktop, and web applications.

-----

## 📦 Installation

Add this to your `pubspec.yaml` file:

```yaml
dependencies:
  file_to_markdown_converter:
    path: ../file_to_markdown_converter
```

-----

## 📖 Usage

### Converting a PDF

To convert a PDF, you can use the `convertFile` method. It accepts an optional `password` parameter for protected files.

```dart
import 'package:file_to_markdown_converter/file_to_markdown_converter.dart';

final result = await FileToMarkdownConverter.convertFile(
  'example.pdf',
  password: 'my_secret_password', // Optional, if PDF is protected
);

if (result.success) {
  print(result.markdown);
} else {
  print('Error: ${result.errorMessage}');
}
```

### Converting a CSV

The `CsvToMarkdownConverter` creates a formatted Markdown table from a CSV file.

```dart
import 'package:file_to_markdown_converter/file_to_markdown_converter.dart';

final result = await CsvToMarkdownConverter.convertFile(
  'data.csv',
);

if (result.success) {
  print(result.markdown);
}
```

### Converting Excel Sheets

You can convert either a single sheet or all sheets from an Excel file.

#### Single Sheet

Use the `sheetName` parameter to specify a particular sheet.

```dart
final result = await ExcelToMarkdownConverter.convertFile(
  'spreadsheet.xlsx',
  sheetName: 'Sheet1', // Optional
);

if (result.success) {
  print(result.markdown);
}
```

#### All Sheets

This method converts every sheet in the workbook.

```dart
final result = await ExcelToMarkdownConverter.convertAllSheets(
  'spreadsheet.xlsx',
);

if (result.success) {
  print(result.markdown);
}
```

### OCR from an Image

Use the `OcrToMarkdownConverter` to extract text from an image file. This is great for digitizing physical documents.

```dart
import 'dart:io';
import 'package:file_to_markdown_converter/file_to_markdown_converter.dart';

final imageFile = File('receipt.jpg');
final ocrResult = await OcrToMarkdownConverter.convertImageToMarkdown(imageFile);

if (ocrResult.success) {
  print(ocrResult.markdown);
}
```

-----

## ⚙️ Advanced Usage: Optional Parameters

Many of the conversion methods offer optional parameters to fine-tune the output.

### `convertFile()` (PDF)

You can customize PDF conversion by controlling heading detection and image handling.

```dart
final advancedPdfResult = await FileToMarkdownConverter.convertFile(
  'document.pdf',
  // Optional parameters
  detectHeadings: true, // Attempt to format detected headings
  includeImages: false, // Exclude images from the output
);
```

### `convertFile()` (CSV & Excel)

Control the number of rows and columns, and whether to include headers.

```dart
// CSV and Excel conversions
final advancedCsvResult = await CsvToMarkdownConverter.convertFile(
  'large_dataset.csv',
  // Optional parameters
  maxRows: 10, // Limit the number of rows to 10
  includeHeaders: false, // Exclude the header row
  columns: ['email', 'username'], // Only include these columns
);
```

-----

## ⚠️ Notes & Limitations

  - **Password-protected PDFs** are supported, but **password-protected Excel files are not** (a limitation of the current Excel package).
  - OCR quality depends on image clarity and supported languages (currently Latin-based scripts).

-----

## 📜 License

See the `LICENSE` file for details.