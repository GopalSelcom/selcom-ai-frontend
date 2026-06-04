import 'package:flutter_test/flutter_test.dart';
import 'package:passport_mrz_capture/passport_mrz_capture.dart';

void main() {
  test('parses fragmented OCR like device logs', () {
    const text = 'P<IND<<ASMA<<\nR2065510<4IND8707305 F2 709047';
    final parsed = MRZParser.parseForOcr(text);
    expect(parsed, isNotNull);
    expect(parsed!.issuingCountry, 'IND');
    expect(parsed.surname, 'ASMA');
    expect(parsed.passportNumber, contains('2065510'));
    expect(parsed.mrzLine1.length, 44);
    expect(parsed.mrzLine2.length, 44);
  });

  test('parses when filler < is misread as K in line2', () {
    const text =
        'P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<\nL898902C36UTO7408122F1204159ZE184226BKKKKK10';
    final parsed = MRZParser.parseForOcr(text);
    expect(parsed, isNotNull);
    expect(parsed!.mrzLine2, contains('<<<<<10'));
  });

  test('keeps real K letter in name', () {
    const text =
        'P<INDKARIM<<ALI<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\nL898902C36UTO7408122F1204159ZE184226B<<<<<10';
    final parsed = MRZParser.parseForOcr(text);
    expect(parsed, isNotNull);
    expect(parsed!.surname, 'KARIM');
  });

  test('parses device OCR with KCCe filler tail as <<<<', () {
    const text =
        'PSINDRATO<<CANDICE<XYSTUS<<KCCe\nZ5650585<7IND7305058F3002038<e';
    final parsed = MRZParser.parseForOcr(text);
    expect(parsed, isNotNull);
    expect(parsed!.issuingCountry, 'IND');
    expect(parsed!.surname, 'RATO');
    expect(parsed!.givenNames, contains('CANDICE'));
    expect(parsed!.mrzLine1, startsWith('P<IND'));
    expect(parsed!.mrzLine1, isNot(contains('KCCE')));
    expect(parsed!.mrzLine1.length, 44);
    expect(parsed!.mrzLine1.substring(25), matches(r'^<{17,}$'));
  });

  test('rejects invalid candidates even with K variants', () {
    const text =
        'PKUTOERIKSSONKKANNAKMARIAKKKKKKKKKKKKKKKKKKK\nL8989K2C36UTO74K812KF12K4159ZE184226BKKKKK10';
    final parsed = MRZParser.parseForOcr(text);
    expect(parsed, isNull);
  });
}
