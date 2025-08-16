class ConversionResult {
  final bool success;
  final String markdown;
  final String? error;
  final Map<String, dynamic>? metadata;

  const ConversionResult._({
    required this.success,
    required this.markdown,
    this.error,
    this.metadata,
  });

  factory ConversionResult.success(
    String markdown, {
    Map<String, dynamic>? metadata,
  }) =>
      ConversionResult._(
        success: true,
        markdown: markdown,
        metadata: metadata,
        error: null,
      );

  factory ConversionResult.error(String message, {Map<String, dynamic>? metadata}) =>
      ConversionResult._(
        success: false,
        markdown: '',
        error: message,
        metadata: metadata,
      );
}
