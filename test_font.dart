import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test load font', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      final data = await rootBundle.load('assets/fonts/metropolis/Metropolis-Regular.otf');
      print('SUCCESS: loaded ${data.lengthInBytes} bytes');
    } catch (e) {
      print('ERROR: $e');
    }
  });
}
