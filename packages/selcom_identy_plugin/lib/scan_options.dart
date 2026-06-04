import 'dart:io';

class IdentyOptions {
  bool leftHandSelected = false;
  bool rightHandSelected = false;
  bool isLeftMissingFingerSelected = false;
  bool isRightMissingFingerSelected = false;
  List<int> leftHandMissingArray = [];
  List<int> rightHandMissingArray = [];
  String licenseFile = "";
  String languageCode = "en";

  ///returns the options as a serialized list.
  dynamic toParams() {
    return <String, dynamic>{
      'leftHandSelected': rightHandSelected ? false : leftHandSelected,
      'rightHandSelected': leftHandSelected ? false : rightHandSelected,
      'isLeftMissingFingerSelected':
          isRightMissingFingerSelected ? false : isLeftMissingFingerSelected,
      'isRightMissingFingerSelected':
          isLeftMissingFingerSelected ? false : isRightMissingFingerSelected,
      "leftHandMissingArray":
          isRightMissingFingerSelected ? [] : leftHandMissingArray,
      'rightHandMissingArray':
          isLeftMissingFingerSelected ? [] : rightHandMissingArray,
      'licenseFile': getFileName(licenseFile),
      'languageCode': languageCode,
    };
  }

  String getFileName(String input) {
    if (Platform.isAndroid) {
      if (!input.endsWith('.lic')) {
        return "$input.lic";
      } else {
        return input;
      }
    } else if (Platform.isIOS) {
      if (input.endsWith('.lic')) {
        return input.substring(0, input.length - 4);
      }
    }
    return input;
  }
}
