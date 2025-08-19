# Changelog

## [1.1.4] 

### Added
- **Password Protection Support**: Added comprehensive password protection functionality for files
- **File Encryption**: New `protectFile()` method to encrypt files with passwords
- **Password-Protected Excel Support**: Enhanced Excel converter to handle password-protected files
- **New Dependencies**: Added `spreadsheet_decoder`, `crypto`, and `encrypt` packages for enhanced functionality

### Changed
- **Excel Converter**: Replaced `excel` package with `spreadsheet_decoder` for better password support
- **Package Structure**: Updated dependencies to avoid version conflicts
- **API Enhancement**: All conversion methods now support optional password parameters

### Features
- **Password-Protected File Conversion**: Convert encrypted files by providing passwords
- **File Security**: Encrypt sensitive files with password protection
- **Excel Password Support**: Handle both native Excel password protection and custom encryption
- **Temporary File Management**: Automatic cleanup of decrypted temporary files

### Technical Improvements
- **Better Error Handling**: Improved password-related error messages
- **Metadata Enhancement**: Added password protection status to conversion results
- **Cross-Platform**: Enhanced compatibility across Flutter, Dart, and web platforms

### Breaking Changes
- **Excel Package**: Changed from `excel` to `spreadsheet_decoder` package
- **Dependency Updates**: Some package versions updated for compatibility

### Migration Guide
- Update any direct usage of `excel` package to use the new converter methods
- Password parameters are now optional and backward compatible
- New `protectFile()` method available for file encryption needs
  
