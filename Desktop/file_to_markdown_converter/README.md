# File to Markdown Converter

A comprehensive Flutter/Dart library to convert CSV, Excel, PDF, and images (via OCR) into Markdown format with **password protection support**.

## 🚀 Features

- **🗂️ CSV to Markdown**: Convert CSV files with customizable delimiters and column selection
- **📊 Excel to Markdown**: Convert Excel files (.xlsx, .xls) with multi-sheet support and password protection
- **📄 PDF to Markdown**: Extract text from PDFs with heading detection and password support
- **🖼️ OCR Support**: Convert images to text using Google ML Kit with multiple output styles
- **🔐 Password Protection**: Encrypt/decrypt files with AES encryption
- **⚙️ Flexible Options**: Extensive customization options for all converters
- **🌐 Cross-Platform**: Works on Flutter, Dart, and web platforms

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  file_to_markdown_converter: ^1.1.1
```

Then run:
```bash
flutter pub get
```

## 🎯 Quick Start

```dart
import 'package:file_to_markdown_converter/file_to_markdown_converter.dart';

// Convert any supported file
final result = await FileToMarkdownConverter.convertFile('document.pdf');
if (result.success) {
  print(result.markdown);
} else {
  print('Error: ${result.error}');
}
```

---

## 📚 Complete API Documentation

### 🏠 Main Converter Class

#### `FileToMarkdownConverter.convertFile()`

**Purpose**: Universal file converter that automatically detects file type and converts to Markdown.

**Syntax**:
```dart
static Future<ConversionResult> convertFile(
  String filePath, {
  ConversionOptions? options,
  String? sheetName,        // Excel only
  String? password,         // PDF and Excel
})
```

**Parameters**:
- `filePath` (String): Path to the file to convert
- `options` (ConversionOptions?): Optional conversion settings
- `sheetName` (String?): Specific Excel sheet name (Excel files only)
- `password` (String?): Password for protected files

**Examples**:
```dart
// Basic conversion
final result = await FileToMarkdownConverter.convertFile('data.csv');

// Excel with specific sheet
final result = await FileToMarkdownConverter.convertFile(
  'workbook.xlsx',
  sheetName: 'Sales Data',
);

// Password-protected PDF
final result = await FileToMarkdownConverter.convertFile(
  'report.pdf',
  password: 'secret123',
);

// With custom options
final result = await FileToMarkdownConverter.convertFile(
  'data.csv',
  options: ConversionOptions(
    maxRows: 100,
    includeHeaders: true,
    columnsToInclude: ['Name', 'Email', 'Phone'],
  ),
);
```

#### `FileToMarkdownConverter.convertBytes()`

**Purpose**: Convert file content from bytes (useful for web uploads or in-memory processing).

**Syntax**:
```dart
static ConversionResult convertBytes(
  Uint8List bytes,
  String fileType, {
  ConversionOptions? options,
  String? sheetName,
  String? password,
})
```

**Examples**:
```dart
import 'dart:typed_data';

// From file upload
final bytes = await uploadedFile.readAsBytes();
final result = FileToMarkdownConverter.convertBytes(
  bytes,
  'xlsx',
  sheetName: 'Data',
);

// CSV from network
final response = await http.get(csvUrl);
final result = FileToMarkdownConverter.convertBytes(
  response.bodyBytes,
  'csv',
  options: ConversionOptions(delimiter: ';'),
);
```

### 🔐 Password Protection Functions

#### `FileToMarkdownConverter.protectFile()`

**Purpose**: Encrypt a file with password protection.

**Syntax**:
```dart
static Future<bool> protectFile(
  String inputFilePath,
  String password, {
  String? outputFilePath,
})
```

**Examples**:
```dart
// Protect with auto-generated name (adds .protected extension)
final success = await FileToMarkdownConverter.protectFile(
  'sensitive.xlsx',
  'myPassword123',
);

// Protect with custom output path
final success = await FileToMarkdownConverter.protectFile(
  'document.pdf',
  'strongPassword',
  outputFilePath: 'encrypted_document.pdf.protected',
);

if (success) {
  print('File protected successfully!');
} else {
  print('Protection failed');
}
```

#### `FileToMarkdownConverter.decryptFile()`

**Purpose**: Decrypt a password-protected file and return its content as bytes.

**Syntax**:
```dart
static Future<Uint8List?> decryptFile(
  String encryptedFilePath,
  String password,
)
```

**Examples**:
```dart
// Decrypt file
final decryptedBytes = await FileToMarkdownConverter.decryptFile(
  'document.pdf.protected',
  'myPassword123',
);

if (decryptedBytes != null) {
  // Save decrypted content
  await File('decrypted_document.pdf').writeAsBytes(decryptedBytes);
} else {
  print('Decryption failed - wrong password or corrupted file');
}
```

#### `FileToMarkdownConverter.isPasswordProtected()`

**Purpose**: Check if a file is password-protected (encrypted by this library).

**Syntax**:
```dart
static bool isPasswordProtected(String filePath)
```

**Examples**:
```dart
final files = ['data.csv', 'secret.xlsx.protected', 'report.pdf'];

for (final file in files) {
  if (FileToMarkdownConverter.isPasswordProtected(file)) {
    print('🔒 $file is encrypted');
    // Handle password-protected file
  } else {
    print('📄 $file is not encrypted');
    // Handle regular file
  }
}
```

---

## 📊 Specialized Converters

### 📈 Excel Converter

#### `ExcelToMarkdownConverter.convertFile()`

**Purpose**: Convert Excel files with advanced options and password support.

**Examples**:
```dart
// Basic Excel conversion
final result = await ExcelToMarkdownConverter.convertFile('data.xlsx');

// Specific sheet with password
final result = await ExcelToMarkdownConverter.convertFile(
  'protected.xlsx',
  sheetName: 'Q4 Sales',
  password: 'excel123',
);

// With detailed options
final result = await ExcelToMarkdownConverter.convertFile(
  'report.xlsx',
  options: ConversionOptions(
    maxRows: 50,
    columnsToInclude: ['Product', 'Revenue', 'Profit'],
    columnAlignments: {0: ':---', 1: '---:', 2: '---:'},
    includeHeaders: true,
  ),
);
```

#### `ExcelToMarkdownConverter.convertAllSheets()`

**Purpose**: Convert all sheets in an Excel workbook to a single Markdown document.

**Examples**:
```dart
// Convert all sheets with headings
final result = await ExcelToMarkdownConverter.convertAllSheets(
  'workbook.xlsx',
  options: ConversionOptions(
    includeSheetHeadings: true,
    sheetHeadingPrefix: '## ',
    maxRows: 100,
  ),
);

// Password-protected workbook
final result = await ExcelToMarkdownConverter.convertAllSheets(
  'protected_workbook.xlsx',
  password: 'workbook123',
  options: ConversionOptions(
    includeSheetHeadings: true,
    sheetHeadingPrefix: '### ',
  ),
);

if (result.success) {
  print('Converted ${result.metadata?['sheets']} sheets');
  print('Available sheets: ${result.metadata?['sheets']}');
}
```

### 📄 PDF Converter

#### `PdfToMarkdownConverter.convertFile()`

**Purpose**: Extract text from PDF files with advanced formatting options.

**Examples**:
```dart
// Basic PDF conversion
final result = await PdfToMarkdownConverter.convertFile('document.pdf');

// Password-protected PDF with heading detection
final result = await PdfToMarkdownConverter.convertFile(
  'protected.pdf',
  password: 'pdf123',
  options: ConversionOptions(
    detectHeadings: true,
    preserveFormatting: true,
    maxPages: 10,
  ),
);

// Simple text extraction
final result = await PdfToMarkdownConverter.convertFile(
  'report.pdf',
  options: ConversionOptions(
    preserveFormatting: false,
    detectHeadings: false,
  ),
);
```

### 📄 CSV Converter

#### `CsvToMarkdownConverter.convertFile()`

**Purpose**: Convert CSV files to Markdown tables with customizable options.

**Examples**:
```dart
// Basic CSV conversion
final result = await CsvToMarkdownConverter.convertFile('data.csv');

// Custom delimiter and column selection
final result = await CsvToMarkdownConverter.convertFile(
  'data.csv',
  options: ConversionOptions(
    delimiter: ';',
    maxRows: 50,
    columnsToInclude: ['Name', 'Email', 'Phone'],
    columnAlignments: {0: ':---', 1: ':---:', 2: '---:'},
  ),
);

// Without headers
final result = await CsvToMarkdownConverter.convertFile(
  'raw_data.csv',
  options: ConversionOptions(
    includeHeaders: false,
    delimiter: '\t', // Tab-separated
  ),
);
```

#### `CsvToMarkdownConverter.convertString()`

**Purpose**: Convert CSV content from a string.

**Examples**:
```dart
// CSV content as string
final csvContent = '''
Name,Age,City
John,25,New York
Jane,30,London
''';

final result = CsvToMarkdownConverter.convertString(
  csvContent,
  options: ConversionOptions(
    columnAlignments: {0: ':---', 1: '---:', 2: ':---:'},
  ),
);

// From network or API
final response = await http.get(csvApiUrl);
final result = CsvToMarkdownConverter.convertString(response.body);
```

### 🖼️ OCR Converter

#### `OcrToMarkdownConverter.convertImageToMarkdown()`

**Purpose**: Extract text from images using Google ML Kit OCR.

**Examples**:
```dart
import 'dart:io';

// Basic image OCR
final imageFile = File('receipt.jpg');
final result = await OcrToMarkdownConverter.convertImageToMarkdown(imageFile);

// With different output styles
final result = await OcrToMarkdownConverter.convertImageToMarkdown(
  File('document.png'),
  options: ConversionOptions(ocrStyle: 'list'), // 'plain', 'list', or 'code'
);

// Different language script
final result = await OcrToMarkdownConverter.convertImageToMarkdown(
  File('chinese_text.jpg'),
  script: TextRecognitionScript.chinese,
);

// Code formatting for screenshots
final result = await OcrToMarkdownConverter.convertImageToMarkdown(
  File('code_screenshot.png'),
  options: ConversionOptions(ocrStyle: 'code'),
);
```

---

## ⚙️ Conversion Options Reference

The `ConversionOptions` class provides extensive customization for all converters:

```dart
final options = ConversionOptions(
  // Row/Page Limits
  maxRows: 100,              // Limit rows for CSV/Excel
  maxPages: 5,               // Limit pages for PDF
  
  // Table Structure
  includeHeaders: true,      // Include first row as headers
  includeSheetHeadings: true, // Include sheet names in multi-sheet Excel
  sheetHeadingPrefix: '## ',  // Markdown prefix for sheet headings
  
  // Column Selection
  columnsToInclude: ['Name', 'Email'], // By name (if headers exist)
  columnsToInclude: ['0', '2', '4'],   // By index (0-based)
  
  // Column Alignment
  columnAlignments: {
    0: ':---',    // Left align
    1: ':---:',   // Center align
    2: '---:',    // Right align
  },
  
  // CSV Specific
  delimiter: ',',            // Field separator
  eol: '\n',                // Line ending
  
  // PDF Specific
  preserveFormatting: true,  // Keep layout hints
  detectHeadings: true,      // Auto-detect headings
  
  // OCR Specific
  ocrStyle: 'plain',         // 'plain', 'list', or 'code'
);
```

### Column Selection Examples

```dart
// Select specific columns by name (requires headers)
final options = ConversionOptions(
  columnsToInclude: ['Product Name', 'Price', 'Stock'],
);

// Select columns by index (0-based)
final options = ConversionOptions(
  columnsToInclude: ['0', '3', '5'], // First, fourth, and sixth columns
);

// Mixed selection (if headers exist, names take precedence)
final options = ConversionOptions(
  columnsToInclude: ['Name', '2', 'Email'], // Name column, third column, Email column
);
```

### Table Alignment Examples

```dart
final options = ConversionOptions(
  columnAlignments: {
    0: ':---',    // Left-align first column
    1: ':---:',   // Center-align second column
    2: '---:',    // Right-align third column
  },
);
```

---

## 📋 Result Handling

### ConversionResult Properties

```dart
class ConversionResult {
  final bool success;                    // Conversion success status
  final String markdown;                 // Generated Markdown content
  final String? error;                   // Error message if failed
  final Map<String, dynamic>? metadata;  // Additional information
}
```

### Metadata Examples

Different converters provide specific metadata:

```dart
// Excel metadata
{
  'type': 'excel',
  'sheetName': 'Sheet1',
  'columns': 5,
  'maxRows': 100,
  'availableSheets': ['Sheet1', 'Sheet2'],
  'isPasswordProtected': true,
}

// PDF metadata
{
  'type': 'pdf',
  'pageCount': 10,
  'processedPages': 5,
  'passwordProtected': true,
}

// CSV metadata
{
  'type': 'csv',
  'rows': 250,
  'columns': 8,
  'delimiter': ',',
}

// OCR metadata
{
  'type': 'ocr',
  'blocks': 15,
  'style': 'plain',
  'script': 'latin',
}
```

---

## 🔧 Error Handling & Troubleshooting

### Common Error Patterns

```dart
final result = await FileToMarkdownConverter.convertFile('document.pdf');

if (!result.success) {
  final error = result.error!;
  
  // Password errors
  if (error.contains('password') || error.contains('Password')) {
    print('Password required or incorrect');
    // Prompt user for password
  }
  
  // File not found
  else if (error.contains('not found')) {
    print('File does not exist');
    // Check file path
  }
  
  // Sheet not found (Excel)
  else if (error.contains('Sheet') && error.contains('not found')) {
    print('Excel sheet does not exist');
    print('Available sheets: ${result.metadata?['availableSheets']}');
  }
  
  // Empty file
  else if (error.contains('empty')) {
    print('File has no content');
  }
  
  // Unsupported format
  else if (error.contains('Unsupported')) {
    print('File format not supported');
  }
  
  else {
    print('Unexpected error: $error');
  }
}
```

### Exception Handling

```dart
try {
  final result = await FileToMarkdownConverter.convertFile('document.pdf');
  
  if (result.success) {
    print('Conversion successful!');
    print('Generated ${result.markdown.length} characters of Markdown');
  } else {
    print('Conversion failed: ${result.error}');
  }
  
} catch (e) {
  print('Unexpected exception: $e');
  // Handle file system errors, network issues, etc.
}
```

### Performance Tips

```dart
// Limit processing for large files
final options = ConversionOptions(
  maxRows: 1000,    // Limit Excel/CSV rows
  maxPages: 10,     // Limit PDF pages
);

// Use bytes conversion for better memory management
final bytes = await file.readAsBytes();
final result = FileToMarkdownConverter.convertBytes(bytes, 'csv');
```

---

## 🔐 Security & Password Features

### Password Support by File Type

| File Type | Native Password Support | Custom Encryption |
|-----------|------------------------|-------------------|
| **PDF** | ✅ Full support | ✅ Available |
| **Excel** | ⚠️ Limited support | ✅ Available |
| **CSV** | ❌ Not applicable | ✅ Available |
| **Images** | ❌ Not applicable | ✅ Available |

### Security Best Practices

```dart
// 1. Use strong passwords
final success = await FileToMarkdownConverter.protectFile(
  'sensitive.xlsx',
  'MyStr0ng!P@ssw0rd2024', // Strong password
);

// 2. Handle passwords securely
String? getPassword() {
  // Get password from secure input, environment variables, or key management
  return Platform.environment['FILE_PASSWORD'];
}

// 3. Clean up temporary data
final result = await FileToMarkdownConverter.convertFile(
  'protected.xlsx',
  password: getPassword(),
);
// Password automatically cleared from memory after use

// 4. Check file protection status
if (FileToMarkdownConverter.isPasswordProtected('file.xlsx')) {
  // Handle as sensitive file
}
```

---

## 🎨 Advanced Usage Examples

### Batch Processing

```dart
Future<void> convertMultipleFiles(List<String> filePaths) async {
  final results = <String, ConversionResult>{};
  
  for (final filePath in filePaths) {
    print('Converting $filePath...');
    final result = await FileToMarkdownConverter.convertFile(filePath);
    results[filePath] = result;
    
    if (result.success) {
      print('✅ Success: ${result.markdown.length} chars');
    } else {
      print('❌ Failed: ${result.error}');
    }
  }
  
  return results;
}
```

### Web File Upload Integration

```dart
// Flutter Web file picker integration
import 'package:file_picker/file_picker.dart';

Future<void> handleFileUpload() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'xlsx', 'xls', 'csv'],
  );
  
  if (result != null && result.files.single.bytes != null) {
    final bytes = result.files.single.bytes!;
    final fileName = result.files.single.name;
    final extension = fileName.split('.').last;
    
    final conversion = FileToMarkdownConverter.convertBytes(bytes, extension);
    
    if (conversion.success) {
      print('Converted: ${conversion.markdown}');
    }
  }
}
```

### Progress Tracking for Large Files

```dart
Future<ConversionResult> convertWithProgress(String filePath) async {
  print('Starting conversion of $filePath...');
  
  // Check file size
  final file = File(filePath);
  final size = await file.length();
  print('File size: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
  
  if (size > 10 * 1024 * 1024) { // 10MB
    print('Large file detected, using row/page limits...');
    final options = ConversionOptions(
      maxRows: 1000,
      maxPages: 50,
    );
    return await FileToMarkdownConverter.convertFile(filePath, options: options);
  }
  
  return await FileToMarkdownConverter.convertFile(filePath);
}
```

---

## 📦 Dependencies & Compatibility

### Package Dependencies

```yaml
dependencies:
  # Core packages
  csv: ^6.0.0                           # CSV parsing
  spreadsheet_decoder: ^2.1.0           # Excel processing
  syncfusion_flutter_pdf: ^30.2.5       # PDF text extraction
  google_mlkit_text_recognition: ^0.15.0 # OCR functionality
  
  # Security packages
  crypto: ^3.0.3                        # Cryptographic functions
  encrypt: ^5.0.3                       # File encryption
  
  # Utility packages
  path: ^1.9.1                          # Path manipulation
  meta: ^1.16.0                         # Annotations
  archive: ^3.6.1                       # Archive support
```

### Platform Support

| Platform | CSV | Excel | PDF | OCR | Encryption |
|----------|-----|-------|-----|-----|-----------|
| **Android** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **iOS** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Web** | ✅ | ✅ | ✅ | ❌* | ✅ |
| **Windows** | ✅ | ✅ | ✅ | ❌* | ✅ |
| **macOS** | ✅ | ✅ | ✅ | ❌* | ✅ |
| **Linux** | ✅ | ✅ | ✅ | ❌* | ✅ |

*OCR requires camera/ML Kit which is mobile-only

### Version Requirements

- **Dart SDK**: >=3.0.0 <4.0.0
- **Flutter**: >=3.0.0
- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 11.0+

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/your-username/file_to_markdown_converter.git

# Install dependencies
cd file_to_markdown_converter
flutter pub get

# Run tests
flutter test

# Run example
cd example
flutter run
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🆘 Support

- **Documentation**: This README
- **Issues**: [GitHub Issues](https://github.com/hunstman11177/file_to_markdown_converter/issues)
- **Discussions**: [GitHub Discussions](https://github.com/hunstman11177/file_to_markdown_converter/discussions)

---

*Made with ❤️ by the Flutter community*