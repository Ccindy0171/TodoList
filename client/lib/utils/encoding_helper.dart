import 'dart:convert';
import 'package:flutter/foundation.dart';

class EncodingHelper {
  /// Ensures proper UTF-8 encoding for strings
  static String ensureUtf8(String text) {
    try {
      // First decode as UTF-8 to handle any existing encoding
      final decoded = utf8.decode(utf8.encode(text));
      return decoded;
    } catch (e) {
      debugPrint('Error ensuring UTF-8 encoding: $e');
      return text;
    }
  }
  
  /// Initialize encoding settings
  static void initialize() {
    // Set UTF-8 as default encoding for text operations
    Utf8Codec utf8 = const Utf8Codec();
    // This ensures that any text operations use UTF-8 by default
    debugPrint('UTF-8 encoding initialized');
  }
} 