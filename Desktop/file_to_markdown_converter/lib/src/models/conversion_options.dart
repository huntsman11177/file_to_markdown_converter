/// Cross-format conversion options.
/// Keep defaults conservative; callers can opt-in to smarter heuristics.
class ConversionOptions {
  /// CSV/Excel row limit; for PDF use [maxPages].
  final int? maxRows;

  /// PDF page limit.
  final int? maxPages;

  /// Include the first row as headers (CSV/Excel). Defaults to true.
  final bool includeHeaders;

  /// If provided, selects columns by name (when headers are present) or by
  /// zero-based indices encoded as strings, e.g. ["0","3"].
  final List<String>? columnsToInclude;

  /// CSV delimiter (defaults to ','); supports ';' or '\t' etc.
  final String? delimiter;

  /// CSV line ending; default autodetected by parser.
  final String? eol;

  /// Optional per-column Markdown alignment (by column index).
  /// e.g. {0: ':---', 2: '---:'}
  final Map<int, String>? columnAlignments;

  /// PDF text formatting: when true, keep more layout signals.
  final bool preserveFormatting;

  /// When true, apply extra heading detection heuristics for PDF text.
  final bool detectHeadings;

  /// For multi-sheet Excel export headings.
  final bool includeSheetHeadings;

  /// Heading token for sheet titles (e.g., "##", "###").
  final String sheetHeadingPrefix;

  /// OCR output style: 'plain' | 'list' | 'code'
  final String ocrStyle;

  const ConversionOptions({
    this.maxRows,
    this.maxPages,
    this.includeHeaders = true,
    this.columnsToInclude,
    this.delimiter,
    this.eol,
    this.columnAlignments,
    this.preserveFormatting = false,
    this.detectHeadings = false,
    this.includeSheetHeadings = true,
    this.sheetHeadingPrefix = '##',
    this.ocrStyle = 'plain',
  });
}
