/// Small non-cryptographic hashing used for result checksums, certificate
/// codes and the optional PIN. It detects accidental damage and casual
/// editing; it is not strong security (see the design, section 8).
library;

import 'dart:convert';

/// 64-bit FNV-1a (two independent 32-bit lanes, so it behaves the same on
/// every platform), as 16 hex characters.
String fnv64Hex(String input) {
  var a = 0x811c9dc5;
  var b = 0x9747b28c;
  for (final byte in utf8.encode(input)) {
    a = ((a ^ byte) * 0x01000193) & 0xFFFFFFFF;
    b = ((b ^ byte) * 0x01000193 + 0x7f4a7c15) & 0xFFFFFFFF;
  }
  return a.toRadixString(16).padLeft(8, '0') +
      b.toRadixString(16).padLeft(8, '0');
}

/// Salted, repeated hash for a PIN.
String pinHash(String salt, String pin) {
  var h = '$salt:$pin';
  for (var i = 0; i < 2000; i++) {
    h = fnv64Hex('$salt|$i|$h');
  }
  return h;
}
