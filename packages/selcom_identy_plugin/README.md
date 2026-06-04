# selcom_identy_plugin

A new Flutter plugin project.

## Getting Started

## Android Setup Guide

[Step1]
- File Name [AndroidManifest.xml] in your Project. Path [android/app/scr/main]. Make sure you have this permission added.
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.hardware.camera.autofocus" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_VIDEO" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />

<uses-feature
    android:name="android.hardware.camera"
    android:required="false" />
<uses-feature
    android:name="android.hardware.camera.autofocus"
    android:required="false" />
<uses-feature
    android:name="android.hardware.camera.front"
    android:required="false" />
<uses-feature
    android:name="android.hardware.camera.front.autofocus"
    android:required="false" />
    
- Add this line below your application opening tag to avoid outofmemory crashes.
  <application
      android:largeHeap="true"

- Add this line inside your application tag.
<activity
            android:name="com.example.selcom_identy_plugin.TempActivity"
            android:exported="true"   
            android:theme="@style/Theme.AppCompat.Light.NoActionBar" />

[Step2]
- File Name [colors.xml] in your Project. Path [android/app/scr/main/res/values].
-Make sure you have this colors in every colors.xml file.
-Please don't change color codes.
-Please check [lib/resources/android]. Have added all res files required. Add this in your main project. Keep same folder structure

<color name="boxes">#ff5CB75E</color>
<color name="boxes_transparent">#ffE3F3E4</color>
<color name="id_result_center">#ff5CB75E</color>
<color name="id_result_end">#ff5CB75E</color>
<color name="id_result_start">#ff5CB75E</color>
<color name="id_success">#ff5CB75E</color>
<color name="id_error">#ff5CB75E</color>
<color name="id_retake">#ff5CB75E</color>

[Step3]
- File Name [build.gradle] in your Project. Path [android/app/src/main/build.gradle]. Add this line inside android{}

packagingOptions{
    pickFirst 'lib/arm64-v8a/libc++_shared.so'
    pickFirst 'lib/x86_64/libc++_shared.so'
    pickFirst 'lib/x86/libc++_shared.so'
    pickFirst 'lib/armeabi-v7a/libc++_shared.so'
}

[Step4]
- File Name [progaurd-rules.pro] in your Project. Path [android/app/src]. Add this line inside it.
-keep class org.identy.** { *; }
-keep class com.identy.** { *; }
-keep public class org.opencv.core.** {
  *;
}
-keep public class org.dft.** {
  *;
}
-dontwarn org.conscrypt.OpenSSLProvider

[Step5]
- [Important] To store lic file of android
- Open android project in [android studio] and then add [.lic] file assets folder or make one if folder is not there.
- To make one right click on [app] then click on [new] and then make [directory]. Name it as [assets]
- Alternatively you can create folder under [android/app/scr/main/]. Inside main create assets folder and add files to it.


## IOS Setup Guide

[Step 1]
- Add below lines to file [Podfile].

1. At the top of the file 
source 'https://github.com/CocoaPods/Specs.git'
plugin 'cocoapods-art', :sources => [
 'cocoapods-identy-finger'
]

2. Add this lines to target
target 'Runner' do
 pod 'Identy','6.3.0'
 pod 'CryptoSwift'
end

[Step 2]
- Add License file [Runner]. Make sure you are adding the license files from XCode. If not then you need to add reference in Xcode when you run the build

[Step 3]
-Please check [lib/resources/ios]. Have added all required files. Add this in your main project. Keep same folder structure


## Flutter 

- Setup Inital values
initstate(){
    selcomIdentyPlugin.options.leftHandSelected = true;
    selcomIdentyPlugin.options.licenseFile =
        generalConfigController.getIdentyLicense;
    loginController.isIndexFingerMissing.value = false;
    loginController.isMiddleFingerMissing.value = false;
    loginController.isRingFingerMissing.value = false;
    loginController.isLittleFingerMissing.value = false;
}

- Selecting hand
forleftHand(){
    selcomIdentyPlugin.options.leftHandSelected = true;
    selcomIdentyPlugin.options.rightHandSelected = false;
}
for rightHand(){
    selcomIdentyPlugin.options.rightHandSelected = true;
    selcomIdentyPlugin.options.leftHandSelected = false;
}

- Selecting Missing Fingers
for missingFinger(){
    if (loginController.isMissingFingerSelected.value) {
        if (loginController.isLeftHandSelected.value) {
            selcomIdentyPlugin.options.leftHandMissingArray =
            loginController.getMissingFingers();
        } else {
            selcomIdentyPlugin.options.rightHandMissingArray =
            loginController.getMissingFingers();
        }
    }
}

- How to Handle Missing fingers
List<int> getMissingFingers() {
    List<int> missingFingers = [];
    if (Platform.isAndroid) {
      if (isIndexFingerMissing.value) {
        missingFingers.add(0);
      } else {
        missingFingers.add(1);
      }
      if (isMiddleFingerMissing.value) {
        missingFingers.add(0);
      } else {
        missingFingers.add(1);
      }
      if (isRingFingerMissing.value) {
        missingFingers.add(0);
      } else {
        missingFingers.add(1);
      }
      if (isLittleFingerMissing.value) {
        missingFingers.add(0);
      } else {
        missingFingers.add(1);
      }
    } else if (Platform.isIOS) {
      if (isLeftHandSelected.value) {
        if (!isIndexFingerMissing.value) missingFingers.add(2);
        if (!isMiddleFingerMissing.value) missingFingers.add(3);
        if (!isRingFingerMissing.value) missingFingers.add(4);
        if (!isLittleFingerMissing.value) missingFingers.add(5);
      } else if (isRightHandSelected.value) {
        if (!isIndexFingerMissing.value) missingFingers.add(7);
        if (!isMiddleFingerMissing.value) missingFingers.add(8);
        if (!isRingFingerMissing.value) missingFingers.add(9);
        if (!isLittleFingerMissing.value) missingFingers.add(10);
      }
    }
    log("missingFingers ===> $missingFingers");
    return missingFingers;
}

- Launch Scanning and get data
//Check camera and location permission before onboarding
 if (await getpermission(permission: Permission.camera,)) {
    log("Premissionnnnnnnnnnnn granted");
    if (loginController.isMissingFingerSelected.value) {
        if (loginController.isLeftHandSelected.value) {
            selcomIdentyPlugin.options.leftHandMissingArray =
            loginController.getMissingFingers();
        } else {
            SelcomIdentyPlugin.options.rightHandMissingArray =
            loginController.getMissingFingers();
        }
    }
    if (Platform.isAndroid) {
        showLoader();
    }
    var result = await selcomIdentyPlugin.enrollFinger();
        if (Platform.isAndroid) {
        hideLoader();
    }
    await loginController.processIdentyResult(result: result);
}

- To Handle Result After Plugin Result 
- Future<void> processIdentyResult({required dynamic result}) async {
    log("Finger scan result ==========> ${result}");
    if (result != null &&
        result != "" &&
        result != "null" &&
        result != "500" &&
        !result.toString().contains("IDENTY_ERROR")) {
      log("convertedJson ===> ${jsonEncode(result)}");
      // Your Api Logic
    } else if (result == "500" || result == "") {
      log("result ===> ${result}");
    } else if (result == null || result == "null") {
      if (!Platform.isAndroid) {
        await showDialogWithMessage(
          message: "Biometric scan failed. Please try again.",
        );
      }
    } else if (result.toString().contains("IDENTY_ERROR")) {
      List<String> parts = result.toString().split(':');
      if (parts.length > 1) {
        await showDialogWithMessage(message: parts[1].trim());
      }
    } else {
      await showDialogWithMessage(
        message: generalConfigController
            .getTranslatedString(languageTransaltion.SOMETHINGWENTWRONG),
      );
    }
}
