import 'package:passport_mrz_capture/src/models/passport_mrz_parsed_data.dart';

class MRZParser {
  /// Parses the recognized text to extract TD3 MRZ lines and populate the data model.
  static PassportMrzParsedData? parse(String text) {
    try {
      final pair = _selectTd3Pair(text, _isCriticalTd3Valid);
      if (pair == null) return null;
      return _buildFromTd3Lines(pair.$1, pair.$2);
    } catch (_) {
      return null;
    }
  }

  /// OCR path: accepts TD3 lines without ICAO checksum validation.
  static PassportMrzParsedData? parseForOcr(String text) {
    try {
      final pair = _selectTd3Pair(text, _isTd3StructurallyValid);
      if (pair == null) return null;
      return _buildFromTd3Lines(pair.$1, pair.$2);
    } catch (_) {
      return null;
    }
  }

  static (String, String)? _selectTd3Pair(
    String text,
    bool Function(String line2) line2Valid,
  ) {
    final pairs = _extractTd3Candidates(text);
    for (final pair in pairs) {
      for (final variant in _withKAsFillerVariants(pair.$1, pair.$2)) {
        final l1 = _finalizeTd3Line1(variant.$1);
        final l2 = _correctMrzLine2(variant.$2);
        if (line2Valid(l2)) return (l1, l2);
      }
    }
    return null;
  }

  /// Try original pair first, then conservative K->< filler normalization.
  static List<(String, String)> _withKAsFillerVariants(String line1, String line2) {
    final v1 = (_replaceLikelyFillerKLine1(line1), _replaceLikelyFillerKLine2(line2));
    final hasLikelyFillerK = line2.length == 44 && line2.substring(28, 42).contains('KK');
    if (v1 == (line1, line2)) return [(line1, line2)];
    if (hasLikelyFillerK) return [v1, (line1, line2)];
    return [(line1, line2), v1];
  }

  /// For TD3 line 1, normalize document prefix and filler tail OCR noise.
  static String _replaceLikelyFillerKLine1(String line) {
    return _normalizeTd3Line1Ocr(line);
  }

  static String _finalizeTd3Line1(String line) {
    var base = _normalizeTd3Line1Ocr(line);
    if (base.length > 44) {
      base = base.substring(0, 44);
    } else if (base.length < 44) {
      base = base.padRight(44, '<');
    }
    return base;
  }

  /// Fixes P< prefix, extra `<<` before fillers, and K/C/e misreads in filler zones.
  static String _normalizeTd3Line1Ocr(String line) {
    var out = line.toUpperCase();
    if (out.startsWith('PS') && out.length > 2) {
      out = 'P<${out.substring(2)}';
    } else if (out.startsWith('PK') && out.length > 2) {
      out = 'P<${out.substring(2)}';
    }

    final parts = out.split('<<');
    if (parts.length <= 1) return out;

    final head = parts.first;
    // Avoid breaking fragmented OCR like P<IND<<ASMA (head too short).
    if (head.length < 8 || !RegExp(r'^P[<?][A-Z]{3}').hasMatch(head)) {
      return out;
    }

    final names = parts[1];

    if (parts.length == 2) {
      final split = _splitNameAndFillerTail(names);
      return '$head<<${split.$1}${_ocrCharsToFiller(split.$2)}';
    }

    // Extra `<<` before filler tail (e.g. XYSTUS<<KCCe) — merge tail parts only.
    final fillerOcr = parts.sublist(2).join();
    return '$head<<$names${_ocrCharsToFiller(fillerOcr)}';
  }

  /// Splits given-name segment from trailing OCR filler garbage (e.g. KCCe).
  static (String, String) _splitNameAndFillerTail(String names) {
    var lastLetter = -1;
    for (var i = 0; i < names.length; i++) {
      if (RegExp(r'[A-Z]').hasMatch(names[i])) lastLetter = i;
    }
    if (lastLetter < 0) return (names, '');
    final namePart = names.substring(0, lastLetter + 1);
    final tail = names.substring(lastLetter + 1);
    if (tail.isEmpty || !_looksLikeOcrFillerTail(tail)) {
      return (names, '');
    }
    return (namePart, tail);
  }

  static bool _looksLikeOcrFillerTail(String tail) {
    if (tail.isEmpty) return false;
    if (tail.contains('<')) return true;
    final letterCount = RegExp(r'[A-Z]').allMatches(tail).length;
    return letterCount <= 1;
  }

  /// In filler-only segments, map OCR noise to `<` (K/C/e etc. are not real name letters).
  static String _ocrCharsToFiller(String s) {
    if (s.isEmpty) return '';
    return s.split('').map((c) => c == '<' ? '<' : '<').join();
  }

  /// For TD3 line 2, K/e often appear in personal-number filler (28..41).
  static String _replaceLikelyFillerKLine2(String line) {
    if (line.length != 44) return line;
    final prefix = line.substring(0, 28);
    var personal = line.substring(28, 42).replaceAll('K', '<');
    personal = personal.replaceAllMapped(
      RegExp(r'[CE]{2,}$'),
      (m) => '<' * m.group(0)!.length,
    );
    final suffix = line.substring(42).split('').map((c) {
      if (RegExp(r'[0-9]').hasMatch(c) || c == '<') return c;
      return '<';
    }).join();
    return prefix + personal + suffix;
  }

  static PassportMrzParsedData _buildFromTd3Lines(String line1, String line2) {
    // Line 1: P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<
    final issuingCountry = line1.substring(2, 5).replaceAll('<', '');

    final nameString =
        line1.substring(5).trim().replaceFirst(RegExp(r'^<+'), '');
    final nameParts = nameString
        .split('<<')
        .map((p) => _fixNameLetters(p.replaceAll('<', ' ').trim()))
        .where((p) => p.isNotEmpty)
        .toList();
    final surname = nameParts.isNotEmpty ? nameParts.first : '';
    final givenNames =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final fullName = '$givenNames $surname'.trim();

    // Line 2: L898902C36UTO7408122F1204159ZE184226B<<<<<10
    final passportNumber = line2.substring(0, 9).replaceAll('<', '');
    final nationality = line2.substring(10, 13).replaceAll('<', '');

    final dobRaw = line2.substring(13, 19);
    final dateOfBirth = _formatDate(dobRaw);

    final genderRaw = line2.substring(20, 21);
    final gender = _parseGender(genderRaw);

    final expiryRaw = line2.substring(21, 27);
    final expiryDate = _formatDate(expiryRaw, isExpiry: true);

    final personalNumber = line2.substring(28, 42).replaceAll('<', '');

    return PassportMrzParsedData(
      fullName: fullName,
      surname: surname,
      givenNames: givenNames,
      passportNumber: passportNumber,
      issuingCountry: issuingCountry,
      nationality: nationality,
      dateOfBirth: dateOfBirth,
      expiryDate: expiryDate,
      gender: gender,
      personalNumber: personalNumber,
      mrzLine1: line1,
      mrzLine2: line2,
    );
  }

  ///ge place of birth from the passport
  static String extractPlaceOfBirth(String text) {
    final regex = RegExp(
      r'(?:Place|Pace)\s*o[a-zA-Z]?\s*Birth[\s\n:]*([A-Z,\s]+)',
      caseSensitive: false,
      multiLine: true,
    );

    final match = regex.firstMatch(text);

    if (match != null) {
      String value = match.group(1)?.trim() ?? '';

      // Keep only first valid line
      value = value.split('\n').first.trim();

      return value;
    }

    return '';
  }

  /// Extracts Surname from the VIZ (Visual Inspection Zone)
  static String extractSurnameVIZ(String text) {
    final regex = RegExp(
      r'(?:Surname|Nom|Last Name|Surname \/ Nom)[\s\n:]*([A-Z\s\-]+)',
      caseSensitive: false,
      multiLine: true,
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      String value = match.group(1)?.trim() ?? '';
      value = value.split('\n').first.trim();
      if (value.isNotEmpty && !value.contains('<')) {
        return value;
      }
    }
    return '';
  }

  /// Extracts Given Names from the VIZ
  static String extractGivenNamesVIZ(String text) {
    final regex = RegExp(
      r'(?:Given Names|Prenoms|Given Name|First Name|Given names \/ Prénoms|Given names\/Prénoms)[\s\n:]*([A-Z\s\-]+)',
      caseSensitive: false,
      multiLine: true,
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      String value = match.group(1)?.trim() ?? '';
      value = value.split('\n').first.trim();
      if (value.isNotEmpty && !value.contains('<')) {
        return value;
      }
    }
    return '';
  }

  /// Extracts Passport Number from the VIZ
  static String extractPassportNumberVIZ(String text) {
    final regex = RegExp(
      r'(?:Passport No|Passeport No|Passport Number|Document No|Passport No\. \/ Passeport N°)[\.\s\n:]*([A-Z0-9]+)',
      caseSensitive: false,
      multiLine: true,
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      String value = match.group(1)?.trim() ?? '';
      value = value.split('\n').first.trim();
      if (value.length >= 6 && !value.contains('<')) {
        return value;
      }
    }
    return '';
  }

  static String _formatDate(String raw, {bool isExpiry = false}) {
    if (raw.length != 6) return raw;
    String yearStr = raw.substring(0, 2);
    String month = raw.substring(2, 4);
    String day = raw.substring(4, 6);
    
    int year = int.tryParse(yearStr) ?? 0;
    int currentYear = DateTime.now().year % 100;
    
    int fullYear;
    if (isExpiry) {
      // Expiry is in the future or recent past
      fullYear = 2000 + year;
    } else {
      // DOB
      if (year > currentYear) {
        fullYear = 1900 + year;
      } else {
        fullYear = 2000 + year;
      }
    }
    
    return '$fullYear-$month-$day';
  }

  static String _parseGender(String g) {
    if (g == 'M') return 'Male';
    if (g == 'F') return 'Female';
    return 'Unspecified';
  }

  static List<(String, String)> _extractTd3Candidates(String text) {
    final raw = text
        .split('\n')
        .map(_sanitizeMrzLine)
        .where((l) => l.isNotEmpty)
        .toList();
    final mrzLike = raw.where((l) => l.length >= 20).toList();

    final candidates = <(String, String)>[];
    for (var i = 0; i + 1 < mrzLike.length; i++) {
      candidates.add((_as44(mrzLike[i]), _as44(mrzLike[i + 1])));
    }
    if (mrzLike.length >= 2) {
      candidates.add((_as44(mrzLike[mrzLike.length - 2]), _as44(mrzLike.last)));
    }

    // Handle OCR that merges both lines into one long line.
    for (final l in mrzLike) {
      if (l.length >= 88) {
        candidates.add((_as44(l.substring(0, 44)), _as44(l.substring(44, 88))));
      }
    }

    // Joined fallback for fragmented OCR lines.
    final joined = mrzLike.join();
    if (joined.length >= 88) {
      candidates.add((_as44(joined.substring(0, 44)), _as44(joined.substring(44, 88))));
    }

    candidates.addAll(_extractFragmentedTd3Pairs(raw));
    return candidates;
  }

  /// Short line 1 (P<…) + partial line 2, or both glued without 88 chars.
  static List<(String, String)> _extractFragmentedTd3Pairs(List<String> sanitizedLines) {
    final pairs = <(String, String)>[];

    final pLines = sanitizedLines.where((l) => l.startsWith('P<')).toList();
    final nonP = sanitizedLines.where((l) => !l.startsWith('P<')).toList();
    if (pLines.isNotEmpty && nonP.isNotEmpty) {
      final l1 = _as44(pLines.first);
      final l2 = _as44(nonP.join());
      pairs.add((l1, l2));
      pairs.add((l1, _correctMrzLine2(l2)));
    }

    final stream = sanitizedLines.join();
    if (!stream.startsWith('P<') || stream.length < 25) return pairs;

    final splitAt = _findLine2StartIndex(stream);
    if (splitAt != null && splitAt > 5) {
      final l1 = _as44(stream.substring(0, splitAt));
      final l2 = _as44(stream.substring(splitAt));
      pairs.add((l1, l2));
      pairs.add((l1, _correctMrzLine2(l2)));
    }

    if (stream.length >= 44) {
      final l1 = _as44(stream.substring(0, 44));
      final rest = stream.length > 44 ? stream.substring(44) : '';
      if (rest.isNotEmpty) {
        final l2 = _as44(rest);
        pairs.add((l1, l2));
        pairs.add((l1, _correctMrzLine2(l2)));
      }
    }

    return pairs;
  }

  /// After names (<<), line 2 starts with passport number (contains a digit).
  static int? _findLine2StartIndex(String s) {
    final re = RegExp(r'<<([A-Z0-9<]+)');
    int? best;
    for (final m in re.allMatches(s)) {
      final seg = m.group(1)!;
      if (seg.length >= 7 && RegExp(r'[0-9]').hasMatch(seg)) {
        best = m.start + 2;
      }
    }
    return best;
  }

  static String _sanitizeMrzLine(String line) {
    var s = line
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('«', '<')
        .replaceAll('‹', '<')
        .replaceAll('›', '<')
        .replaceAll('>', '<')
        .replaceAll(RegExp(r'[^A-Z0-9<]'), '');
    // Only normalize reasonably complete line-1 OCR (skip short fragments).
    if (s.startsWith('P') && s.length >= 25) {
      s = _normalizeTd3Line1Ocr(s);
    }
    return s;
  }

  static String _as44(String s) {
    if (s.length >= 44) return s.substring(0, 44);
    return s.padRight(44, '<');
  }

  static String _fixNumeric(String input) {
    return input
        .replaceAll('O', '0')
        .replaceAll('Q', '0')
        .replaceAll('U', '0')
        .replaceAll('D', '0')
        .replaceAll('I', '1')
        .replaceAll('L', '1')
        .replaceAll('Z', '2')
        .replaceAll('S', '5')
        .replaceAll('B', '8')
        .replaceAll('G', '6');
  }

  static String _correctMrzLine2(String line) {
    if (line.length != 44) return line;

    // Fix numeric-only fields
    String p1 = line.substring(0, 9);
    final p2 = _fixNumeric(line.substring(9, 10)); 
    final p3 = line.substring(10, 13);
    final p4 = _fixNumeric(line.substring(13, 20)); // DOB + Check digit
    final p5 = line.substring(20, 21);
    final p6 = _fixNumeric(line.substring(21, 28)); // Expiry + Check digit
    final p7 = line.substring(28); 
    
    // Try to correct passport number if its check digit exists and checksum fails
    if (RegExp(r'^[0-9]$').hasMatch(p2)) {
      final targetCheck = int.parse(p2);
      if (_icaoChecksum(p1) != targetCheck) {
        // Try replacing common alpha to numeric
        final alt1 = p1.replaceAll('O', '0');
        if (_icaoChecksum(alt1) == targetCheck) {
          p1 = alt1;
        } else {
          final alt2 = p1.replaceAll('I', '1');
          if (_icaoChecksum(alt2) == targetCheck) {
            p1 = alt2;
          } else {
            final alt3 = _fixNumeric(p1);
            if (_icaoChecksum(alt3) == targetCheck) {
              p1 = alt3;
            }
          }
        }
      }
    }
    
    return p1 + p2 + p3 + p4 + p5 + p6 + p7;
  }

  /// MRZ line 2 must pass format and ICAO check digits (no letter guessing on numbers/dates).
  static bool _isCriticalTd3Valid(String line2) {
    if (line2.length != 44) return false;
    final passport = line2.substring(0, 9);
    final passportCheck = line2.substring(9, 10);
    final dob = line2.substring(13, 19);
    final dobCheck = line2.substring(19, 20);
    final expiry = line2.substring(21, 27);
    final expiryCheck = line2.substring(27, 28);

    if (!RegExp(r'^[A-Z0-9<]{9}$').hasMatch(passport)) return false;
    if (!RegExp(r'^[0-9<]$').hasMatch(passportCheck)) return false;
    if (!RegExp(r'^[0-9]{6}$').hasMatch(dob)) return false;
    if (!RegExp(r'^[0-9]$').hasMatch(dobCheck)) return false;
    if (!RegExp(r'^[0-9]{6}$').hasMatch(expiry)) return false;
    if (!RegExp(r'^[0-9]$').hasMatch(expiryCheck)) return false;

    return _checksumMatches(passport, passportCheck) &&
        _checksumMatches(dob, dobCheck) &&
        _checksumMatches(expiry, expiryCheck);
  }

  /// OCR: line 2 shape only (no ICAO check digits).
  static bool _isTd3StructurallyValid(String line2) {
    if (line2.length != 44) return false;
    final passport = line2.substring(0, 9);
    final passportCheck = line2.substring(9, 10);
    final nationality = line2.substring(10, 13);
    final dob = line2.substring(13, 19);
    final dobCheck = line2.substring(19, 20);
    final gender = line2.substring(20, 21);
    final expiry = line2.substring(21, 27);
    final expiryCheck = line2.substring(27, 28);

    if (!RegExp(r'^[A-Z0-9<]{9}$').hasMatch(passport)) return false;
    if (!RegExp(r'^[0-9<]$').hasMatch(passportCheck)) return false;
    if (!RegExp(r'^[A-Z<]{3}$').hasMatch(nationality)) return false;
    if (!RegExp(r'^[0-9]{6}$').hasMatch(dob)) return false;
    if (!RegExp(r'^[0-9<]$').hasMatch(dobCheck)) return false;
    if (!RegExp(r'^[MFUX<]$', caseSensitive: false).hasMatch(gender)) {
      return false;
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(expiry)) return false;
    if (!RegExp(r'^[0-9<]$').hasMatch(expiryCheck)) return false;
    return true;
  }

  static int? _checkDigitValue(String c) {
    if (c == '<') return 0;
    return int.tryParse(c);
  }

  static bool _checksumMatches(String data, String checkChar) {
    final expected = _checkDigitValue(checkChar);
    if (expected == null) return false;
    return _icaoChecksum(data) == expected;
  }

  /// OCR often reads O as 0 in the name zone; digits never appear in MRZ names.
  static String _fixNameLetters(String value) {
    return value.replaceAll('0', 'O');
  }

  static int _icaoChecksum(String input) {
    const weights = [7, 3, 1];
    var sum = 0;
    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      int v;
      if (c == '<') {
        v = 0;
      } else if (RegExp(r'[0-9]').hasMatch(c)) {
        v = int.parse(c);
      } else {
        v = c.codeUnitAt(0) - 'A'.codeUnitAt(0) + 10;
      }
      sum += v * weights[i % 3];
    }
    return sum % 10;
  }
}
