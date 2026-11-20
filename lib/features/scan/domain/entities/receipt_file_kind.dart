/// What kind of file the user chose for a receipt.
enum ReceiptFileKind {
  /// A PDF. Its first page is turned into an image before it is read.
  pdf,

  /// A photo or screenshot the phone can read.
  image,

  /// Anything else, which cannot be read as a receipt.
  unknown;

  /// How much of the start of a file is needed to tell what it is. The PDF
  /// standard allows its header anywhere in the first 1024 bytes.
  static const headBytes = 1024;

  /// What the file is, from its first [headBytes] bytes.
  ///
  /// The name is not used. A file copied from the Files app, Drive or an email
  /// can have no extension or a wrong one, but its first bytes always say what
  /// it is.
  static ReceiptFileKind detect(List<int> head) {
    if (_containsPdfHeader(head)) return pdf;
    if (_isJpeg(head) || _isPng(head) || _isWebp(head) || _isHeif(head)) {
      return image;
    }
    return unknown;
  }

  static bool _startsWith(List<int> bytes, List<int> prefix, [int at = 0]) {
    if (bytes.length < at + prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[at + i] != prefix[i]) return false;
    }
    return true;
  }

  /// "%PDF-" in the first 1024 bytes.
  static bool _containsPdfHeader(List<int> head) {
    const header = [0x25, 0x50, 0x44, 0x46, 0x2D];
    final end = head.length < headBytes ? head.length : headBytes;
    for (var i = 0; i + header.length <= end; i++) {
      if (_startsWith(head, header, i)) return true;
    }
    return false;
  }

  static bool _isJpeg(List<int> head) => _startsWith(head, [0xFF, 0xD8, 0xFF]);

  static bool _isPng(List<int> head) =>
      _startsWith(head, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  /// "RIFF", four size bytes, then "WEBP".
  static bool _isWebp(List<int> head) =>
      _startsWith(head, [0x52, 0x49, 0x46, 0x46]) &&
      _startsWith(head, [0x57, 0x45, 0x42, 0x50], 8);

  /// HEIC and HEIF photos, common from newer phones: "ftyp" at byte 4, then a
  /// brand.
  static bool _isHeif(List<int> head) {
    if (!_startsWith(head, [0x66, 0x74, 0x79, 0x70], 4)) return false;
    if (head.length < 12) return false;
    final brand = String.fromCharCodes(head.sublist(8, 12));
    return const {
      'heic',
      'heix',
      'hevc',
      'hevx',
      'heim',
      'heis',
      'mif1',
      'msf1',
    }.contains(brand);
  }
}
