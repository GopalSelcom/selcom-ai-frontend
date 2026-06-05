import 'package:intl/intl.dart';

String getLastWord(String input) {
  List<String> words = input.split(' ');
  return words.isNotEmpty ? words.last : "";
}

int countHyphens(String input) {
  int count = 0;
  for (int i = 0; i < input.length; i++) {
    if (input[i] == '-') {
      count++;
    }
  }
  return count;
}

String formatDateFromNidaCard(String inputDate) {
  assert(inputDate.length == 8);

  int year = int.parse(inputDate.substring(0, 4));
  int month = int.parse(inputDate.substring(4, 6));
  int day = int.parse(inputDate.substring(6, 8));

  DateTime date = DateTime(year, month, day);
  String formattedDate = DateFormat('dd MMM yyyy').format(date);

  return formattedDate;
}
